function [  ] = data2FPGA( mode )
%%
    modeHex = dec2hex(mode,4);
%% создание текущего скрипта Data2FPGA.tcl
    CurrentFile  = fopen('Data2FPGA.tcl', 'w');

%% заполнение скрипта Data2FPGA.tcl
    % Setup USB hardware - assumes only USB Blaster is installed and
    % an FPGA is the only device in the JTAG chain
    fprintf(CurrentFile, ['puts "Start"', '\n']);
    fprintf(CurrentFile, ['set usb [lindex [get_hardware_names] 0]', '\n']);
    fprintf(CurrentFile, ['set device_name [lindex [get_device_names -hardware_name $usb] 0]', '\n']); 
    fprintf(CurrentFile, ['start_insystem_source_probe -device_name $device_name -hardware_name $usb', '\n']);
    % new mode generation
    fprintf(CurrentFile, ['write_source_data -instance_index 0 -value 0x1', '00', modeHex, ' -value_in_hex', '\n']);
    fprintf(CurrentFile, ['write_source_data -instance_index 0 -value 0x0', '00', modeHex, ' -value_in_hex', '\n']);
    % end source module
    fprintf(CurrentFile, ['end_insystem_source_probe', '\n']);
    fprintf(CurrentFile, ['puts "Done"', '\n']);
    fclose(CurrentFile);
%% запуск source and probe (quartus)
    dos ('quartus_stp -t Data2FPGA.tcl')
    
end