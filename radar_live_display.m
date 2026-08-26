fprintf('Starting live radar display...\n');

N = params.N_samples;
M = params.N_chirps;
half = floor(N/2);
win_r = hanning(N);

freq_ax = (0:N-1) * params.fs_adc / N;
r_ax = freq_ax(1:half) * params.c / (2*params.slope);
N_ang = 64;
u = (-N_ang/2:N_ang/2-1) / N_ang;
ang_ax = asind(u * params.lambda / params.d_rx);
valid_ang = ~isnan(ang_ax) & abs(ang_ax) <= 90;

phase_history = nan(1, M);
time_history = (0:M-1) * params.T_frame;

fig = figure('Name','LIVE RADAR', 'NumberTitle','off', ...
    'Position',[50 50 1100 700], 'Color','k');

ax1 = subplot(2,2,1);
p1 = plot(nan, nan, 'g');
set(ax1, 'Color','k', 'XColor','w', 'YColor','w');
xlabel('Sample'); ylabel('Voltage');
title('IF Signal (current chirp)', 'Color','w');
grid on; set(ax1, 'GridColor',[0.3 0.3 0.3]);

ax2 = subplot(2,2,2);
p2 = plot(r_ax, nan(size(r_ax)), 'c', 'LineWidth', 1.5);
set(ax2, 'Color','k', 'XColor','w', 'YColor','w');
xlabel('Range [m]'); ylabel('Power [dB]');
title('Range Profile', 'Color','w');
xlim([0 8]); ylim([-40 5]); grid on; set(ax2, 'GridColor',[0.3 0.3 0.3]);

ax3 = subplot(2,2,3);
ra_img = imagesc(ang_ax(valid_ang), r_ax, zeros(half, sum(valid_ang)));
set(ax3, 'Color','k', 'XColor','w', 'YColor','w', 'YDir','normal');
xlabel('Angle [deg]'); ylabel('Range [m]');
title('Range-Angle Map', 'Color','w');
colormap(ax3, 'jet'); caxis([-30 0]);

ax4 = subplot(2,2,4);
p4 = plot(nan, nan, 'y', 'LineWidth', 1.2);
set(ax4, 'Color','k', 'XColor','w', 'YColor','w');
xlabel('Time [s]'); ylabel('Phase [rad]');
title('Breathing Signal', 'Color','w');
grid on; set(ax4, 'GridColor',[0.3 0.3 0.3]);

[~, bin1] = min(abs(r_ax - targets(1).range));
step = 2;
ra_accum = zeros(half, N_ang);

pause(0.5);

for chirp = 1:step:M
    if ~ishandle(fig), break; end

    if_sig = real(rx_data_cube(:, chirp, 1));

    rfft_all = zeros(N, params.N_virtual);
    for ch = 1:params.N_virtual
        rfft_all(:, ch) = fft(rx_data_cube(:, chirp, ch) .* win_r, N);
    end

    rp = abs(rfft_all(1:half, 1)).^2;
    rp_dB = 10*log10(rp / max(rp) + 1e-10);

    ra_frame = zeros(half, N_ang);
    for r = 1:half
        ra_frame(r,:) = fftshift(fft(rfft_all(r,:), N_ang));
    end
    ra_accum = 0.8*ra_accum + 0.2*abs(ra_frame);
    ra_dB = 20*log10(ra_accum / max(ra_accum(:)) + 1e-10);

    phase_history(chirp) = angle(rfft_all(bin1, 1));

    valid_ph = ~isnan(phase_history(1:chirp));
    ph_clean = unwrap(phase_history(valid_ph));
    if length(ph_clean) > 3
        ph_clean = detrend(ph_clean);
    end

    set(p1, 'XData', 1:N, 'YData', if_sig);
    set(p2, 'YData', rp_dB);
    set(ra_img, 'CData', ra_dB(:, valid_ang));
    set(p4, 'XData', time_history(valid_ph), 'YData', ph_clean);

    title(ax1, sprintf('IF Signal (chirp %d/%d)', chirp, M), 'Color','w');

    if chirp > 100
        N_resp = 2048;
        fs_s = 1/params.T_frame;
        sp = abs(fft(ph_clean, N_resp));
        fr = (0:N_resp-1)*fs_s/N_resp;
        band = (fr >= 0.1) & (fr <= 0.5);
        sp_b = sp; sp_b(~band) = 0;
        [~, pi_] = max(sp_b);
        bpm = fr(pi_)*60;
        title(ax4, sprintf('Breathing: ~%.0f BPM (%.1fs elapsed)', bpm, chirp*params.T_frame), 'Color','w');
    else
        title(ax4, sprintf('Breathing (%.1fs elapsed)', chirp*params.T_frame), 'Color','w');
    end

    drawnow;
    pause(0.05);
end

fprintf('Live display complete.\n');
