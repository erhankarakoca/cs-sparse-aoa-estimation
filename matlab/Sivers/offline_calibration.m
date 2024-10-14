load("calibration_meas.mat");
figure 
plot(real(IQv))
hold on
for i = 1:10000:160000
    xline(i)
end
figure
for i = 1:16
    plot(real(IQv((i-1)*10000+1:i*10000)))
    hold on
end
W_calibration = zeros(16,2);
offset1 = 200;
offset2 = 0;
all_samples = zeros(16,10000-offset1-offset2);
for i = 1:16
    tone_samples_v = IQv(offset1 + (i-1)*10000+1:(i)*10000 - offset2);
    all_samples(i,:) = tone_samples_v;
    tone_spectrum = fft(tone_samples_v)/(10000-offset1-offset2);
    W_calibration(i,1) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
    tone_samples_h = IQh(offset1 + (i-1)*10000:(i)*10000 - offset2);
    tone_spectrum = fft(tone_samples_h)/(10000-offset1-offset2);
    W_calibration(i,2) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
end

% calib_angles = angle(conj(W_calibration));
% calib_amps = abs(W_calibration);

W_calibration = exp(1j*angle(conj(W_calibration))) ./ abs(W_calibration);
% W_calibration = W_calibration ./ abs(W_calibration);
% W_calibration(:,1) = (W_calibration(:,1)) .*  abs(W_calibration(:,1));
% W_calibration(:,2) = (W_calibration(:,2)) .*  abs(W_calibration(:,2));
figure
for i = 1:16
    plot(real(all_samples(i,:)*W_calibration(i,1)))
    hold on
end
%% 
load("calibration_meas2.mat");

all_samples = zeros(16,10000-offset1-offset2);
for i = 1:16
    tone_samples_v = IQv(offset1 + (i-1)*10000+1:(i)*10000 - offset2);
    all_samples(i,:) = tone_samples_v;
end
figure
for i = 1:16
    plot(real(all_samples(i,:)*W_calibration(i,1)))
    hold on
end