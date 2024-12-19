% clc;
% clear all;
% close all;

%% Sivers Configuration Parameters / Global parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 

D_az = 181*4;   
D_el = 181*4; 

% Grids
azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-90, 90, D_el);

K = size(W,2); % Number of measurements (snapshots)
% K= 40;
W_matrix_start_index = 0;
W_matrix_end_index = W_matrix_start_index + K ;

L = 1; % Number of different incoming signals   (AoAs)
f = 25e9;
wavelength = physconst('LightSpeed')/f ; 
d = 8.20e-3 / wavelength ;

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


% Create a time vector based on the length of your IQ data
fs = 491.52e6 ;
samples_per_symbol = 1000;
t = (0:length(IQv)-1)/fs;
% estimated_freq = rootmusic(IQv,1,fs);
fif = 10e6;

% OMP global parameters
max_iter = 1;      
tol = 1e-11;         
frequency_shift = exp(-1j*2*pi*fif*t);
%% Process start  -> inputs : IQ_v, frequency_shift , t , IQv, fs, W_quantized, W_calibration,A, max_iter, tol , K , samples_per_symbol , D_az, D_el 

IQv_shifted = IQv .* frequency_shift;
IQv_shifted_removed = IQv_shifted(157:end);
% This can be optional
IQ_filtered = lowpass(IQv_shifted_removed, 10e6 , fs, ImpulseResponse="iir",Steepness=0.80);

%% FFT of the each symbol 

for k = 1:K
    % Step 1: Extract the k-th time-domain sample and apply FFT
    IQ_time_sample = IQv_shifted_removed((k-1)*samples_per_symbol + 1:k*samples_per_symbol); % Adjust indices as needed
    % FFT for the k-th symbol samples
    fft_samples = fft(IQ_time_sample,1024*8); 
    [~, index] = max(abs(fft_samples)); % take max samples of the fft
    measured_fft_samples(k)= fft_samples(index);

end


%%
W_calibrated = W_quantized.*(W_calibration(:,1));
y_noisy_rf_chain = IQv_shifted_removed;
y_sampled = measured_fft_samples;



%% Sensing matrix Phi
Phi = W_calibrated' * A;

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = abs(pinv(Phi) * y_sampled.');

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
%     (basic_reconstruction).^2);
% title(sprintf('Basic Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
%     azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
% shading interp
%% Reconstruction with algorithm


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

% figure;
% surf(elevation_angles, azimuth_angles,abs(x_omp_mat));
% xlim([min(elevation_angles) max(elevation_angles)])
% ylim([min(azimuth_angles) max(azimuth_angles)])
% title(sprintf('OMP Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
%     azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
% shading interp