function distances = compute_flight_distance(ETA, ETD, TT_out, TT_in, categories, speeds)
%% COMPUTE_FLIGHT_DISTANCE  Calcula la distancia de vuelo de cada avión
%
%   distances = compute_flight_distance(ETA, ETD, TT_out, TT_in, categories, speeds)
%
%   ENTRADA:
%     ETA        - array de horas de llegada [minutos desde medianoche]
%     ETD        - array de horas de salida  [minutos desde medianoche]
%     TT_out     - array de taxi-out [minutos] (dato del Excel)
%     TT_in      - valor único de taxi-in [minutos] (dato de Eurocontrol)
%                  Para LEBL = 5.51 minutos
%     categories - cell array con categoría RECAT de cada vuelo ('A'..'F')
%     speeds     - struct con velocidades por categoría (de parameters.m)
%                  Ej: speeds.A=900, speeds.B=870, speeds.C=840...
%
%   SALIDA:
%     distances  - array con la distancia de cada vuelo [km]
%
%   FÓRMULA:
%     tiempo_vuelo = ETA - ETD - TT_out - TT_in   [minutos]
%     distancia    = (tiempo_vuelo / 60) * velocidad_media  [km]
%
%   NOTA: Solo tiene sentido calcular distancia para vuelos que LLEGAN
%   al aeropuerto. El script principal (WP1_main) se encarga de filtrar.

fprintf('Calculando distancias de vuelo...\n');

N = length(ETA);
distances = zeros(N, 1);

n_negative = 0;  % contador de vuelos con tiempo de vuelo negativo (error)

for i = 1:N
    
    % --- PASO 1: Calcular tiempo de vuelo en minutos ---
    % Restamos el taxi-out (tiempo rodando antes de despegar en origen)
    % y el taxi-in (tiempo rodando después de aterrizar en destino)
    flight_time_min = ETA(i) - ETD(i) - TT_out(i) - TT_in;
    
    % --- PASO 2: Comprobar que el tiempo de vuelo es positivo ---
    % Para vuelos muy cortos (ej: Palma-Barcelona ~185km), los tiempos de
    % taxi pueden superar la diferencia ETA-ETD, dando resultado negativo.
    % Solución: usamos un mínimo de 10 minutos de tiempo de vuelo.
    MIN_FLIGHT_TIME = 10;  % [minutos] tiempo mínimo razonable en aire
    if flight_time_min <= 0
        flight_time_min = MIN_FLIGHT_TIME;
        n_negative = n_negative + 1;
    end
    
    % --- PASO 3: Obtener velocidad media según categoría RECAT ---
    cat = upper(strtrim(char(categories{i})));
    
    switch cat
        case 'A'
            v = speeds.A;
        case 'B'
            v = speeds.B;
        case 'C'
            v = speeds.C;
        case 'D'
            v = speeds.D;
        case 'E'
            v = speeds.E;
        case 'F'
            v = speeds.F;
        otherwise
            % Categoría desconocida: usamos velocidad de C (la más común)
            v = speeds.C;
    end
    
    % --- PASO 4: Calcular distancia ---
    % Convertimos minutos a horas dividiendo entre 60
    flight_time_h = flight_time_min / 60;
    distances(i)  = flight_time_h * v;   % [km]
    
end

% --- Resumen ---
if n_negative > 0
    fprintf('  ℹ %d vuelos muy cortos con tiempo negativo → se usó mínimo de 10 min\n', n_negative);
    fprintf('    (Son vuelos tan cortos que taxi-in+taxi-out superan la diferencia ETA-ETD)\n');
end

fprintf('  Distancia mínima: %.0f km\n', min(distances(distances > 0)));
fprintf('  Distancia máxima: %.0f km\n', max(distances));
fprintf('  Distancia media:  %.0f km\n', mean(distances(distances > 0)));
fprintf('✓ Distancias calculadas correctamente.\n\n');

end
