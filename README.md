# 77 GHz FMCW Radar Instrumentation PoC

Software-only simulation of a radar instrumentation chain using MATLAB and Simulink.

## How to Run

```matlab
setup_radar_poc
```

## What It Does

Simulates a 77 GHz FMCW radar detecting two human targets, processes the signals through an analog front end and STM32 MCU, and extracts range, angle, velocity, and breathing rate.

Signal chain:

    Radar echo -> RC filter -> Amplifier -> ADC (12-bit) -> STM32 MCU -> Signal Processing -> Detection results

## Files

| File | What it does |
|------|-------------|
| setup_radar_poc.m | Run this. Does everything. |
| radar_parameters.m | All radar and MCU settings |
| radar_target_scene.m | Two virtual human targets |
| generate_fmcw_echo.m | Generates radar IF signal |
| build_simulink_model.m | Creates the Simulink model |
| radar_signal_processing.m | Range, Doppler, angle FFTs and breathing detection |
| plot_instrumentation_results.m | All the plots |
| adc_quantize.m | ADC quantization helper |
| stm32_fixed_point_fft.m | STM32 fixed-point FFT simulation |

## Toolboxes Needed

- MATLAB
- Simulink
- Signal Processing Toolbox
- Simscape + Simscape Electrical (optional, for physical RC circuit demo)

No Radar Toolbox needed. No physical hardware needed.

## Key Concepts

**FMCW Radar**: Transmits a frequency-sweeping chirp. The beat frequency of the returned echo tells you the target range. Range = f_beat * c / (2 * slope).

**MIMO**: 2 TX and 4 RX antennas create 8 virtual antenna elements, improving angle resolution without extra hardware.

**Analog Front End**: RC low-pass filter removes noise, amplifier boosts the weak echo signal to match the ADC input range.

**ADC**: Converts the analog voltage to 12-bit digital values. LSB = 3.3V / 4095 = 0.8 mV.

**STM32 MCU**: Reads ADC samples over SPI, buffers via DMA, performs a fixed-point (Q15) FFT for range processing, and sends results to the host PC over UART.

**Range FFT**: FFT along fast-time samples within each chirp. Each frequency bin maps to a range.

**Doppler FFT**: FFT across chirps (slow-time). Phase change between chirps reveals target velocity.

**Angle FFT**: FFT across virtual antenna elements. Phase difference between antennas encodes angle of arrival.

**Breathing Detection**: A breathing person's chest moves a few mm. At 77 GHz (wavelength = 3.9 mm), this creates a detectable phase modulation. We extract the phase over time and look for the breathing frequency (0.1 to 0.5 Hz).

## Targets

| | Range | Angle | Velocity | Breathing |
|---|---|---|---|---|
| Target 1 | 3.0 m | -15 deg | 0 m/s | 15 BPM |
| Target 2 | 4.5 m | +20 deg | 0.5 m/s | 12 BPM |

## Disclaimer

This is an educational proof of concept, not a medical device or production radar system.

## References

1. Multi-Person 2-D Positioning Method Based on 77 GHz FMCW Radar
2. A High Precision Vital Signs Detection Method Based on Millimeter Wave Radar
3. 3D Near-Field Virtual MIMO-SAR Imaging Using FMCW Radar Systems at 77 GHz
