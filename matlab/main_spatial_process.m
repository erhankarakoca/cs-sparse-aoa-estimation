% clc;
% clear all;
% close all;

%% Load

%% Sivers Configuration Parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 

D_az = 181*4;   
D_el = 181*4; 

K = size(W,2); % Number of measurements (snapshots)
% K= 40;
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
% estimated_freq = rootmusic(IQv,1,fs);
fc = 10e6;
frequency_shift = exp(-1j*2*pi*fc*t);

IQv_shifted = IQv .* frequency_shift;
IQv_shifted_removed = IQv_shifted(157:end);
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
% 
% %% Plot scopes
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
    fft_samples = fft(IQ_time_sample,1024*8); 
    [~, index] = max(abs(fft_samples)); % take max samples of the fft
    measured_fft_samples(k)= fft_samples(index);

end

%% Grids
azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-90, 90, D_el);

%% Steering vector function for URA
steering_vector_ura = @(theta, phi, N_x, N_y, d) ...
    kron(exp(1j * 2 * pi * d * (0:N_x-1).' * sind(theta)), ...
         exp(1j * 2 * pi * d * (0:N_y-1).' * sind(phi)));

%% Full steering matrix A
A = zeros(N_x * N_y, D_az * D_el); 

index = 1;
for phi = elevation_angles
    for theta = azimuth_angles
        A(:, index) = steering_vector_ura(theta, phi, N_x, N_y, d);
        index = index + 1;
    end
end

%%
% W_quantized = W_quantized(:, W_matrix_start_index+1:W_matrix_end_index);
W_calibrated = W_quantized.*(W_calibration(:,1));
y_noisy_rf_chain = IQv_shifted_removed;
% start_index = 400;
% sample_indexes = 100 + 500 + W_matrix_start_index*samples_per_symbol:samples_per_symbol:W_matrix_end_index*samples_per_symbol;
% y_sampled = y_noisy_rf_chain(sample_indexes);
y_sampled = measured_fft_samples;


%%

% figure
% stem(abs(measured_fft_samples)/max(abs(measured_fft_samples)));
% hold on
% stem(abs(sum(W_calibrated,1)) / max(abs(sum(W_calibrated,1))))
% 
% figure
% stem(angle(measured_fft_samples));



%% Sensing matrix Phi
Phi = W_calibrated' * A;

%% TO DO : Requires Antenna mapping for SIVERS --> mapping(W, A)

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = abs(pinv(Phi) * y_sampled.');

%% Spatial channel extraction 
% spatial_channel = pinv(W.')*y_sampled.';
% 
% figure
% surf(reshape(real(spatial_channel),4,4))
% 
% figure
% surf(reshape(angle(spatial_channel),4,4))
% 
% dft_mtx=dftmtx(16);
% channel_dft = dft_mtx * spatial_channel;
% 
% figure 
% imagesc(abs(reshape(channel_dft,4,4)))

% spatial_spectrum = pinv(W_calibrated.')*y_sampled.';
% H_est_angular_pinv = A' * spatial_spectrum;
% H_est_angular_pinv = reshape(H_est_angular_pinv, length(azimuth_angles), length(elevation_angles));

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

% figure;
% surf(elevation_angles, azimuth_angles, ...
%     abs(H_est_angular_pinv).^2);

figure;
surf(elevation_angles, azimuth_angles, ...
    (basic_reconstruction).^2);
title(sprintf('Basic Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
    azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
shading interp
%% Reconstruction with algorithm
max_iter = 1;      
tol = 1e-5;         

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