function [eta_hours, fig] = plot_wp1_traffic_demand_example(n_flights)
%% PLOT_WP1_TRAFFIC_DEMAND_EXAMPLE  Genera la gráfica tipo "WP1: Traffic demand data"
%
%   [eta_hours, fig] = plot_wp1_traffic_demand_example(n_flights)
%
%   ENTRADA (opcional)
%     n_flights - número de llegadas simuladas en 24h (por defecto: 700)
%
%   SALIDA
%     eta_hours - vector con horas de llegada simuladas [h]
%     fig       - handle de la figura creada
%
%   La distribución se simula con dos picos (mañana y tarde), similar al
%   ejemplo docente, y se añaden líneas horizontales de capacidad:
%     - Verde: capacidad nominal
%     - Roja: capacidad reducida

if nargin < 1
    n_flights = 700;
end

rng(1);  % reproducible

% -------------------------------------------------------------------------
% 1) Simulación de demanda en 24h con dos picos de llegadas
% -------------------------------------------------------------------------
mu_morning = 8.5;
mu_evening = 15.5;
sigma = 2.0;

n1 = round(0.50 * n_flights);
n2 = n_flights - n1;

peak1 = mu_morning + sigma * randn(n1, 1);
peak2 = mu_evening + sigma * randn(n2, 1);
eta_hours = [peak1; peak2];

% Limitar al intervalo [0, 24]
eta_hours = eta_hours(eta_hours >= 0 & eta_hours <= 24);

% -------------------------------------------------------------------------
% 2) Histograma
% -------------------------------------------------------------------------
fig = figure('Name', 'WP1: Traffic demand data', 'NumberTitle', 'off', ...
             'Color', 'w', 'Position', [120, 80, 980, 620]);

histogram(eta_hours, 24, ...
    'FaceColor', [0.23 0.17 0.67], ...
    'EdgeColor', [0.16 0.11 0.45], ...
    'LineWidth', 0.6);
hold on;

% -------------------------------------------------------------------------
% 3) Líneas de capacidad (como en el ejemplo visual)
% -------------------------------------------------------------------------
cap_nominal = 60;
cap_reduced = 30;

Hstart = 8;    % inicio de reducción
Hend   = 12;   % fin de reducción

% Capacidad nominal (verde) fuera del intervalo regulado
plot([2, Hstart], [cap_nominal, cap_nominal], 'g-', 'LineWidth', 3);
plot([Hend, 22], [cap_nominal, cap_nominal], 'g-', 'LineWidth', 3);

% Capacidad reducida (roja) durante la regulación
plot([Hstart, Hend], [cap_reduced, cap_reduced], 'r-', 'LineWidth', 3);

% -------------------------------------------------------------------------
% 4) Formato
% -------------------------------------------------------------------------
title('Histogram arrivals non-regulated traffic', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('time (hours)', 'FontSize', 12);
ylabel('arrivals (number of aircraft)', 'FontSize', 12);

xlim([0 24]);
ylim([0 70]);
set(gca, 'XTick', 0:5:24, 'YTick', 0:10:70, 'FontSize', 11);
box on;

hold off;

fprintf('✓ Gráfica de demanda simulada generada (%d vuelos efectivos).\n', numel(eta_hours));
end
