clc;
clear all;
close all;
%% Load
% load("W_matrix_init.mat");
% load("W_matrix_quantized.mat");

% Don't remap for new data
load("meas_14_10_1.mat");

%Calibration matrix that is going to be dot product with W
calibration = load("calibration_meas.mat", "IQv");

%% Sivers Configuration Parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 

D_az = 181;  
D_el = 91; 

K = 40; % Number of measurements (snapshots)
W_matrix_start_index = 0;
W_matrix_end_index = W_matrix_start_index + K ;

L = 1; % Number of different incoming signals   (AoAs)

f = 25e9;

wavelength = physconst('LightSpeed')/f ; 
d = 8.20e-3 / wavelength ;

% Create a time vector based on the length of your IQ data
fs = 491.52e6 ;
samples_per_symbol = 1000;
t = (0:length(IQv)-1)/fs;

fc = 10e6;
frequency_shift = exp(-1j*2*pi*fc*t);

IQv_shifted = IQv .* frequency_shift;
IQv_shifted_removed = IQv_shifted(154:92154);
IQ_filtered = lowpass(IQv_shifted_removed, 10e6 , fs, ImpulseResponse="iir",Steepness=0.80);

%% Figuring

% figure
% % Plot real part of IQv in the first subplot
% subplot(3, 1, 1);
% plot(real(IQv));
% hold on;
% plot(imag(IQv));
% title('Real and Imaginary parts of IQv');
% 
% % Plot real part of IQv_shifted in the second subplot
% subplot(3, 1, 2);
% plot(real(IQv_shifted));
% hold on;
% plot(imag(IQv_shifted));
% title('Real and Imaginary parts of IQv\_shifted');
% 
% subplot(3, 1, 3);
% plot(real(IQ_filtered))
% hold on
% plot(imag(IQ_filtered))

