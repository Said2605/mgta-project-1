function airlines = get_airline(ARCID)
%% GET_AIRLINE  Extrae el código de aerolínea de cada número de vuelo
%
%   airlines = get_airline(ARCID)
%
%   ENTRADA:
%     ARCID   - cell array con los números de vuelo
%               (ej: {'VLG7575','RYR404A','IBE2602','AEE713',...})
%
%   SALIDA:
%     airlines - cell array con el código IATA de la aerolínea (3 letras)
%                (ej: {'VLG','RYR','IBE','AEE',...})
%
%   EXPLICACIÓN:
%     Los números de vuelo tienen formato: [código aerolínea][número]
%     El código de aerolínea son las primeras letras (hasta que empieza
%     la parte numérica). Ejemplos:
%       'VLG7575'  → 'VLG'  (Vueling)
%       'RYR404A'  → 'RYR'  (Ryanair)
%       'IBE2602'  → 'IBE'  (Iberia)
%       'AEE713'   → 'AEE'  (Aegean Airlines)
%       'AAL66'    → 'AAL'  (American Airlines)
%       'TAP1041'  → 'TAP'  (TAP Air Portugal)

fprintf('Extrayendo códigos de aerolínea de los números de vuelo...\n');

N = length(ARCID);
airlines = cell(N, 1);

for i = 1:N
    arcid_i = strtrim(char(ARCID{i}));
    
    % Buscamos dónde empieza el primer dígito numérico
    % Todo lo que hay ANTES del primer número es el código de aerolínea
    first_digit = regexp(arcid_i, '\d', 'once');
    
    if ~isempty(first_digit) && first_digit > 1
        airlines{i} = arcid_i(1 : first_digit - 1);
    else
        % Si no encontramos número, usamos el código entero
        airlines{i} = arcid_i;
    end
end

% --- Resumen: ¿cuántas aerolíneas distintas hay? ---
unique_airlines = unique(airlines);
fprintf('  Aerolíneas distintas encontradas: %d\n', length(unique_airlines));

% Mostramos las 10 más frecuentes
fprintf('  Top 10 aerolíneas por número de vuelos:\n');
counts = zeros(length(unique_airlines), 1);
for k = 1:length(unique_airlines)
    counts(k) = sum(strcmp(airlines, unique_airlines{k}));
end
[counts_sorted, sort_idx] = sort(counts, 'descend');
for k = 1:min(10, length(unique_airlines))
    fprintf('    %s: %d vuelos\n', unique_airlines{sort_idx(k)}, counts_sorted(k));
end

fprintf('✓ Aerolíneas extraídas correctamente.\n\n');

end
