clc;
clear all;
close all;

%% Parameters
N_x = 4; % Number of elements in x-dimension
N_y = 4; % Number of elements in y-dimension
N = N_x * N_y; % Total number of elements in URA
D_az = 180; % Azimuth angle range
D_el = 90; % Elevation angle range
K = 10; % Number of measurements (snapshots)
L = 1; % Number of incoming signals
SNR_dB = 20; % Signal-to-noise ratio in dB
d = 0.5; % Element spacing in wavelengths

%% Grids
azimuth_angles = linspace(-90, 90, D_az / 2);
elevation_angles = linspace(-45, 45, D_el / 2);

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
W = (1 / sqrt(N)) * exp(1j * 2 * pi * rand(N, K));

%% DFT matrix (commented out, remove if needed)
% F = dftmtx(N);

%% Sensing matrix Phi
Phi = W' * A;

%% Random incoming signals (true AoAs)
true_azimuths = randsample(azimuth_angles, L, false);
true_elevations = randsample(elevation_angles, L, false);

%% Pilot signal
s = ones(1, L);

%% The received signal X
X = zeros(N, 1); % Initialize the received signal
for i = 1:L
    a = steering_vector_ura(true_azimuths(i), true_elevations(i), N_x, N_y, d);
    X = X + a * s(i).';
end

%% Compressed received signal using random beamforming
y_compressed = W' * X;

%% Noisy received signal
SNR = 10^(SNR_dB / 10); 
noise_power = norm(y_compressed, 'fro')^2 / (SNR * K); 
noise = sqrt(noise_power / 2) * (randn(K, 1) + 1j * randn(K, 1)); 
y_noisy_rf_chain = y_compressed + noise;

%% Displaying true AoAs for reference
disp('True Azimuth Angles (degrees):');
disp(true_azimuths);
disp('True Elevation Angles (degrees):');
disp(true_elevations);

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = pinv(Phi) * y_noisy_rf_chain;
basic_reconstruction = reshape(basic_reconstruction, length(azimuth_angles), length(elevation_angles));

figure;
surf(abs(basic_reconstruction));
title('Basic reconstruction using pinv');
shading interp
%% Reconstruction with algorithm
max_iter = 10;        % Maximum number of iterations
tol = 1e-5;           % Tolerance for residual norm

% Call the function
x_omp = omp(Phi, y_noisy_rf_chain, max_iter, tol);

x_omp_mat = reshape(x_omp, length(azimuth_angles), length(elevation_angles));
figure;
surf(abs(x_omp_mat));
title('Reconstruction using OMP');
shading interp