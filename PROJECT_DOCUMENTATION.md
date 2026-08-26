# 77 GHz FMCW Radar PoC - Complete Code Explanation

## How It All Fits Together

```
setup_radar_poc.m  (runs everything in order)
    |
    +-- radar_parameters.m     (sets all numbers)
    +-- radar_target_scene.m   (creates one target)
    |   +-- generate_fmcw_echo.m  (does the radar math)
    +-- build_simulink_model.m (builds the Simulink circuit)
    +-- radar_signal_processing.m  (FFTs and detection)
    |   +-- stm32_fixed_point_fft.m  (MCU FFT simulation)
    |   +-- adc_quantize.m           (ADC simulation)
    +-- plot_instrumentation_results.m  (3 static plots)
    +-- radar_live_display.m   (animated live radar)
```

---

## 1. setup_radar_poc.m

Master script. Run this and it calls everything else in order:
1. Load parameters
2. Generate one virtual target
3. Build Simulink model (skips if Simulink not installed)
4. Run Simulink simulation
5. Signal processing (Range/Doppler/Angle FFTs, breathing)
6. 3 static plots
7. Live animated display

---

## 2. radar_parameters.m

Sets all numbers in a `params` struct that every other file reads.

- `fc = 77e9` - 77 GHz carrier. Wavelength = 3.9 mm. Small enough to detect mm-scale chest movement.
- `B = 1e9` - 1 GHz bandwidth gives 15 cm range resolution.
- `T_chirp = 40e-6` - each chirp lasts 40 microseconds.
- `slope = B/T_chirp` - how fast frequency sweeps. Used to convert beat frequency to range.
- `fs_adc = 10e6` - ADC samples at 10 MHz. 256 samples per chirp.
- `N_chirps = 1024` at `T_frame = 20ms` - 1024 snapshots over 20.48 seconds. Long enough to see ~5 breathing cycles.
- `N_TX=2, N_RX=4` - MIMO: 8 virtual antenna elements for angle estimation.
- `amp_gain = 20` - amplifier boosts weak echo by 20x.
- `f_cutoff = 4e6` - RC filter cutoff. R=100 ohm, C calculated from fc = 1/(2*pi*R*C).
- `adc_bits = 12, adc_vref = 3.3V` - 12-bit ADC, LSB = 0.8 mV.
- `mcu_clock = 168e6` - STM32F4 at 168 MHz, 16-bit fixed-point FFT.

---

## 3. radar_target_scene.m

Defines one virtual human target:
- 3.0 m away, 15 degrees to the left, stationary, breathing at 15 BPM with 3 mm chest displacement.

Calls `generate_fmcw_echo()` to create the radar return signal, then scales a short segment to 100 mV and packages it as a timeseries for Simulink.

---

## 4. generate_fmcw_echo.m

Core radar physics. For each of 1024 chirps:

- `R = range + breath_amp * sin(2*pi*breath_freq*t)` - target range changes with breathing.
- `tau = 2*R/c` - round-trip time delay.
- `f_beat = slope * tau` - beat frequency proportional to range (the key FMCW equation).
- `ph_steer = 2*pi*d*(v-1)*sin(theta)/lambda` - phase shift across antennas encodes angle.
- `echo = rcs * exp(1j*(ph_beat - ph_carrier + ph_steer))` - complex echo signal.

Adds noise. Returns a 3D data cube: [256 samples x 1024 chirps x 8 virtual antennas].

---

## 5. adc_quantize.m

Simulates a 12-bit ADC: clamps input to [0, 3.3V], rounds to nearest 0.8 mV step.

---

## 6. stm32_fixed_point_fft.m

Compares PC FFT (64-bit float) with STM32 FFT (16-bit fixed-point). Normalizes signal to [-1,1], quantizes to 16-bit, runs FFT. Shows how much precision the MCU loses.

---

## 7. build_simulink_model.m

Creates a Simulink model with 6 blocks in a line:

    Radar_IF -> RC_Filter -> Amplifier -> ADC_12bit -> STM32_MCU -> Output

The RC_Filter uses a Transfer Function block: H(s) = 1/(RC*s + 1). Two scopes tap the analog and digital signals.

---

## 8. radar_signal_processing.m

### Range FFT
FFT of 256 fast-time samples within each chirp. Each bin maps to a range: R = f_beat * c / (2 * slope). Detects peak at ~3.0 m.

### Doppler FFT
FFT across 1024 chirps at each range bin. Phase shift between chirps reveals velocity: v = f_doppler * lambda / 2.

### Angle FFT
FFT across 8 virtual antennas at each range bin. Phase gradient encodes angle: theta = arcsin(u * lambda / d).

### Detection
findpeaks() finds the target peak above -15 dB. Looks up its angle and velocity from the 2D maps.

### Respiration
Extracts phase at the target's range bin over 1024 chirps (20.48 seconds). Chest displacement of 3 mm at 3.9 mm wavelength produces ~9.7 radians of phase shift. FFT of the phase finds the breathing frequency in the 0.1-0.5 Hz band (6-30 BPM). Multiply by 60 for BPM.

---

## 9. plot_instrumentation_results.m

Three figures:
1. Range Profile: power vs range, peak marked at 3.0 m
2. Range-Angle Map: 2D color plot, target visible at -15 degrees
3. Respiration: phase waveform over 20 seconds + frequency spectrum with BPM

---

## 10. radar_live_display.m

Animated display with 4 panels on dark background. Processes chirps one by one at ~20 fps:
- IF signal (green waveform)
- Range profile (cyan, updating)
- Range-angle map (building up)
- Breathing phase (growing over time, BPM estimate appears after 2 seconds)

Runs for about 25 seconds total.

---

## Summary

Radar sends chirps -> receives echo from one person -> filters and amplifies -> ADC digitizes -> STM32 processes -> FFTs extract range, angle, and breathing rate.
