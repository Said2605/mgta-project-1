function [HNoReg, total_delay, AggregateDemand, AggregateCapacity] = ...
    compute_regulation(ETA, Hstart, Hend, PAAR, AAR)
%% COMPUTE_REGULATION  Calcula la regulación ATFM para el aeropuerto
%
%   LÓGICA CORRECTA:
%     Contamos desde Hstart. Solo miramos vuelos con ETA >= Hstart.
%     Ambas curvas (demanda y capacidad) empiezan en 0 en Hstart.
%     - Demanda: sube cada vez que llega un vuelo (ETA >= Hstart)
%     - Capacidad reducida: sube a ritmo PAAR hasta Hend, luego AAR
%     - Capacidad nominal: sube a ritmo AAR siempre (referencia)
%     HNoReg = primer minuto tras Hend donde cap_cum >= demand_cum

fprintf('Calculando regulación ATFM...\n');
fprintf('  Hstart = %dh%02d | Hend = %dh%02d | PAAR = %d arr/h | AAR = %d arr/h\n', ...
    floor(Hstart/60), mod(Hstart,60), floor(Hend/60), mod(Hend,60), PAAR, AAR);

% -------------------------------------------------------------------------
%% PASO 1: Filtrar vuelos afectados (ETA >= Hstart)
% -------------------------------------------------------------------------
ETA_reg = ETA(ETA >= Hstart);
n_reg   = length(ETA_reg);
fprintf('  Vuelos con ETA >= Hstart (%dh): %d\n', floor(Hstart/60), n_reg);

t_start     = Hstart;
t_end       = ceil(max(ETA_reg)) + 120;
time_vector = (t_start : t_end)';
T           = length(time_vector);

% -------------------------------------------------------------------------
%% PASO 2: Demanda acumulada desde Hstart (ambas curvas parten de 0)
% -------------------------------------------------------------------------
demand_cum = zeros(T, 1);
for k = 1:T
    demand_cum(k) = sum(ETA_reg <= time_vector(k));
end
AggregateDemand = [time_vector, demand_cum];

% -------------------------------------------------------------------------
%% PASO 3: Capacidad reducida acumulada
% -------------------------------------------------------------------------
cap_cum = zeros(T, 1);
for k = 2:T
    if time_vector(k) <= Hend
        cap_cum(k) = cap_cum(k-1) + PAAR/60;
    else
        cap_cum(k) = cap_cum(k-1) + AAR/60;
    end
end
AggregateCapacity = [time_vector, cap_cum];

% -------------------------------------------------------------------------
%% PASO 4: Capacidad nominal acumulada (AAR siempre, para referencia)
% -------------------------------------------------------------------------
cap_nominal_cum = zeros(T, 1);
for k = 2:T
    cap_nominal_cum(k) = cap_nominal_cum(k-1) + AAR/60;
end

% -------------------------------------------------------------------------
%% PASO 5: HNoReg — primer minuto tras Hend donde capacidad >= demanda
% -------------------------------------------------------------------------
HNoReg = NaN;
for k = 1:T
    if time_vector(k) >= Hend && cap_cum(k) >= demand_cum(k)
        HNoReg = time_vector(k);
        break
    end
end
if isnan(HNoReg)
    warning('HNoReg no encontrado. Considera reducir PAAR o ampliar Hend.');
    HNoReg = t_end;
end

% -------------------------------------------------------------------------
%% PASO 6: Delay total mínimo
% -------------------------------------------------------------------------
delay_per_min = max(0, demand_cum - cap_cum);
total_delay   = sum(delay_per_min);

% Vuelos afectados = solo los que tienen ETA entre Hstart y HNoReg
n_affected = sum(ETA_reg <= HNoReg);
avg_delay  = total_delay / max(n_affected, 1);

fprintf('  HNoReg: %dh%02d\n', floor(HNoReg/60), mod(round(HNoReg),60));
fprintf('  Delay total mínimo: %.0f minutos\n', total_delay);
fprintf('  Delay medio por vuelo: %.1f minutos\n', avg_delay);

if avg_delay < 45
    fprintf('  ⚠ Delay medio < 45 min. Considera reducir PAAR o ampliar Hend.\n');
