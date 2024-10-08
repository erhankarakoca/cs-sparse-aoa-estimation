function start_tx(cmd_client, dat_client)

verbose = 0;
d1 = 0.1;
timeout = 2;
res = send_cmd(timeout,cmd_client,1,d1,verbose,'tmctl status');
ipp_res = res(strfind(res,'IPS:'):end-1);
ipp_res = split(ipp_res);
ipp = str2double(ipp_res{4});

%Upload frequency calib data
datain = import_dac_data('datain\10MHzSinus_491_52Msps.bin');
tx_period = length(datain)/2; % samples of datain are I-Q-I-Q-I-Q...
data = zeros(1,length(datain)*2,'int16');
data(1:4:end) = datain(1:2:end); % first channel I
data(3:4:end) = datain(1:2:end); % second channel I
data(2:4:end) = datain(2:2:end); % first channel Q
data(4:4:end) = datain(2:2:end); % second channel Q
datain = data;
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl stop');

%Config FPGA settings
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl status');
if ipp ~= 24576000
    send_cmd(timeout,cmd_client,1,d1,verbose,'tmctl ipp 1 24576000');
    send_cmd(timeout,cmd_client,1,d1,verbose,'rfctl if dac 255 0');
    send_cmd(timeout,cmd_client,1,d1,verbose,'rfctl if adc 255 0');
end

%No beamswitching
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl beam 0 0 0'); % no beam sweeping
send_cmd(timeout,cmd_client,1,d1,verbose,'rxctl beam 0 0 0'); % no beam sweeping

%Set initial beams
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('txctl bix %d',6)); % 0 deg beam (6 out of 11)
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl bix %d',6)); % 0 deg beam (6 out of 11)

%Send data on both channels
write_dac_data( timeout, dat_client, d1, sprintf('bin2mem 0 %d',tx_period), datain);
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl init 255 0x10'); 

send_cmd(timeout,cmd_client,1,d1,verbose,'rxctl window 0 0');
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('txctl period %f', tx_period));

send_cmd(timeout,cmd_client,1,d1,verbose,'txctl start 0');
end