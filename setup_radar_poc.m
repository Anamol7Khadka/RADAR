clc; close all; clear;
fprintf('77 GHz FMCW MIMO Radar Instrumentation PoC\n\n');

scriptDir = fileparts(mfilename('fullpath'));
if ~isempty(scriptDir), cd(scriptDir); end

fprintf('[1/7] Loading parameters...\n');
radar_parameters;

fprintf('[2/7] Generating target scene...\n');
radar_target_scene;

fprintf('[3/7] Building Simulink model...\n');
try
    build_simulink_model;
    slx_ok = true;
catch ME
    fprintf('Simulink model failed: %s\nContinuing without it.\n', ME.message);
    slx_ok = false;
end

if slx_ok
    fprintf('[4/7] Running Simulink simulation...\n');
    try
        simOut = sim('radar_instrumentation_poc');
        fprintf('Simulink sim complete.\n');
    catch ME
        fprintf('Sim failed: %s\n', ME.message);
    end
else
    fprintf('[4/7] Skipped (no Simulink).\n');
end

fprintf('[5/7] Processing signals...\n');
radar_signal_processing;

fprintf('[6/7] Generating plots...\n');
plot_instrumentation_results;

fprintf('[7/7] Starting live radar display...\n');
radar_live_display;

fprintf('\nDone. Open Simulink model: open_system(''radar_instrumentation_poc'')\n');
