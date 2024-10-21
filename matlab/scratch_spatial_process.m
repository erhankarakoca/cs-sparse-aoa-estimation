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
K = 50; % Number of measurements (snapshots)
W_matrix_start_index = 0;
W_matrix_end_index = W_matrix_start_index + K ;
L = 1; % Number of different incoming signals   (AoAs)
f = 25e9;

wavelength = physconst('LightSpeed')/f ; 
d = 8.20e-3 / wavelength ;


%% Create a time vector based on the length of your IQ data
fs = 491.52e6 ;
samples_per_symbol = 1000;
t = (0:length(IQv)-1)/fs;

fc = 10e6;
frequency_shift = exp(-1j*2*pi*fc*t);

IQv_shifted = IQv .* frequency_shift;

IQ_filtered = lowpass(IQv_shifted, 10e6 , fs, ImpulseResponse="iir",Steepness=0.80);

%%

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

%% Calibration

W_calibration = zeros(16,1);
offset1 = 200;
offset2 = 0;
all_samples = zeros(16,10000-offset1-offset2);
for i = 1:16
    tone_samples_v = calibration.IQv(offset1 + (i-1)*10000+1:(i)*10000 - offset2);
    all_samples(i,:) = tone_samples_v;
    tone_spectrum = fft(tone_samples_v)/(10000-offset1-offset2);
    W_calibration(i,1) = tone_spectrum(abs(tone_spectrum) == max(abs(tone_spectrum)));
end

W_quantized = W_quantized(:, W_matrix_start_index+1:W_matrix_end_index);
W_calibrated = W_quantized.*W_calibration;
y_noisy_rf_chain = IQ_filtered;
% start_index = 400;
sample_indexes = 147+200 + W_matrix_start_index*samples_per_symbol:samples_per_symbol:W_matrix_end_index*samples_per_symbol;
y_sampled = y_noisy_rf_chain(sample_indexes).';

%% Sensing matrix Phi
Phi = W_calibrated' * A;


% Compute the spatial spectrum for all angles simultaneously
spectrum = abs(A * Phi.') * abs(y_sampled).^2; % Matrix multiplication

% Reshape the spectrum into a 2D grid for visualization
spatial_spectrum = reshape(spectrum, [azimuth_angles, elevation_angles]);

% Normalize the spectrum
spatial_spectrum = spatial_spectrum / max(spatial_spectrum(:));

% Normalize the spectrum for better visualization
spatial_spectrum = spatial_spectrum / max(spatial_spectrum(:));


% Plot the spatial spectrum as a heatmap
figure;
imagesc(elevation_angles, azimuth_angles, spatial_spectrum); % X: Azimuth, Y: Elevation
colormap('viridis'); % Use the viridis colormap
colorbar;
xlabel('Azimuth (degrees)');
ylabel('Elevation (degrees)');
title('Spatial Spectrum of Received Signal');
set(gca, 'YDir', 'normal'); % Flip the Y-axis for correct orientation
