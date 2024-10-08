%% Parameters
%%% C:\Sivers Semiconductors\Rapinoe\API\config\ram
clc;
clear;
freq = 25e9;
AGC_atten = 10; % 1 ile 56 
period = 491.52e3;

%% RFSoC Initialization 
ip_address = "192.168.0.10";
dat_client = tcpclient( ip_address, 8082); % TCP port to handle data
cmd_client = tcpclient( ip_address, 8081); % TCP port to handle commands
d1 = 0.1;
verbose = 0;
% test the connection and stop any possible transmission
send_cmd(5,cmd_client,1,d1,0,'txctl stop');

%% EVK Initialization 
% Reciever EVK bize bir obje olarak lazım olduğu için onu evk fonksiyonu
% ile çağırıyoruz, bu fonksiyon ilk başta reset ve calibration işlemleri de
% yapıyor.
% 517 ile biten EVK bizim alıcı, 516 ile biten EVK verici
evkObject = evk('T582300517',freq); % TxRx = None ==> reciever modunda
% Vericiyi sadece resetleyip kalibre etmemiz gerekiyor, daha sonra müdahale
% etmeyeceğiz.
disp('Rx ok')
device_reset('T582300516'); % hem resetliyor hem de default hüzmeleri
% yüklüyor,  karşıya bakan hüzme 6 numaralıdır.
% default hüzmeler (C:\Users\User\Desktop\Compressive_Sensing\config\ram)
% içinde ram dosyasındadır.
device_calibrate(freq,'T582300516') % birkaç dakika sürebilir
disp('Tx ok')

%% Start Tx
start_tx(cmd_client, dat_client) % sinyal basıyor


%% Configure RX

send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set enable 0'));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set loper %d',period));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set plowdb -26'));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set phighdb -18'));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set dlow 56'));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set dhigh 1'));
% send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set data 32'));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl agc set channel 2'));
send_cmd(5,cmd_client,1,d1,0,sprintf('rxctl agc set data %d',AGC_atten));
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl power 0 0')); % güç ölçmesin

%% Upload Compressive Sensing Weights 

% W = (1 / sqrt(16)) * exp(1j * 2 * pi * rand(16, 50));
load('W_matrix_init.mat');

% array = []; % ya URA objesi, ya da x,y koordinatları
array = [-2 -2 -2 -2 -1 -1 -1 -1 1 1 1 1 2 2 2 2; ...
    -2 -1 1 2 -2 -1 1 2 -2 -1 1 2 -2 -1 1 2];
evkObject = uploadRAMTable(evkObject,array,W); 
% eklenecek: bu fonksiyondan qunatized W alınacak




%% Receiving

send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl beam 0 1000 50')); % 0 samples_per_beam number_of_beams
% send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl bix %d',beam_rx));



period = 1000 * 50; %n_rx_beams*period
dataout = acquire_data(cmd_client, dat_client, bin2dec('1100'), period);

IQv = double(dataout(1,:))/2^15 + 1j * double(dataout(2,:))/2^15; % vertical pol
IQh = double(dataout(3,:))/2^15 + 1j * double(dataout(4,:))/2^15; % vertical pol

