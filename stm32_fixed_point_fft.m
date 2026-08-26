function [fft_fixed, fft_float] = stm32_fixed_point_fft(signal, n_bits)
    if nargin < 2, n_bits = 16; end
    fft_float = fft(signal);
    peak = max(abs(signal));
    if peak > 0
        normalized = signal / peak;
    else
        normalized = signal;
    end
    scale = 2^(n_bits-1);
    quantized = round(normalized*(scale-1)) / (scale-1);
    fft_fixed = fft(quantized) * peak;
end
