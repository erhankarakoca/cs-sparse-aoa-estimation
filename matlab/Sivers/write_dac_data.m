function resp = write_dac_data( tcp_timeout, client, delay, cmd, data)

%Add CRLF to end of cmd
cmd = uint8(cmd);
cmd(end + 1) = 13;
cmd(end + 1) = 10;
write(client, cmd);
pause(delay); % critical for stability
% Note: WriteDataToMemory returns no string

write(client, data); % this one returns a string
pause(0.5); % critical for stability

t1 = datetime( 'now');
while ~client.BytesAvailable
    t2 = datetime( 'now');
    if seconds( diff( [ t1 t2])) > tcp_timeout
        disp('Write data TCP timeout')
        closereq
    end
end
resp = char( read( client));
pause( 0.05); % critical for stability
if isequal( uint8( resp( end-1:end)), [ 13 10])
    resp = resp( 1:end-2); % cut \r\n
end
% disp( resp)
end