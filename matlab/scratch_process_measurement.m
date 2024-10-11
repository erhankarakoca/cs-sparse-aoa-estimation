clc;
clear all;
close all;
%% Load
load("W_matrix_init.mat");
load("W_matrix_quantized.mat");
load("meas1.mat");

%% Sivers Configuration Parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 
D_az = 181;                     
D_el = 91; 
K = 50; % Number of measurements (snapshots)
L = 1; % Number of different incoming signals   (AoAs)
f = 27e9;

wavelength = physconst('LightSpeed')/f ; 
d = 8.20e-3 / wavelength ;
% d=0.7;
% Create a time vector based on the length of your IQ data
fs = 491.52e6 ; 
t = (0:length(IQv)-1)/fs;

fc = 10e6;
frequency_shift = exp(-1j*2*pi*fc*t);

IQ = IQv .* frequency_shift;

figure
plot(real(IQ))
hold on
plot(imag(IQ))
%%
scope_1 = spectrumAnalyzer(InputDomain="time", SampleRate=fs, AveragingMethod="exponential",...
    PlotAsTwoSidedSpectrum=true,...
    RBWSource="auto",SpectrumUnits="dBW");
scope_1(IQ')
scope_1.release

IQ_filtered = lowpass(IQ, 8e6 , fs, ImpulseResponse="iir",Steepness=0.80);
scope_2 = spectrumAnalyzer(InputDomain="time", SampleRate=fs, AveragingMethod="exponential",...
    PlotAsTwoSidedSpectrum=true,...
    RBWSource="auto",SpectrumUnits="dBW");
scope_2(IQ_filtered')
scope_2.release

figure
plot(real(IQ_filtered))
hold on
plot(imag(IQ_filtered))
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

%% Random beamforming matrix W
%   | W(4,x)   W(8,x)   W(12,x)   W(16,x) |
%   | W(3,x)   W(7,x)   W(11,x)   W(15,x) |
%   | W(2,x)   W(6,x)   W(10,x)   W(14,x) |
%   | W(1,x)   W(5,x)   W(9,x)    W(13,x) |



% W_remap = zeros(4, size(W, 2));

% Remap according to the given structure
W_remap = W_quantized([4:-1:1,8:-1:5,12:-1:9, 16:-1:13], :);   
% A_remap = A([4:-1:1,8:-1:5,12:-1:9, 16:-1:13], :); 


% Display the remapped matrix
% disp(W_remap);



y_noisy_rf_chain = IQ_filtered;
% start_index = 400;
sample_indexes = 147+400:1000:50000;
y_sampled = y_noisy_rf_chain(sample_indexes).';

%% Sensing matrix Phi
Phi = W_remap' * A;

%% TO DO : Requires Antenna mapping for SIVERS --> mapping(W, A)

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = pinv(Phi) * y_sampled;

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
surf(elevation_angles, azimuth_angles, abs(basic_reconstruction));
title(sprintf('Basic Reconstruction (Azimuth: %.2f°, Elevation: %.2f°)', ...
    azimuth_angles(estimated_az_idx), elevation_angles(estimated_el_idx)));
shading interp
%% Reconstruction with algorithm
max_iter = 3;      
tol = 1e-5;         

x_omp = omp(Phi, y_sampled, max_iter, tol);

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