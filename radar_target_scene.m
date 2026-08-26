targets(1).range = 3.0;
targets(1).angle = -15;
targets(1).velocity = 0;
targets(1).breath_rate = 15;
targets(1).breath_amp = 3e-3;
targets(1).rcs = 1.0;

targets(2).range = 4.5;
targets(2).angle = 20;
targets(2).velocity = 0.5;
targets(2).breath_rate = 12;
targets(2).breath_amp = 4e-3;
targets(2).rcs = 0.8;

[rx_data_cube, rx_signal_1ch] = generate_fmcw_echo(params, targets);

n_sim = params.N_samples * 3;
sim_signal = rx_signal_1ch(1:n_sim);
sim_signal = sim_signal / max(abs(sim_signal)) * 0.1;
t_sim = (0:n_sim-1)' / params.fs_adc;
sim_input = timeseries(sim_signal, t_sim);
sim_stop_time = t_sim(end);

fprintf('Targets generated. Data cube: [%d x %d x %d]\n', ...
    size(rx_data_cube,1), size(rx_data_cube,2), size(rx_data_cube,3));
