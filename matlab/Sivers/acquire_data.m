function dataout = acquire_data(cmd_client, dat_client, ch_mask, period,pow)
% pow to measure power
timeout = 2;
d1 = 0.1;
verbose = 0;
nchannels = length(strfind(dec2bin(ch_mask),'1'));
if exist("pow","var")
    send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl power 1 %d',period));
    send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl sample %d',1));
    dataout = acquire_adc_data(timeout,dat_client,d1,nchannels*1,sprintf('mem2bin %d %d',ch_mask,1),1);
    send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl power 0 0'));
else
    %Read data with period number of IQ-samples
    send_cmd(timeout,cmd_client,1,d1,verbose,sprintf('rxctl sample %d',period));
    dataout = acquire_adc_data(timeout,dat_client,d1,nchannels*period,sprintf('mem2bin %d %d',ch_mask,period));
    dataout = reshape(dataout,2*nchannels,[]);
    if nchannels > 1
        data_temp = zeros(nchannels,length(dataout));
        for i=1:nchannels
            data_temp(i,:) = (double(dataout(i*2-1,:)) + 1j * double(dataout(i*2,:)))/2^15;
        end
        dataout = data_temp;
    else
        dataout = (double(dataout(1,:)) + 1j * double(dataout(2,:)))/2^15;
    end
end


end