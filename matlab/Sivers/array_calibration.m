%% Parameters
clc;
clear;
freq = 25e9;
AGC_atten = 35; % 1 ile 56 
period = 491.52e3;
addpath('..\..\python\Sivers\');
addpath('.\')
pyenv(Version="C:\Users\yaser.yagan\AppData\Local\anaconda3\python.exe");
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

%% Upload weights
array = [-2 -2 -2 -2 -1 -1 -1 -1 1 1 1 1 2 2 2 2; ...
    2 1 -1 -2 2 1 -1 -2 2 1 -1 -2 2 1 -1 -2];
% bu array şu maplamayı ifade eder:
%   | W(1,x)   W(5,x)   W(9,x)   W(13,x) |
%   | W(2,x)   W(6,x)   W(10,x)  W(14,x) |
%   | W(3,x)   W(7,x)   W(11,x)  W(15,x) |
%   | W(4,x)   W(8,x)   W(12,x)  W(16,x) |
W = [eye(16) eye(16)]; % in each configuration turn on a single element
[evkObject, W_quantized] = uploadRAMTable(evkObject,array,W); 

%% Receiving
send_cmd(30,cmd_client,1,d1,verbose,sprintf('rxctl beam 0 8192 32')); % 0 samples_per_beam number_of_beams
period = 8192; %n_rx_beams*period
n_meas = size(W,2);
dataout = acquire_data(cmd_client, dat_client, bin2dec('1100'), period*n_meas);
% for i = 1: n_meas
%     send_cmd(5,cmd_client,1,d1,verbose,sprintf('rxctl bix %d',i-1));
%     dataout(:,(i-1)*period+1:i*period) = acquire_data(cmd_client, dat_client, bin2dec('1100'), period);
% end

IQv = dataout(1,:); % vertical pol
IQh = dataout(2,:); % horizontal pol

%% Calibration
W_calibration = zeros(16,2);
offset1 = 500;
offset2 = 0;
all_samples = zeros(16,period-offset1-offset2);
for i = 1:16
    tone_samples_v = IQv(offset1 + (i-1)*period+1:(i)*period - offset2);
    all_samples(i,:) = tone_samples_v;
    tone_spectrum = fft(tone_samples_v)/(period-offset1-offset2);
    W_calibration(i,1) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
    tone_samples_h = IQh(offset1 + (i-1)*period+1:(i)*period - offset2);
    tone_spectrum = fft(tone_samples_h)/(period-offset1-offset2);
    W_calibration(i,2) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
end

% calib_angles = angle(conj(W_calibration));
% calib_amps = abs(W_calibration);

W_calibration = exp(1j*angle(conj(W_calibration))) ./ abs(W_calibration);
%% PLOT
all_samples = zeros(16,period-offset1-offset2);
for i = 1:16
    tone_samples_v = IQv(offset1 + (i-1)*period+1:(i)*period - offset2);
    all_samples(i,:) = tone_samples_v;
end
figure
for i = 1:16
    plot(real(all_samples(i,:)*W_calibration(i,1)))
    hold on
end


