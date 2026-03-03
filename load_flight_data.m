function flights = load_flight_data(filepath)
%% LOAD_FLIGHT_DATA  Carga los datos de vuelo del Excel del aeropuerto
%
%   flights = load_flight_data(filepath)
%
%   ENTRADA:
%     filepath  - ruta al archivo Excel (p.ej. 'data/LEBL_10AUG2025.xlsx')
%
%   SALIDA:
%     flights   - struct con los datos de todos los vuelos, con campos:
%                   .ARCID    - número de vuelo (cell array de strings)
%                   .ATYP     - tipo de avión  (cell array de strings)
%                   .ADEP     - aeropuerto origen ICAO (cell array)
%                   .ADES     - aeropuerto destino ICAO (cell array)
%                   .RM       - matrícula del avión (cell array)
%                   .ARF      - nivel de vuelo de referencia (array numérico)
%                   .ETD      - hora de salida en MINUTOS desde medianoche
%                   .TT       - taxi time OUT en minutos (array numérico)
%                   .ETA      - hora de llegada en MINUTOS desde medianoche
%                   .N        - número total de vuelos
%                   .arrivals - índices de los vuelos que llegan a LEBL
%
%   NOTAS:
%     - Las horas del Excel vienen como texto "HH:MM:SS" o como número
%       decimal de Excel (fracción del día). Esta función maneja ambos casos.
%     - Si ETD > ETA significa que el vuelo salió el día anterior.
%       Se corrige sumando 24*60 a ETD para que los cálculos sean correctos.

fprintf('Cargando datos de vuelos desde: %s\n', filepath);

% -------------------------------------------------------------------------
%% PASO 1: Leer el Excel
% -------------------------------------------------------------------------
% Opciones de lectura: preservamos los nombres de columna originales
opts = detectImportOptions(filepath, 'VariableNamingRule', 'preserve');
T = readtable(filepath, opts);

fprintf('  Total de filas leídas: %d\n', height(T));

% -------------------------------------------------------------------------
%% PASO 2: Extraer cada columna del Excel
% -------------------------------------------------------------------------
% Las columnas son: ARCID, ATYP, ADEP, ADES, RM, ARF, ETD, TT, ETA

flights.ARCID = T.ARCID;   % Número de vuelo
flights.ATYP  = T.ATYP;    % Tipo de avión
flights.ADEP  = T.ADEP;    % Aeropuerto de salida
flights.ADES  = T.ADES;    % Aeropuerto de llegada
flights.RM    = T.RM;      % Matrícula
flights.ARF   = T.ARF;     % Nivel de vuelo

% Taxi time out: ya viene en minutos como número entero
flights.TT = T.TT;

% -------------------------------------------------------------------------
%% PASO 3: Convertir ETD y ETA a minutos desde medianoche
% -------------------------------------------------------------------------
% Las horas en el Excel pueden venir de dos formas:
%   a) Como texto:  "22:50:00"
%   b) Como número decimal de Excel: 0.9514 = 22h50min (fracción de 1 día)
% La función time_to_minutes maneja ambos casos.

N = height(T);
ETD_min = zeros(N, 1);
ETA_min = zeros(N, 1);

% MATLAB puede leer las horas del Excel de distintas formas según la versión:
%   - Como cell array de strings: {'22:50:00', '0:19:00', ...}
%   - Como array de datetime:     [22-Jan-0000 22:50:00, ...]
%   - Como array de duration:     [22:50:00, 0:19:00, ...]
% Detectamos el tipo y actuamos en consecuencia:

if iscell(T.ETD)
    % --- Caso 1: cell array de strings ---
    for i = 1:N
        ETD_min(i) = time_to_minutes(T.ETD{i});
        ETA_min(i) = time_to_minutes(T.ETA{i});
    end

elseif isdatetime(T.ETD)
    % --- Caso 2: array de datetime ---
    ETD_min = hour(T.ETD)*60 + minute(T.ETD) + second(T.ETD)/60;
    ETA_min = hour(T.ETA)*60 + minute(T.ETA) + second(T.ETA)/60;