%% Plot scopes
% scope_1 = spectrumAnalyzer(InputDomain="time", SampleRate=fs, AveragingMethod="exponential",...
%     PlotAsTwoSidedSpectrum=true,...
%     RBWSource="auto",SpectrumUnits="dBW");
% scope_1(IQv')
% scope_1.release
% 
% scope_2 = spectrumAnalyzer(InputDomain="time", SampleRate=fs, AveragingMethod="exponential",...
%     PlotAsTwoSidedSpectrum=true,...
%     RBWSource="auto",SpectrumUnits="dBW");
% scope_2(IQv_shifted')
% scope_2.release
% 
% 
% 
% scope_3 = spectrumAnalyzer(InputDomain="time", SampleRate=fs, AveragingMethod="exponential",...
%     PlotAsTwoSidedSpectrum=true,...
%     RBWSource="auto",SpectrumUnits="dBW");
% scope_3(IQ_filtered')
% scope_3.release
%% FFT of the each symbol 


for k = 1:K
    % Step 1: Extract the k-th time-domain sample and apply FFT
    IQ_time_sample = IQv_shifted_removed((k-1)*1000 + 1:k*1000); % Adjust indices as needed
     % FFT for the k-th sample
    measured_fft_samples(k)= max(fft(IQ_time_sample,1024)); % take max samples of the fft
end

%% Grids
azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-45, 45, D_el);

%% Steering vector function for URA
steering_vector_ura = @(theta, phi, N_x, N_y, d) ...
    kron(exp(1j * 2 * pi * d * (0:N_x-1).' * sind(theta)), ...
         exp(1j * 2 * pi * d * (0:N_y-1).' * sind(phi)));

%% Full steering matrix A
A = [];
for phi = elevation_angles
    for theta = azimuth_angles
        A = [A, steering_vector_ura(theta, phi, N_x, N_y, d)];
    end
end


%% Calibration matrix initilization 
% figure 
% plot(real(calibration.IQv))
% hold on
% for i = 1:10000:160000
%     xline(i)
% end
% figure
% for i = 1:16
%     plot(real(calibration.IQv((i-1)*10000+1:i*10000)))
%     hold on
% end
W_calibration = zeros(16,1);
offset1 = 200;
offset2 = 0;
all_samples = zeros(16,10000-offset1-offset2);
for i = 1:16
    tone_samples_v = calibration.IQv(offset1 + (i-1)*10000+1:(i)*10000 - offset2);
    all_samples(i,:) = tone_samples_v;
    tone_spectrum = fft(tone_samples_v)/(10000-offset1-offset2);
    % peak_index = find(abs(tone_spectrum) == max(abs(tone_spectrum)));
    % W_calibration(i,1) = angle(tone_spectrum(peak_index));  % Store phase instead of magnitude
    W_calibration(i,1) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
   
    % tone_samples_h = IQh(offset1 + (i-1)*10000:(i)*10000 - offset2);
    % tone_spectrum = fft(tone_samples_h)/(10000-offset1-offset2);
    % W_calibration(i,2) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
end

%% Random beamforming matrix W
%   | W(4,x)   W(8,x)   W(12,x)   W(16,x) |
%   | W(3,x)   W(7,x)   W(11,x)   W(15,x) |
%   | W(2,x)   W(6,x)   W(10,x)   W(14,x) |
%   | W(1,x)   W(5,x)   W(9,x)    W(13,x) |
% W_remap = zeros(4, size(W, 2));

% Remap according to the given structure
% W_remap = W_quantized([4:-1:1,8:-1:5,12:-1:9, 16:-1:13], :);   
% W_remap = W_quantized([4:-1:1,8:-1:5,12:-1:9, 16:-1:13], :);   
% A_remap = A([4:-1:1,8:-1:5,12:-1:9, 16:-1:13], :); 


% Display the remapped matrix
% disp(W_remap);

%%
% W_calibration = exp(1j*angle(conj(W_calibration))) ./ abs(W_calibration);
% W_calibration = W_calibration ./ abs(W_calibration);
% % W_calibration(:,1) = (W_calibration(:,1)) .*  abs(W_calibration(:,1));
% % W_calibration(:,2) = (W_calibration(:,2)) .*  abs(W_calibration(:,2));
% figure
% for i = 1:16
%     plot(real(all_samples(i,:)*W_calibration(i,1)))
%     hold on
% end
%% 

%%
W_quantized = W_quantized(:, W_matrix_start_index+1:W_matrix_end_index);
W_calibrated = W_quantized.*W_calibration;
y_noisy_rf_chain = IQv_shifted_removed;
start_index = 400;
sample_indexes = 100 + 500 + W_matrix_start_index*samples_per_symbol:samples_per_symbol:W_matrix_end_index*samples_per_symbol;
% y_sampled = y_noisy_rf_chain(sample_indexes);
y_sampled = measured_fft_samples;

%% Sensing matrix Phi
Phi = W_calibrated' * A;

%% TO DO : Requires Antenna mapping for SIVERS --> mapping(W, A)

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = abs(pinv(Phi) * y_sampled.');
% spatial_spectrum = abs(Phi * (A' .* y_sampled))^2; % With sensing matrix

% Find indices of maximum values (estimated AoAs)
[~, max_idx] = max(abs(basic_reconstruction));
[estimated_az_idx, estimated_el_idx] = ind2sub([D_az, D_el], max_idx);

basic_reconstruction = reshape(basic_reconstruction, length(azimuth_angles), length(elevation_angles));


% Display the corresponding angles
disp('--------- Basic construction -----------')
disp('Estimated Azimuth Angle:');
disp(azimuth_angles(estimated_az_idx));
disp('Estimated Elevation Angle:');
disp(elevation_angles(estimated_el_idx));

figure;
surf(elevation_angles, azimuth_angles, ...
    (basic_reconstruction).^2);
title(sprintf('Basic Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
    azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
shading interp
%% Reconstruction with algorithm
max_iter = 5;      
tol = 1e-6;         

x_omp = omp(Phi, y_sampled.', max_iter, tol);

% Find indices of maximum values (estimated AoAs)
[~, max_idx] = max(abs(x_omp));
[estimated_az_idx, estimated_el_idx] = ind2sub([D_az, D_el], max_idx);

x_omp_mat = reshape(x_omp, length(azimuth_angles), length(elevation_angles));


% Display the corresponding angles
disp('--------- OMP construction -----------')
disp('Estimated Azimuth Angle:');
disp(azimuth_angles(estimated_az_idx));
disp('Estimated Elevation Angle:');
disp(elevation_angles(estimated_el_idx));

figure;
surf(elevation_angles, azimuth_angles,abs(x_omp_mat));
xlim([min(elevation_angles) max(elevation_angles)])
ylim([min(azimuth_angles) max(azimuth_angles)])
title(sprintf('OMP Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
    azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
shading interp