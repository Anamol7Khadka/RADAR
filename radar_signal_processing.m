N = params.N_samples;
M = params.N_chirps;
half = floor(N/2);

win_r = hanning(N);
range_fft = zeros(N, M, params.N_virtual);
for ch = 1:params.N_virtual
    for c = 1:M
        range_fft(:,c,ch) = fft(rx_data_cube(:,c,ch) .* win_r, N);
    end
end

freq_axis = (0:N-1) * params.fs_adc / N;
range_axis = freq_axis(1:half) * params.c / (2*params.slope);
range_profile = mean(abs(range_fft(1:half,:,1)).^2, 2);

win_d = hanning(M)';
range_doppler = zeros(half, M);
for r = 1:half
    row = squeeze(range_fft(r,:,1));
    range_doppler(r,:) = fftshift(fft(row .* win_d, M));
end
doppler_hz = (-M/2:M/2-1) / (M * params.T_frame);
velocity_axis = doppler_hz * params.lambda / 2;

N_ang = 64;
range_angle = zeros(half, N_ang);
for r = 1:half
    spatial = squeeze(mean(range_fft(r,:,:), 2));
    range_angle(r,:) = fftshift(fft(spatial, N_ang));
end
u = (-N_ang/2:N_ang/2-1) / N_ang;
angle_axis = asind(u * params.lambda / params.d_rx);

range_dB = 10*log10(range_profile / max(range_profile));
[pks, locs] = findpeaks(range_dB, 'MinPeakHeight', -15, 'MinPeakDistance', 5);
det_ranges = range_axis(locs);
det_angles = zeros(size(locs));
det_vels = zeros(size(locs));

for k = 1:length(locs)
    [~, ai] = max(abs(range_angle(locs(k),:)).^2);
    det_angles(k) = angle_axis(ai);
    [~, di] = max(abs(range_doppler(locs(k),:)).^2);
    det_vels(k) = velocity_axis(di);
end

[~, bin1] = min(abs(range_axis - targets(1).range));
phase_slow = unwrap(angle(range_fft(bin1,:,1)));
phase_slow = detrend(phase_slow);
t_slow_ax = (0:M-1) * params.T_frame;
fs_slow = 1 / params.T_frame;

N_resp = 2048;
resp_spec = abs(fft(phase_slow, N_resp));
resp_freqs = (0:N_resp-1) * fs_slow / N_resp;
band = (resp_freqs >= 0.1) & (resp_freqs <= 0.5);
resp_band = resp_spec; resp_band(~band) = 0;
[~, pk_idx] = max(resp_band);
est_bpm = resp_freqs(pk_idx) * 60;

test_chirp = real(rx_data_cube(:,1,1));
[fft_fixed, fft_float] = stm32_fixed_point_fft(test_chirp, params.mcu_fft_bits);

adc_raw = sim_signal(1:100);
adc_biased = adc_raw + params.adc_vref/2;
adc_amped = max(0, min(adc_biased * params.amp_gain, params.adc_vref));
adc_quant = adc_quantize(adc_amped, params.adc_vref, params.adc_bits);

fprintf('\nDetected targets:\n');
for k = 1:min(length(locs), length(targets))
    fprintf('  T%d: R=%.2fm (actual %.1f), Ang=%.1f deg (actual %.1f), Vel=%.2f m/s\n', ...
        k, det_ranges(k), targets(k).range, det_angles(k), targets(k).angle, det_vels(k));
end
fprintf('  Breathing (T1): %.1f BPM estimated (actual: %.1f BPM)\n\n', ...
    est_bpm, targets(1).breath_rate);
