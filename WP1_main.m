%% WP1_MAIN.M
% Script principal del Work Package 1 - Proyecto MGTA
% Aeropuerto: Barcelona (LEBL) - 10 de Agosto de 2025
%
% Este script ejecuta todas las funciones del WP1 en orden y genera
% todos los resultados y gráficas necesarias para el informe.
%
% CÓMO EJECUTAR:
%   1. Asegúrate de estar en la carpeta WP1/
%   2. Escribe "WP1_main" en la Command Window y pulsa Enter
%   3. Todos los resultados aparecerán en el workspace y las gráficas
%      se generarán automáticamente.
%
% ESTRUCTURA:
%   Bloque 0: Inicialización
%   Bloque 1: Datos de tráfico (puntos a, b, c, d del enunciado)
%   Bloque 2: Definición de la regulación (puntos 3, 4, 5 del enunciado)
%   Bloque 3: Resumen de KPIs

fprintf('╔══════════════════════════════════════════════════════╗\n');
fprintf('║         WP1 - MGTA - Barcelona (LEBL)               ║\n');
fprintf('║         10 de Agosto de 2025                         ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n\n');

% =========================================================================
%% BLOQUE 0: INICIALIZACIÓN
% =========================================================================
clear;
cd(fileparts(which('WP1_main')));   % asegura que estamos en la carpeta WP1
parameters;                          % carga todos los parámetros

% =========================================================================
%% BLOQUE 1: DATOS DE TRÁFICO
% =========================================================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('BLOQUE 1: Datos de tráfico\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% --- Cargar datos del Excel ---
flights = load_flight_data(FILE_FLIGHTS);

% --- Índices de vuelos que LLEGAN a LEBL ---
idx = flights.arrivals;

% --- Gráfica de ejemplo tipo diapositiva WP1 (demanda simulada 24h) ---
plot_wp1_traffic_demand_example(700);

% --- (a) Categoría RECAT-EU y asientos ---
[cats, seats] = get_aircraft_info(flights.ATYP, FILE_FLEET);

% --- (b) Distancia de vuelo ---
distances = compute_flight_distance( ...
    flights.ETA(idx), flights.ETD(idx), flights.TT(idx), ...
    TAXI_IN_LEBL, cats(idx), speeds);

% --- (c) Origen ECAC ---
is_ecac = get_ecac_status(flights.ADEP(idx), ECAC_prefixes);

% --- (d) Aerolínea ---
airlines = get_airline(flights.ARCID(idx));

% =========================================================================
%% BLOQUE 2: DEFINICIÓN DE LA REGULACIÓN
% =========================================================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('BLOQUE 2: Definición de la regulación\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% --- Demanda acumulada y HNoReg ---
ETA_arrivals = flights.ETA(idx);
[HNoReg, total_delay, AggregateDemand, AggregateCapacity] = ...
    compute_regulation(ETA_arrivals, Hstart, Hend, PAAR, AAR);

% --- Matriz de slots ---
slots = compute_slots(Hstart, Hend, HNoReg, PAAR, AAR);

% =========================================================================
%% BLOQUE 3: RESUMEN DE KPIs
% =========================================================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('BLOQUE 3: Resumen de KPIs del WP1\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

n_arr       = length(idx);
n_ecac      = sum(is_ecac);
n_no_ecac   = sum(~is_ecac);
avg_dist    = mean(distances(distances > 0));
% Vuelos afectados = solo los que tienen ETA entre Hstart y HNoReg
n_affected  = sum(ETA_arrivals >= Hstart & ETA_arrivals <= HNoReg);
avg_delay   = total_delay / max(n_affected, 1);
dur_reg_min = HNoReg - Hstart;

fprintf('── KPA: Capacity ─────────────────────────────────────\n');
fprintf('  AAR (capacidad nominal):        %d llegadas/hora\n', AAR);
fprintf('  PAAR (capacidad reducida):       %d llegadas/hora\n', PAAR);
fprintf('  Duración regulación (Hstart→HNoReg): %dh%02d\n', ...
    floor(dur_reg_min/60), mod(round(dur_reg_min),60));
fprintf('  Total slots generados:           %d\n', size(slots,1));

fprintf('\n── KPA: Operational Efficiency ───────────────────────\n');
fprintf('  Delay total mínimo:              %.0f minutos\n', total_delay);
fprintf('  Delay medio por vuelo:           %.1f minutos\n', avg_delay);
fprintf('  Distancia media de vuelo:        %.0f km\n', avg_dist);
fprintf('  Distancia mínima:                %.0f km\n', min(distances(distances>0)));
fprintf('  Distancia máxima:                %.0f km\n', max(distances));

fprintf('\n── KPA: Access and Equity ────────────────────────────\n');
fprintf('  Vuelos totales llegando a LEBL:  %d\n', n_arr);
fprintf('  Vuelos desde ECAC (Europa):      %d (%.1f%%)\n', n_ecac, 100*n_ecac/n_arr);
fprintf('  Vuelos desde fuera ECAC:         %d (%.1f%%)\n', n_no_ecac, 100*n_no_ecac/n_arr);

fprintf('\n── KPA: Predictability ───────────────────────────────\n');
fprintf('  Hfile  (publicación regulación): %dh%02d\n', floor(Hfile/60),  mod(Hfile,60));
fprintf('  Hstart (inicio cap. reducida):   %dh%02d\n', floor(Hstart/60), mod(Hstart,60));
fprintf('  Hend   (fin cap. reducida):      %dh%02d\n', floor(Hend/60),   mod(Hend,60));
fprintf('  HNoReg (fin regulación):         %dh%02d\n', floor(HNoReg/60), mod(round(HNoReg),60));

fprintf('\n╔══════════════════════════════════════════════════════╗\n');
fprintf('║  WP1 completado. Todas las variables están en el    ║\n');
fprintf('║  workspace listas para WP2.                         ║\n');
fprintf('╚══════════════════════════════════════════════════════╝\n');
