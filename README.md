# 77 GHz FMCW Radar Instrumentation PoC

Software-only simulation of a radar instrumentation chain using MATLAB and Simulink.

## How to Run

```matlab
setup_radar_poc
```

## What It Does

Simulates a 77 GHz FMCW radar detecting a single human target, processes the signal through an analog front end and STM32 MCU, and extracts range, angle, and breathing rate.

Signal chain:

    Radar echo -> RC filter -> Amplifier -> ADC (12-bit) -> STM32 MCU -> Signal Processing -> Detection

## Target

| Property | Value |
|----------|-------|
| Range | 3.0 m |
| Angle | -15 deg |
| Velocity | 0 m/s (stationary) |
| Breathing | 15 BPM, 3 mm chest displacement |

## Files

| File | What it does |
|------|-------------|
| setup_radar_poc.m | Run this. Does everything. |
| radar_parameters.m | All radar and MCU settings |
| radar_target_scene.m | One virtual human target |
| generate_fmcw_echo.m | Generates radar IF signal |
| build_simulink_model.m | Creates the Simulink model |
| radar_signal_processing.m | Range, Doppler, angle FFTs and breathing detection |
| plot_instrumentation_results.m | 3 static plots |
| radar_live_display.m | Animated live radar display |
| adc_quantize.m | ADC quantization helper |
| stm32_fixed_point_fft.m | STM32 fixed-point FFT simulation |

## Toolboxes Needed

- MATLAB
- Simulink
- Signal Processing Toolbox

No Radar Toolbox needed. No physical hardware needed.

## Key Concepts

**FMCW Radar**: Transmits a frequency-sweeping chirp. The beat frequency of the returned echo tells you the target range.

**MIMO**: 2 TX and 4 RX antennas create 8 virtual antenna elements for angle estimation.

**Analog Front End**: RC low-pass filter removes noise, amplifier boosts the signal for the ADC.

**ADC**: Converts analog voltage to 12-bit digital values (LSB = 0.8 mV).

**STM32 MCU**: Reads ADC via SPI, buffers with DMA, runs fixed-point FFT, sends results over UART.

**Breathing Detection**: Chest movement (3 mm) at 77 GHz creates a detectable phase modulation. FFT of the phase signal over 20 seconds reveals the breathing frequency.

## References

1. Multi-Person 2-D Positioning Method Based on 77 GHz FMCW Radar
2. A High Precision Vital Signs Detection Method Based on Millimeter Wave Radar
3. 3D Near-Field Virtual MIMO-SAR Imaging Using FMCW Radar Systems at 77 GHz

Educational proof of concept only.
