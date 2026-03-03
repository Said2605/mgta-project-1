% Navega automáticamente a la carpeta donde está este archivo setup.m
% Funciona en cualquier ordenador sin importar la ruta
cd(fileparts(which('setup')));
clear
parameters
flights = load_flight_data('..\data\LEBL_10AUG2025.xlsx');
idx = flights.arrivals;
[cats, seats] = get_aircraft_info(flights.ATYP, '..\data\fleet_cat_seat.csv');
distances = compute_flight_distance(flights.ETA(idx), flights.ETD(idx), flights.TT(idx), TAXI_IN_LEBL, cats(idx), speeds);
is_ecac = get_ecac_status(flights.ADEP(idx), ECAC_prefixes);
airlines = get_airline(flights.ARCID(idx));