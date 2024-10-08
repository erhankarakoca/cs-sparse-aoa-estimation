function device_calibrate(freq,tx_device,rx_device)
% Calibrates the radios
% Taken from the original Sivers GUI
% Supports only Windows
% INPUTS:
% freq: operation frequency
% tx_device: A string containing the device's SN
% rx_device: A string containing the device's SN
% Last update: 19.07.2023 by MYY

if ~exist('freq','var') || isempty(freq)
    freq = 29e9;
end
fout = fopen('freq.txt','w');
fprintf(fout,'%s\n',freq);
fclose(fout);

if exist('rx_device','var') && ~isempty(rx_device)
    %Startup script in separate file, which reads the frequency from the file
    %created previously in this function
    %Different commands for different OS
    cmd_tmp = sprintf( "rapinoe_start_rx.bat %s", rx_device);
    system( cmd_tmp, '-echo');
end

if exist('tx_device','var') && ~isempty(tx_device)
    cmd_tmp = sprintf( "rapinoe_start_tx.bat %s", tx_device);
    system( cmd_tmp, '-echo');
end


end