elseif isduration(T.ETD)
    % --- Caso 3: array de duration ---
    ETD_min = hour(T.ETD)*60 + minute(T.ETD) + second(T.ETD)/60;
    ETA_min = hour(T.ETA)*60 + minute(T.ETA) + second(T.ETA)/60;

elseif isnumeric(T.ETD)
    % --- Caso 4: número decimal de Excel (fracción del día) ---
    ETD_min = mod(T.ETD * 24 * 60, 24*60);
    ETA_min = mod(T.ETA * 24 * 60, 24*60);

else
    error('Formato de hora desconocido: %s. Contacta al desarrollador.', class(T.ETD));
end

% -------------------------------------------------------------------------
%% PASO 4: Corregir vuelos que salieron el día anterior
% -------------------------------------------------------------------------
% Si ETD > ETA significa que el vuelo salió antes de medianoche y llegó
% después (en el día siguiente). Ej: sale a las 23:30, llega a las 01:15.
% Para que los cálculos de tiempo de vuelo sean correctos, sumamos 24h a ETD.
% Así el tiempo de vuelo = ETA - ETD siempre es positivo.

mask_prev_day = (ETD_min > ETA_min);
ETD_min(mask_prev_day) = ETD_min(mask_prev_day) - 24*60;
% Nota: esto deja ETD en negativo (p.ej. -30 = salió 30 min antes de medianoche)
% pero permite calcular correctamente: tiempo_vuelo = ETA - ETD

n_prev = sum(mask_prev_day);
if n_prev > 0
    fprintf('  %d vuelos salieron el día anterior (ETD corregido)\n', n_prev);
end

flights.ETD = ETD_min;
flights.ETA = ETA_min;
flights.N   = N;

% -------------------------------------------------------------------------
%% PASO 5: Identificar vuelos que llegan a nuestro aeropuerto (LEBL)
% -------------------------------------------------------------------------
% Solo nos interesan los vuelos con ADES = 'LEBL'
% (los vuelos con ADEP = 'LEBL' son salidas, no llegadas)

arrivals_mask = strcmp(flights.ADES, 'LEBL');
flights.arrivals = find(arrivals_mask);   % índices de filas que son llegadas

fprintf('  Vuelos totales en el Excel: %d\n', N);
fprintf('  Vuelos que llegan a LEBL: %d\n', length(flights.arrivals));
fprintf('✓ Datos cargados correctamente.\n\n');

end


%% ========================================================================
%  FUNCIÓN AUXILIAR: time_to_minutes
%  Convierte un tiempo (texto o número) a minutos desde medianoche
%% ========================================================================
function m = time_to_minutes(t)
% Convierte un valor de tiempo al número de minutos desde medianoche.
%
%   Acepta:
%     - String/char:  '22:50:00' o '22:50'
%     - datetime:     valor de tipo datetime de MATLAB
%     - duration:     valor de tipo duration de MATLAB
%     - Número:       fracción decimal del día (estilo Excel: 0.9514 = 22h50m)

    if ischar(t) || isstring(t)
        % ----- Caso texto: "HH:MM:SS" o "HH:MM" -----
        t = char(t);
        parts = strsplit(strtrim(t), ':');
        h  = str2double(parts{1});
        mn = str2double(parts{2});
        if numel(parts) >= 3
            s = str2double(parts{3});
        else
            s = 0;
        end
        m = h*60 + mn + s/60;

    elseif isdatetime(t)
        % ----- Caso datetime de MATLAB -----
        m = hour(t)*60 + minute(t) + second(t)/60;

    elseif isduration(t)
        % ----- Caso duration de MATLAB -----
        m = hours(t) * 60;

    elseif isnumeric(t)
        % ----- Caso número decimal de Excel (fracción del día) -----
        % 1.0 = 24h, 0.5 = 12h, etc.
        total_minutes = t * 24 * 60;
        m = mod(total_minutes, 24*60);   % por si supera las 24h

    else
        warning('time_to_minutes: tipo desconocido para el valor: %s', class(t));
        m = NaN;
    end
end
