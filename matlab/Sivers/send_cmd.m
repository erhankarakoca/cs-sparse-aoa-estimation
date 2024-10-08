function resp = send_cmd( tcp_timeout, client, expect_response, delay, verbose, cmd)

%Add CRLF to end of cmd and write to fpga
cmd = uint8( cmd);
cmd(end + 1) = 13;
cmd(end + 1) = 10;
write(client, cmd);
pause(delay); % critical for stability

%Read response
if expect_response
    t1 = datetime( 'now');
    while ~client.BytesAvailable
        t2 = datetime( 'now');
        if seconds( diff( [ t1 t2])) > tcp_timeout
            disp('Command reply TCP timeout');
            closereq
        end
    end
    resp = char(read( client));
    pause(0.05); % critical for stability
    if isequal(uint8( resp( end-1:end)), [ 13 10])
        resp = resp( 1:end-2); % cut \r\n
    end
    if verbose
        disp( resp)
    end
else
    resp = 0;
end
end