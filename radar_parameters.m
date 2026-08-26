params.c = 299792458;
params.fc = 77e9;
params.lambda = params.c / params.fc;

params.B = 1e9;
params.T_chirp = 40e-6;
params.slope = params.B / params.T_chirp;

params.fs_adc = 10e6;
params.N_samples = 256;

params.N_chirps = 1024;
params.T_frame = 20e-3;
params.CRI = params.T_frame;

params.N_TX = 2;
params.N_RX = 4;
params.N_virtual = params.N_TX * params.N_RX;
params.d_rx = params.lambda / 2;

params.delta_R = params.c / (2*params.B);
params.R_max = params.fs_adc * params.c / (2*params.slope);
params.v_max = params.lambda / (4*params.CRI);
params.total_time = params.N_chirps * params.T_frame;

params.amp_gain = 20;
params.amp_saturation = 3.0;
params.f_cutoff = 4e6;
params.R_filter = 100;
params.C_filter = 1/(2*pi*params.R_filter*params.f_cutoff);

params.adc_bits = 12;
params.adc_vref = 3.3;
params.adc_LSB = params.adc_vref / (2^params.adc_bits - 1);

params.noise_power = 1e-4;

params.mcu_clock = 168e6;
params.mcu_spi_clock = 21e6;
params.mcu_fft_bits = 16;
params.mcu_uart_baud = 921600;

fprintf('Params loaded. lambda=%.2fmm, dR=%.2fm, observation=%.1fs\n', ...
    params.lambda*1e3, params.delta_R, params.total_time);
