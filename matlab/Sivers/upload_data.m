function upload_data(cmd_client, dat_client, tx_period, datain)

d1 = 0.1;
verbose = 0;
timeout = 2;

%Stop Tx and upload new data
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl stop');
write_dac_data(timeout, dat_client, d1, sprintf('bin2mem 0 %d',tx_period), datain);
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl init 255 0x10');

%Setup AGC
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set enable 0'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set loper %d',tx_period));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set plowdb -26'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set phighdb -18'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set dlow 56'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set dhigh 1'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set data 32'));
send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl agc set channel 2'));

send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('txctl period %f', tx_period));
send_cmd(timeout,cmd_client,1,d1,verbose,'txctl start 0');
% send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('txctl start %d', tx_period));
% send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl radar'));
% send_cmd(timeout,cmd_client,1,d1,verbose,'txctl stop 0');


end