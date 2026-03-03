%% PARAMETERS.M
% Archivo de parámetros del proyecto MGTA - Aeropuerto Barcelona (LEBL)
%
% INSTRUCCIONES:
%   Este archivo contiene TODOS los parámetros del proyecto en un solo lugar.
%   Si quieres cambiar algún valor (capacidad, horas de regulación, etc.),
%   solo tienes que cambiarlo AQUÍ y todo el proyecto se actualiza solo.
%
% CÓMO USARLO:
%   Llama a este script al principio de cualquier otro script con:
%   >> run('ruta/a/parameters.m')   o simplemente >> parameters
%   (si estás en la misma carpeta)

% =========================================================================
%% SECCIÓN 1: RUTAS A LOS ARCHIVOS DE DATOS
% =========================================================================
% Ajusta estas rutas si cambias de ordenador o mueves las carpetas

% Ruta base del proyecto (carpeta raíz, un nivel por encima de WP1/)
base_path = fileparts(fileparts(mfilename('fullpath')));

% Archivos de datos
FILE_FLIGHTS   = fullfile(base_path, 'data', 'LEBL_10AUG2025.xlsx');
FILE_FLEET     = fullfile(base_path, 'data', 'fleet_cat_seat.csv');
FILE_TAXIIN    = fullfile(base_path, 'data', 'eurocontrol-taxi-in-times-summer-2024.xlsx');

% =========================================================================
%% SECCIÓN 2: INFORMACIÓN DEL AEROPUERTO
% =========================================================================

AIRPORT_ICAO = 'LEBL';    % Código ICAO del aeropuerto de Barcelona

% -------------------------------------------------------------------------
% Capacidad del aeropuerto (en número de llegadas por HORA)
% Fuente: EUROCONTROL Airport Capacity Imbalance Study, 2020
%   Barcelona opera principalmente con 2 pistas.
%   En condiciones normales: ~44 llegadas/hora (AAR)
%   En mal tiempo (p.ej. niebla o lluvia fuerte): reducimos a 24/hora (PAAR)
% -------------------------------------------------------------------------
AAR  = 44;    % Airport Arrival Rate nominal [llegadas/hora]
PAAR = 20;    % Pre-Announced Arrival Rate reducida [llegadas/hora] (mal tiempo)

% Tamaño del slot de tiempo [minutos]
% Se calcula como: 60 / capacidad_en_hora
% Con AAR=44 -> slot normal = 60/44 ≈ 1.36 min
% Con PAAR=24 -> slot reducido = 60/24 = 2.5 min
slot_size_AAR  = 60 / AAR;    % [minutos] durante capacidad normal
slot_size_PAAR = 60 / PAAR;   % [minutos] durante capacidad reducida

% =========================================================================
%% SECCIÓN 3: PARÁMETROS DE LA REGULACIÓN
% =========================================================================
% Todos los tiempos están en MINUTOS desde medianoche (00:00 = 0 min)
%
% Ejemplo: 8:00h = 8*60 = 480 minutos
%          14:30h = 14*60 + 30 = 900 minutos
%
% Escenario: Niebla densa por la mañana en Barcelona que reduce capacidad
%            desde las 07:00 hasta las 13:00 (6 horas, > 5h mínimo requerido)

Hfile  = 4 * 60;    % 04:00h -> momento en que se publica la regulación [min]
Hstart = 7 * 60;    % 07:00h -> inicio de capacidad reducida [min]
Hend   = 13 * 60;   % 13:00h -> fin de capacidad reducida [min]
% Nota: HNoReg se calcula automáticamente en compute_regulation.m

% =========================================================================
%% SECCIÓN 4: VELOCIDADES MEDIAS POR CATEGORÍA RECAT-EU
% =========================================================================
% Se usan para calcular la distancia de vuelo a partir del tiempo de vuelo.
% Categorías RECAT-EU: A (más grande) -> F (más pequeño)
% Fuente: valores estándar de crucero aproximados

speed_A = 900;   % [km/h] - Categoría A: aviones muy pesados (A380, B747...)
speed_B = 870;   % [km/h] - Categoría B: pesados (B777, A330, B767...)
speed_C = 840;   % [km/h] - Categoría C: medianos-grandes (A320, B737, A321...)
speed_D = 800;   % [km/h] - Categoría D: medianos (CRJ900, E190...)
speed_E = 720;   % [km/h] - Categoría E: pequeños (ATR72, Dash8...)
speed_F = 550;   % [km/h] - Categoría F: muy pequeños (Cessna, etc.)

% Array de velocidades en orden A->F (útil para indexar)
% Usaremos: speeds('A') = 900, etc.
% Como MATLAB no indexa con letras fácilmente, hacemos un struct:
speeds.A = speed_A;
speeds.B = speed_B;
speeds.C = speed_C;
speeds.D = speed_D;
speeds.E = speed_E;
speeds.F = speed_F;

% =========================================================================
%% SECCIÓN 5: TAXI TIME IN (de Eurocontrol)
% =========================================================================
% Tiempo de rodaje de llegada en Barcelona
% Fuente: EUROCONTROL Taxi-in Times Summer 2024
TAXI_IN_LEBL = 5.51;   % [minutos] - Media para LEBL según Eurocontrol

% =========================================================================
%% SECCIÓN 6: PREFIJOS ICAO DE PAÍSES ECAC
% =========================================================================
% Los países miembros de ECAC (European Civil Aviation Conference) tienen
% códigos ICAO que empiezan por ciertas letras.
% Fuente: https://www.ecac-ceac.org/about-ecac/member-states
%
% Prefijos de 1 o 2 letras que corresponden a países ECAC:
ECAC_prefixes = {'EB','ED','EE','EF','EG','EH','EI','EK','EL','EN', ...
                 'EP','ES','ET','EV','EY','GC','LD','LE','LF','LG', ...
                 'LH','LI','LJ','LK','LL','LM','LN','LO','LP','LQ', ...
                 'LR','LS','LT','LU','LV','LW','LX','LY','LZ', ...
                 'MB','MD','MK','MM','MT','MY', ...
                 'OB','OE','OJ','OK','OL','OM','OO','OT','OY', ...
                 'UB','UD','UG','UK','UM','UT', ...
                 'BG','BI','UA','UK'};
% Nota: Esta lista es una aproximación práctica. Los prefijos de 2 letras
% son más fiables. Para vuelos de fuera (UU=Rusia, KJ=EEUU, etc.) no aparecen.

% =========================================================================
fprintf('✓ Parámetros cargados correctamente.\n');
fprintf('  Aeropuerto: %s | AAR: %d arr/h | PAAR: %d arr/h\n', AIRPORT_ICAO, AAR, PAAR);
fprintf('  Regulación: Hfile=%dh Hstart=%dh Hend=%dh\n', Hfile/60, Hstart/60, Hend/60);
