function [data_cube, signal_1ch] = generate_fmcw_echo(params, targets)
    N = params.N_samples;
    M = params.N_chirps;
    K = params.N_virtual;
    t_fast = (0:N-1)' / params.fs_adc;
    d_v = params.d_rx;

    data_cube = zeros(N, M, K);

    for chirp = 1:M
        t_slow = (chirp-1) * params.T_frame;
        for t = 1:length(targets)
            tgt = targets(t);
            f_br = tgt.breath_rate / 60;
            R = tgt.range + tgt.velocity*t_slow + tgt.breath_amp*sin(2*pi*f_br*t_slow);
            tau = 2*R / params.c;
            f_beat = params.slope * tau;
            ph_beat = 2*pi * f_beat .* t_fast;
            ph_carrier = 2*pi * params.fc * tau;
            theta = deg2rad(tgt.angle);
            for v = 1:K
                ph_steer = 2*pi * d_v * (v-1) * sin(theta) / params.lambda;
                echo = tgt.rcs * exp(1j*(ph_beat - ph_carrier + ph_steer));
                data_cube(:, chirp, v) = data_cube(:, chirp, v) + echo;
            end
        end
    end

    noise = sqrt(params.noise_power/2) * (randn(N,M,K) + 1j*randn(N,M,K));
    data_cube = data_cube + noise;

    signal_1ch = real(data_cube(:,:,1));
    signal_1ch = signal_1ch(:);
end
