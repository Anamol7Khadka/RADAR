function digital = adc_quantize(analog, vref, n_bits)
    LSB = vref / (2^n_bits - 1);
    clamped = max(0, min(analog, vref));
    digital = round(clamped / LSB) * LSB;
end
