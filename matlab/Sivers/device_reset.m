function [tmpout_tx, tmpout_rx] = device_reset(tx_device,rx_device)
% Resets the radios 
% Taken from the original Sivers GUI
% Supports only Windows
% INPUTS:
% tx_device: A string containing the device's SN
% rx_device: A string containing the device's SN
% Last update: 19.07.2023 by MYY

if exist('tx_device','var') && ~isempty(tx_device)
    cmd = "host.reset(rap0)";
    cmd_tmp = sprintf( "rapinoe_send_cmd.bat %s ""%s""", tx_device, cmd);
%     rapinoe_send_cmd.bat T582300517 "host.reset(rap0)"
%     rapinoe_send_cmd.bat T582203143 "host.reset(rap0)"
    [~, tmpout_tx] = system( cmd_tmp, '-echo');
    tmpout_tx = regexprep( tmpout_tx, '\n', '\r');
end
if exist('rx_device','var') && ~isempty(rx_device)
    cmd = "host.reset(rap0)";
    cmd_tmp = sprintf( "rapinoe_send_cmd.bat %s ""%s""", rx_device, cmd);
    [~, tmpout_rx] = system( cmd_tmp, '-echo');
    tmpout_rx = regexprep( tmpout_rx, '\n', '\r');
end

if ~exist('tmpout_tx','var') || isempty(tmpout_tx)
    tmpout_tx = 0;
end
if ~exist('tmpout_rx','var') || isempty(tmpout_rx)
    tmpout_rx = 0;
end

end



