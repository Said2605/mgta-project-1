function [categories, seats] = get_aircraft_info(ATYP, fleet_filepath)
%% GET_AIRCRAFT_INFO  Obtiene la categoría RECAT-EU y asientos de cada avión
%
%   [categories, seats] = get_aircraft_info(ATYP, fleet_filepath)
%
%   ENTRADA:
%     ATYP           - cell array con los tipos de avión (ej: {'A320','B738',...})
%     fleet_filepath - ruta al archivo fleet_cat_seat.csv
%
%   SALIDA:
%     categories - cell array con la categoría RECAT-EU de cada avión
%                  Valores posibles: 'A','B','C','D','E','F'
%                  (A = más grande/pesado, F = más pequeño)
%     seats      - array numérico con el nº de asientos de cada avión
%
%   NOTAS SOBRE RECAT-EU:
%     A: Super-heavy  (A380, B748)
%     B: Upper-heavy  (B777, A330, B767, B763...)
%     C: Lower-heavy  (A321, A320, B738, B737...)  <- mayoría en BCN
%     D: Upper-medium (B712, E190, CRJ9...)
%     E: Lower-medium (AT72, DH8D, E120...)
%     F: Light        (C172, PA28...)

fprintf('Cargando categorías de aviones desde fleet_cat_seat.csv...\n');

% -------------------------------------------------------------------------
%% PASO 1: Leer el CSV de categorías
% -------------------------------------------------------------------------
% El CSV tiene formato:  ;f;recat;size_seats_avg;;
% Separador: punto y coma (;)
% Primera columna: índice numérico (la ignoramos)
% Segunda columna: tipo de avión (ATYP)
% Tercera columna: categoría RECAT-EU
% Cuarta columna: número de asientos medio

opts = detectImportOptions(fleet_filepath, ...
    'Delimiter', ';', ...
    'VariableNamingRule', 'preserve');
fleet = readtable(fleet_filepath, opts);

% Los nombres de columna del CSV son: (vacío), f, recat, size_seats_avg
% Renombramos para trabajar más fácil:
fleet.Properties.VariableNames{2} = 'ATYP';
fleet.Properties.VariableNames{3} = 'recat';
fleet.Properties.VariableNames{4} = 'seats';

% Limpiamos espacios en los tipos de avión del CSV
fleet_ATYP = strtrim(fleet.ATYP);
fleet_recat = fleet.recat;
fleet_seats = fleet.seats;

fprintf('  %d tipos de avión en la base de datos.\n', height(fleet));

% -------------------------------------------------------------------------
%% PASO 2: Buscar cada avión en el CSV
% -------------------------------------------------------------------------
N = length(ATYP);
categories = cell(N, 1);
seats      = zeros(N, 1);

n_found    = 0;  % contador de aviones encontrados en el CSV
n_notfound = 0;  % contador de aviones NO encontrados (usaremos regla por defecto)

for i = 1:N
    atyp_i = strtrim(char(ATYP{i}));  % tipo de avión actual, sin espacios
    
    % Buscar en el CSV (comparación exacta, mayúsculas)
    idx = find(strcmpi(fleet_ATYP, atyp_i), 1);
    
    if ~isempty(idx)
        % --- Avión encontrado en el CSV ---
        categories{i} = strtrim(char(fleet_recat{idx}));
        seats(i)       = fleet_seats(idx);
        n_found = n_found + 1;
    else
        % --- Avión NO encontrado: asignamos categoría por defecto ---
        % Usamos reglas basadas en prefijos comunes de tipos ICAO
        [cat_default, seats_default] = default_aircraft_category(atyp_i);
        categories{i} = cat_default;
        seats(i)       = seats_default;
        n_notfound = n_notfound + 1;
    end
end

fprintf('  Aviones identificados en CSV: %d\n', n_found);
fprintf('  Aviones con categoría por defecto: %d\n', n_notfound);
fprintf('✓ Categorías de aviones obtenidas correctamente.\n\n');

end


%% ========================================================================
%  FUNCIÓN AUXILIAR: default_aircraft_category
%  Asigna una categoría RECAT-EU aproximada para aviones no encontrados en CSV
%% ========================================================================
function [cat, seats] = default_aircraft_category(atyp)
% Asigna categoría RECAT-EU basándose en el código ICAO del avión.
% Esta es una aproximación basada en los prefijos más comunes.
% El enunciado dice: para modelos no en CSV, usar categorías RECAT-EU estándar.

atyp = upper(strtrim(atyp));

% --- Categoría A: Super-heavy ---
if any(strcmpi(atyp, {'A388','A380','B748','B74S'}))
    cat = 'A'; seats = 555;

% --- Categoría B: Upper-heavy ---
elseif any(strcmpi(atyp, {'B77W','B772','B773','B77L','B788','B789','B78X', ...
                            'A332','A333','A338','A339','A342','A343','A345','A346', ...
                            'B762','B763','B764','B752','B753','A306','A310'}))
    cat = 'B'; seats = 270;

% --- Categoría C: Lower-heavy (los más comunes en Barcelona) ---
elseif strncmpi(atyp, 'A32', 3) || strncmpi(atyp, 'A31', 3) || ...
       strncmpi(atyp, 'B73', 3) || strncmpi(atyp, 'B71', 3) || ...
       any(strcmpi(atyp, {'A319','A320','A321','A20N','A21N','A19N', ...
                           'B737','B738','B739','B38M','B39M', ...
                           'B712','MD80','MD81','MD82','MD83','MD87','MD88'}))
    cat = 'C'; seats = 165;

% --- Categoría D: Upper-medium ---
elseif strncmpi(atyp, 'E19', 3) || strncmpi(atyp, 'E17', 3) || ...
       strncmpi(atyp, 'CRJ', 3) || ...
       any(strcmpi(atyp, {'E190','E195','E170','E175','CRJ9','CRJ7', ...
                           'B462','B463','F100','F70'}))
    cat = 'D'; seats = 100;

% --- Categoría E: Lower-medium (turbohélices regionales) ---
elseif strncmpi(atyp, 'AT', 2) || strncmpi(atyp, 'DH', 2) || ...
       any(strcmpi(atyp, {'AT72','AT76','AT75','AT43','AT45', ...
                           'DH8A','DH8B','DH8C','DH8D','SF34','JS31','JS32'}))
    cat = 'E'; seats = 70;

% --- Categoría F: Light ---
elseif any(strcmpi(atyp, {'C172','C182','PA28','PA44','BE20','BE9L'}))
    cat = 'F'; seats = 4;

% --- Desconocido: asumimos C (el más común en aeropuertos europeos) ---
else
    cat = 'C'; seats = 150;
end

end
