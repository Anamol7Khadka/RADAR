modelName = 'radar_instrumentation_poc';

try close_system(modelName, 0); catch, end
if exist([modelName '.slx'], 'file'), delete([modelName '.slx']); end

new_system(modelName);
open_system(modelName);

set_param(modelName, 'Solver','ode45', 'StopTime',num2str(sim_stop_time), ...
    'MaxStep',num2str(1/params.fs_adc), 'RelTol','1e-5');

tau_rc = params.R_filter * params.C_filter;
bw=120; bh=40; y=120; gap=160;

x = 50;
add_block('simulink/Sources/From Workspace', [modelName '/Radar_IF'], ...
    'Position',[x y x+bw y+bh], 'VariableName','sim_input', ...
    'SampleTime',num2str(1/params.fs_adc));

x = x+gap;
add_block('simulink/Continuous/Transfer Fcn', [modelName '/RC_Filter'], ...
    'Position',[x y x+bw y+bh], 'Numerator','[1]', ...
    'Denominator',sprintf('[%e 1]', tau_rc));

x = x+gap;
add_block('simulink/Math Operations/Gain', [modelName '/Amplifier'], ...
    'Position',[x y x+bw y+bh], 'Gain',num2str(params.amp_gain));

x = x+gap;
add_block('simulink/Discontinuities/Quantizer', [modelName '/ADC_12bit'], ...
    'Position',[x y x+bw y+bh], 'QuantizationInterval',num2str(params.adc_LSB));

x = x+gap;
add_block('simulink/Signal Attributes/Rate Transition', [modelName '/STM32_MCU'], ...
    'Position',[x y x+bw y+bh]);

x = x+gap;
add_block('simulink/Sinks/To Workspace', [modelName '/Output'], ...
    'Position',[x y x+bw y+bh], 'VariableName','mcu_output', 'SaveFormat','Timeseries');

add_block('simulink/Sinks/Scope', [modelName '/Scope_Analog'], ...
    'Position',[50+gap+60, y+70, 50+gap+110, y+100]);
add_block('simulink/Sinks/Scope', [modelName '/Scope_Digital'], ...
    'Position',[50+4*gap+60, y+70, 50+4*gap+110, y+100]);

add_block('built-in/Note', [modelName '/L1'], 'Position',[50 y-30 160 y-10], 'Text','Radar Signal');
add_block('built-in/Note', [modelName '/L2'], 'Position',[50+gap y-30 50+gap+140 y-10], 'Text','Analog Filter');
add_block('built-in/Note', [modelName '/L3'], 'Position',[50+2*gap y-30 50+2*gap+100 y-10], 'Text','Amplifier');
add_block('built-in/Note', [modelName '/L4'], 'Position',[50+3*gap y-30 50+3*gap+100 y-10], 'Text','12-bit ADC');
add_block('built-in/Note', [modelName '/L5'], 'Position',[50+4*gap y-30 50+4*gap+120 y-10], 'Text','STM32F4');
add_block('built-in/Note', [modelName '/L6'], 'Position',[50+5*gap y-30 50+5*gap+100 y-10], 'Text','Host PC');

blocks = {'Radar_IF','RC_Filter','Amplifier','ADC_12bit','STM32_MCU','Output'};
for i = 1:length(blocks)-1
    add_line(modelName, [blocks{i} '/1'], [blocks{i+1} '/1']);
end

add_line(modelName, 'RC_Filter/1', 'Scope_Analog/1');
add_line(modelName, 'ADC_12bit/1', 'Scope_Digital/1');

save_system(modelName);
fprintf('Model saved: %s.slx\n', modelName);
