function slots = compute_slots(Hstart, Hend, HNoReg, PAAR, AAR)
%% COMPUTE_SLOTS  Genera la matriz de slots de la regulación ATFM
%
%   slots = compute_slots(Hstart, Hend, HNoReg, PAAR, AAR)
%
%   ENTRADAS:
%     Hstart  - inicio capacidad reducida [minutos desde medianoche]
%     Hend    - fin capacidad reducida [minutos desde medianoche]
%     HNoReg  - fin de la regulación [minutos desde medianoche]
%     PAAR    - capacidad reducida [llegadas/hora]
%     AAR     - capacidad nominal [llegadas/hora]
%
%   SALIDA:
%     slots   - matriz con una fila por slot y 3 columnas:
%               col 1: tiempo de inicio del slot [minutos desde medianoche]
%               col 2: ID del vuelo asignado (0 = sin asignar aún)
%               col 3: código de aerolínea asignada (0 = sin asignar aún)
%
%   LÓGICA:
%     Tramo 1 (Hstart → Hend):    un slot cada 60/PAAR minutos
%     Tramo 2 (Hend   → HNoReg):  un slot cada 60/AAR  minutos
%
%   EJEMPLO de matriz resultante:
%     420.00   0   0    <- slot a las 7:00h (420 min)
%     423.00   0   0    <- slot a las 7:03h (con PAAR=20, slot=3min)
%     426.00   0   0
%     ...
%     780.00   0   0    <- slot a las 13:00h (Hend)
%     781.36   0   0    <- slot a las 13:01h (con AAR=44, slot=1.36min)
%     ...

fprintf('Generando matriz de slots...\n');
fprintf('  Tramo 1 (Hstart→Hend):   slot = %.2f min (PAAR=%d arr/h)\n', 60/PAAR, PAAR);
fprintf('  Tramo 2 (Hend→HNoReg):   slot = %.2f min (AAR=%d arr/h)\n',  60/AAR,  AAR);

% -------------------------------------------------------------------------
%% TRAMO 1: Slots desde Hstart hasta Hend (capacidad reducida PAAR)
% -------------------------------------------------------------------------
slot_size_1 = 60 / PAAR;   % minutos entre slots durante regulación

slots_t1 = [];
t = Hstart;
while t < Hend
    slots_t1(end+1) = t;
    t = t + slot_size_1;
end

% -------------------------------------------------------------------------
%% TRAMO 2: Slots desde Hend hasta HNoReg (capacidad normal AAR)
% -------------------------------------------------------------------------
slot_size_2 = 60 / AAR;   % minutos entre slots tras recuperar capacidad

slots_t2 = [];
t = Hend;
while t < HNoReg
    slots_t2(end+1) = t;
    t = t + slot_size_2;
end

% -------------------------------------------------------------------------
%% COMBINAR y construir la matriz
% -------------------------------------------------------------------------
all_times = [slots_t1, slots_t2]';
n_slots   = length(all_times);

% Matriz de slots: [tiempo, ID_vuelo, aerolinea]
% Inicialmente todo a 0 (sin asignar)
slots = [all_times, zeros(n_slots, 1), zeros(n_slots, 1)];

fprintf('  Slots en tramo 1 (PAAR): %d\n', length(slots_t1));
fprintf('  Slots en tramo 2 (AAR):  %d\n', length(slots_t2));
fprintf('  Total slots generados:   %d\n', n_slots);
fprintf('  Primer slot: %dh%02d\n', floor(all_times(1)/60), mod(round(all_times(1)),60));
fprintf('  Último slot: %dh%02d\n', floor(all_times(end)/60), mod(round(all_times(end)),60));
fprintf('✓ Matriz de slots generada correctamente.\n\n');

end
