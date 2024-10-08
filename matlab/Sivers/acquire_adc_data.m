function data = acquire_adc_data( tcp_timeout, client, delay, num_samps, cmd, pow_meas)

if nargin < 6
    pow_meas = 0;
end
%Add CRLF to end of cmd
cmd = uint8( cmd);
cmd( end + 1) = 13;
cmd( end + 1) = 10;

write( client, cmd);
pause( delay); % critical for stability

%Wait for response
t1 = datetime( 'now');
while ~client.BytesAvailable
    t2 = datetime( 'now');
    if seconds( diff( [ t1 t2])) > tcp_timeout
        disp('Read data TCP timeout');
        closereq
    end
end

% The client will wait for the server to supply the requested number of bytes
if ~pow_meas
    data = read(client, num_samps*2, 'int16');
else
    data = read(client, num_samps, 'int32');
end
end