else
    fprintf('  ✓ Delay medio >= 45 min. Regulación suficientemente interesante.\n');
end

% -------------------------------------------------------------------------
%% PASO 7: Gráfica con 3 líneas (como en los apuntes del profesor)
% -------------------------------------------------------------------------
% IMPORTANTE: Las líneas de capacidad son SEGMENTOS, no líneas completas:
%   - Roja punteada (PAAR): solo de Hstart → Hend
%   - Azul discontinua (AAR): solo de Hend → HNoReg
% Juntas forman la "capacidad acumulada" del período regulado.

figure('Name','WP1 - Regulación ATFM Barcelona','NumberTitle','off', ...
       'Position',[100,100,950,550]);
hold on;

time_h = time_vector / 60;

% Máscaras de tiempo para cada segmento
mask_paar = time_vector >= Hstart & time_vector <= Hend;
mask_aar  = time_vector >= Hend   & time_vector <= HNoReg;

% Línea 1: Demanda acumulada — completa (negra continua)
h1 = plot(time_h, demand_cum, 'k-', 'LineWidth', 2.5);

% Línea 2: Capacidad PAAR — solo Hstart→Hend (roja punteada)
h2 = plot(time_h(mask_paar), cap_cum(mask_paar), 'r:', 'LineWidth', 2.5);

% Línea 3: Capacidad AAR — solo Hend→HNoReg (azul discontinua)
h3 = plot(time_h(mask_aar), cap_cum(mask_aar), 'b--', 'LineWidth', 2);

% Barras verdes del delay cada 10 minutos
for k = 1:T
    if demand_cum(k) > cap_cum(k) && ...
       time_vector(k) >= Hstart && time_vector(k) <= HNoReg && ...
       mod(time_vector(k) - Hstart, 10) == 0
        plot([time_h(k) time_h(k)], [cap_cum(k) demand_cum(k)], ...
             'g-', 'LineWidth', 1.5);
    end
end

% Puntos rojos y etiquetas en Hstart, Hend, HNoReg
idx_s = find(time_vector == Hstart, 1);
idx_e = find(time_vector == Hend, 1);
idx_n = find(time_vector >= HNoReg, 1);

if ~isempty(idx_s)
    plot(Hstart/60, demand_cum(idx_s), 'ro','MarkerSize',10,'MarkerFaceColor','red');
    text(Hstart/60+0.05, demand_cum(idx_s)+2, ...
        sprintf('Hstart %dh',floor(Hstart/60)),'Color','red','FontSize',10);
end
if ~isempty(idx_e)
    plot(Hend/60, cap_cum(idx_e), 'ro','MarkerSize',10,'MarkerFaceColor','red');
    text(Hend/60+0.05, cap_cum(idx_e)+2, ...
        sprintf('Hend %dh',floor(Hend/60)),'Color','red','FontSize',10);
end
if ~isempty(idx_n)
    plot(HNoReg/60, demand_cum(idx_n), 'ro','MarkerSize',10,'MarkerFaceColor','red');
    text(HNoReg/60+0.05, demand_cum(idx_n)+2, ...
        sprintf('HNoReg %dh%02d',floor(HNoReg/60),mod(round(HNoReg),60)), ...
        'Color','red','FontSize',10,'FontWeight','bold');
end

% Líneas verticales Hstart y Hend
xline(Hstart/60,'k--','LineWidth',1);
xline(Hend/60,  'k--','LineWidth',1);

% Formato
xlabel('Hora del día (UTC)', 'FontSize',12);
ylabel('Número acumulado de llegadas (aircraft)', 'FontSize',12);
title(sprintf('WP1: Regulation definition - Barcelona (LEBL) - 10 AUG 2025\nPAAR=%d arr/h | AAR=%d arr/h | Delay total=%.0f min | Delay medio=%.1f min/vuelo', ...
    PAAR, AAR, total_delay, avg_delay), 'FontSize',11);
legend([h1,h2,h3], ...
    {'Aggregate demand','Capacity reduced (PAAR)','Capacity nominal (AAR)'}, ...
    'Location','northwest','FontSize',11);
grid on;
xlim([Hstart/60 - 0.3, HNoReg/60 + 1]);
hold off;

fprintf('✓ Gráfica generada.\n\n');
end
