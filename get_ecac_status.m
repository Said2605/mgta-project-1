function is_ecac = get_ecac_status(ADEP, ECAC_prefixes)
%% GET_ECAC_STATUS  Determina si cada vuelo viene de dentro de la zona ECAC
%
%   is_ecac = get_ecac_status(ADEP, ECAC_prefixes)
%
%   ENTRADA:
%     ADEP          - cell array con los códigos ICAO de los aeropuertos origen
%                     (ej: {'LPPR','EGLL','KJFK','UUEE',...})
%     ECAC_prefixes - cell array con los prefijos ICAO de países ECAC
%                     (viene de parameters.m)
%
%   SALIDA:
%     is_ecac - array lógico (true/false) del mismo tamaño que ADEP
%               true  = el vuelo viene de un aeropuerto ECAC (Europa)
%               false = el vuelo viene de fuera de ECAC
%
%   EXPLICACIÓN:
%     Los códigos ICAO de aeropuertos tienen 4 letras. Las 2 primeras
%     identifican el país/región. Por ejemplo:
%       LEBL = LE (España) + BL (Barcelona)  → ECAC ✓
%       EGLL = EG (UK)     + LL (Heathrow)   → ECAC ✓
%       KJFK = K  (EEUU)   + JFK             → NO ECAC ✗
%       UUEE = UU (Rusia)  + EE (Sheremetyevo)→ NO ECAC ✗
%     Comprobamos si los 2 primeros caracteres del código están en la lista
%     de prefijos ECAC de parameters.m

fprintf('Determinando origen ECAC/no-ECAC de los vuelos...\n');

N = length(ADEP);
is_ecac = false(N, 1);   % por defecto, todos fuera de ECAC

for i = 1:N
    adep_i = upper(strtrim(char(ADEP{i})));
    
    if length(adep_i) >= 2
        prefix2 = adep_i(1:2);   % primeras 2 letras (ej: 'LE', 'EG', 'KJ')
    else
        prefix2 = adep_i;
    end
    
    % Comprobamos si el prefijo de 2 letras está en la lista ECAC
    is_ecac(i) = any(strcmpi(ECAC_prefixes, prefix2));
end

n_ecac     = sum(is_ecac);
n_no_ecac  = sum(~is_ecac);

fprintf('  Vuelos desde ECAC (Europa):     %d\n', n_ecac);
fprintf('  Vuelos desde fuera de ECAC:     %d\n', n_no_ecac);
fprintf('✓ Estado ECAC determinado correctamente.\n\n');

end
