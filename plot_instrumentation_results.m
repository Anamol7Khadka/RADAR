fprintf('Generating plots...\n');

figure('Name','Range Profile');
plot(range_axis, range_dB, 'b-', 'LineWidth',1.5); hold on;
plot(det_ranges(1), pks(1), 'rv', 'MarkerSize',12, 'MarkerFaceColor','r');
text(det_ranges(1)+0.1, pks(1)+1, sprintf('%.2fm',det_ranges(1)), 'Color','r');
xlabel('Range [m]'); ylabel('Power [dB]');
title('Range Profile - Detected Target'); grid on; xlim([0 10]);

figure('Name','Range-Angle');
valid = ~isnan(angle_axis) & abs(angle_axis)<=90;
imagesc(angle_axis(valid), range_axis, ...
    20*log10(abs(range_angle(:,valid))/max(abs(range_angle(:)))));
xlabel('Angle [deg]'); ylabel('Range [m]');
title('Range-Angle Map'); colorbar; colormap('jet'); caxis([-40 0]);
set(gca,'YDir','normal');
hold on;
plot(targets(1).angle, targets(1).range, 'wo', 'MarkerSize',15, 'LineWidth',2);

figure('Name','Respiration');
subplot(2,1,1);
plot(t_slow_ax, phase_slow, 'b-');
xlabel('Time [s]'); ylabel('Phase [rad]');
title(sprintf('Respiration Phase (Target at %.1fm)', targets(1).range)); grid on;
subplot(2,1,2);
plot(resp_freqs*60, resp_spec, 'b-'); hold on;
xline(targets(1).breath_rate, 'g--', 'LineWidth',2);
xline(est_bpm, 'r--', 'LineWidth',2);
legend('Spectrum','Actual','Estimated');
xlabel('BPM'); ylabel('Magnitude');
title(sprintf('Breathing: Estimated %.1f BPM (Actual %.1f)', est_bpm, targets(1).breath_rate));
xlim([0 60]); grid on;

fprintf('Done.\n');
