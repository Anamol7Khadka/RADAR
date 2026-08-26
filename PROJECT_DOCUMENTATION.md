# 77 GHz FMCW Radar PoC - Complete Code Explanation

## How It All Fits Together

```
setup_radar_poc.m  (runs everything in order)
    │
    ├─ radar_parameters.m     (sets all numbers)
    ├─ radar_target_scene.m   (creates fake targets)
    │   └─ generate_fmcw_echo.m  (does the radar math)
    ├─ build_simulink_model.m (builds the Simulink circuit)
    ├─ radar_signal_processing.m  (FFTs and detection)
    │   ├─ stm32_fixed_point_fft.m  (MCU FFT simulation)
    │   └─ adc_quantize.m           (ADC simulation)
    ├─ plot_instrumentation_results.m  (3 static plots)
    └─ radar_live_display.m   (animated live radar)
```

---

## 1. setup_radar_poc.m

This is the master script. You run this one file and it calls everything else.

```matlab
clc; close all; clear;
```
Clears the console, closes all figures, and wipes all variables so we start fresh.

```matlab
scriptDir = fileparts(mfilename('fullpath'));
if ~isempty(scriptDir), cd(scriptDir); end
```
Finds where this script lives on disk and changes into that folder so all the other files can be found.

Then it runs each step in order:
1. Load parameters
2. Generate virtual targets
3. Build the Simulink model (wrapped in try-catch so if Simulink isn't installed, it skips)
4. Run the Simulink simulation
5. Run signal processing (Range FFT, Doppler, angle, breathing)
6. Generate 3 static plots
7. Launch the live animated display

---

## 2. radar_parameters.m

This file just sets numbers. Every other file reads from the `params` struct.

```matlab
params.c = 299792458;          % speed of light in m/s
params.fc = 77e9;              % 77 GHz carrier frequency
params.lambda = params.c / params.fc;  % wavelength = c/f = 3.9 mm
```
The wavelength at 77 GHz is about 3.9 mm. This small wavelength is why mmWave radar can detect tiny chest movements from breathing.

```matlab
params.B = 1e9;                % 1 GHz bandwidth
params.T_chirp = 40e-6;        % 40 microsecond chirp
params.slope = params.B / params.T_chirp;  % = 2.5e13 Hz/s
```
The FMCW chirp sweeps 1 GHz of bandwidth over 40 microseconds. The slope (how fast frequency changes) is key to converting beat frequency to range.

```matlab
params.fs_adc = 10e6;          % ADC samples at 10 MHz
params.N_samples = 256;        % 256 samples per chirp
```
Within each chirp, the ADC takes 256 samples at 10 million samples/second.

```matlab
params.N_chirps = 512;
params.T_frame = 20e-3;        % 20 ms between snapshots
```
We take 512 radar snapshots, one every 20 ms. Total observation = 512 x 20ms = 10.24 seconds. This is long enough to see about 2.5 breathing cycles at 15 breaths/min.

```matlab
params.N_TX = 2;   params.N_RX = 4;
params.N_virtual = params.N_TX * params.N_RX;   % = 8
params.d_rx = params.lambda / 2;                 % half-wavelength spacing
```
MIMO antenna setup. 2 transmitters and 4 receivers create 8 "virtual" antenna elements. This gives us angle-sensing ability without 8 physical antennas. Antennas are spaced half a wavelength apart (about 1.95 mm).

```matlab
params.delta_R = params.c / (2*params.B);        % = 0.15 m
```
Range resolution. With 1 GHz bandwidth, we can distinguish targets 15 cm apart.

```matlab
params.amp_gain = 20;          % amplifier multiplies voltage by 20
params.f_cutoff = 4e6;         % filter passes frequencies below 4 MHz
params.R_filter = 100;         % 100 ohm resistor
params.C_filter = 1/(2*pi*params.R_filter*params.f_cutoff);  % capacitor value
```
Analog front end: an RC low-pass filter (cutoff = 1/(2*pi*R*C) = 4 MHz) and a gain-20 amplifier.

```matlab
params.adc_bits = 12;
params.adc_vref = 3.3;
params.adc_LSB = params.adc_vref / (2^params.adc_bits - 1);  % about 0.8 mV
```
12-bit ADC with 3.3V reference. It can distinguish voltage steps of about 0.8 mV.

```matlab
params.mcu_clock = 168e6;      % STM32F4 runs at 168 MHz
params.mcu_fft_bits = 16;      % uses 16-bit fixed-point math
```
STM32F4 microcontroller parameters. It processes data using 16-bit integers instead of floating-point, which is faster but less precise.

---

## 3. radar_target_scene.m

Defines two virtual human targets:

- Target 1: 3.0 m away, 15 degrees left, stationary, breathing at 15 BPM (3 mm chest movement)
- Target 2: 4.5 m away, 20 degrees right, walking at 0.5 m/s, breathing at 12 BPM (4 mm)

Then calls generate_fmcw_echo() to create the radar return signal.

The last part takes 3 chirps of data, scales to 100 mV, and packages as a timeseries for Simulink.

---

## 4. generate_fmcw_echo.m

This is the core radar physics. It calculates what the radar receiver would actually see.

For each chirp and each target:

```matlab
R = tgt.range + tgt.velocity*t_slow + tgt.breath_amp*sin(2*pi*f_br*t_slow);
```
Target range at this moment. Changes due to velocity (walking) and breathing (chest in/out).

```matlab
tau = 2*R / params.c;
```
Round-trip time. Signal travels to target and back, so distance = 2R.

```matlab
f_beat = params.slope * tau;
```
Beat frequency. This is the key FMCW equation: when you mix the transmitted chirp with the delayed received chirp, you get a sinusoid whose frequency is proportional to delay. Farther target = higher beat frequency.

```matlab
ph_steer = 2*pi * d_v * (v-1) * sin(theta) / params.lambda;
```
Steering phase. Each virtual antenna sees the signal arrive at a slightly different time because they're spaced apart. This phase difference encodes the target's angle.

```matlab
echo = tgt.rcs * exp(1j*(ph_beat - ph_carrier + ph_steer));
```
The complex echo combining all phases. Using complex math lets us track both amplitude and phase.

Noise is added at the end to simulate real conditions.

---

## 5. adc_quantize.m

Simulates what a real 12-bit ADC does:
1. Clamp input to [0, 3.3V]
2. Round to nearest 0.8 mV step (quantization)

---

## 6. stm32_fixed_point_fft.m

Compares PC-quality FFT (64-bit float) with STM32 MCU FFT (16-bit fixed-point).

The MCU normalizes the signal to [-1, 1], quantizes to 16-bit precision (only 32768 possible values), then computes FFT. The difference shows how much precision the MCU loses compared to a PC.

---

## 7. build_simulink_model.m

Creates a Simulink model with 6 blocks in a line:

| Block | Type | What It Represents |
|-------|------|-------------------|
| Radar_IF | From Workspace | Reads the radar signal |
| RC_Filter | Transfer Fcn | RC low-pass filter: H(s) = 1/(RCs + 1) |
| Amplifier | Gain | Multiplies signal by 20 |
| ADC_12bit | Quantizer | Rounds to 0.8 mV steps |
| STM32_MCU | Rate Transition | SPI clock domain crossing |
| Output | To Workspace | Saves result to MATLAB |

Two scopes tap the analog and digital signals.

---

## 8. radar_signal_processing.m

### Range FFT
FFT along 256 fast-time samples within each chirp. Each FFT bin maps to a range via R = f_beat * c / (2 * slope). We get peaks at 3.0 m and 4.5 m.

### Doppler FFT
FFT across 512 chirps for each range bin. A moving target causes phase shifts between chirps. Converts to velocity: v = f_doppler * lambda / 2.

### Angle FFT
FFT across 8 virtual antennas for each range bin. Phase gradient across antennas encodes angle: theta = arcsin(u * lambda / d).

### Target Detection
findpeaks() finds peaks above -15 dB in the range profile. For each peak, looks up angle and velocity from the 2D maps.

### Respiration
Extracts phase at target 1's range bin across all chirps. Phase modulation from chest movement: delta_phi = 4*pi*displacement/lambda. For 3 mm at 3.9 mm wavelength, that's about 9.7 radians. FFT of the phase signal finds the breathing frequency (0.1-0.5 Hz band). Multiply by 60 for BPM.

---

## 9. plot_instrumentation_results.m

Three figures:
1. Range Profile: power vs range with detected peak markers
2. Range-Angle Map: 2D color plot showing where targets are in range and angle
3. Respiration: phase waveform over time + frequency spectrum with BPM estimate

---

## 10. radar_live_display.m

Animated display with 4 panels on dark background. Loops through chirps one by one:
- Top-left: current chirp IF signal (green waveform)
- Top-right: range profile updating live (cyan)
- Bottom-left: range-angle map building up over time
- Bottom-right: breathing phase growing, with live BPM estimate after 1 second

Updates at about 30 fps using drawnow.

---

## Summary

The whole system models what a real radar does:

1. Radar sends chirps, receives echoes from targets
2. Echoes pass through analog electronics (filter + amplifier)
3. ADC converts analog voltage to digital numbers
4. STM32 microcontroller reads and processes the data
5. FFTs convert time-domain signals into range, velocity, and angle
6. Phase tracking over time reveals breathing rate
