clc;
clear all;
close all;

%% Parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 
D_az = 181;                     
D_el = 91; 
K = 20; % Number of measurements (snapshots)
L = 1; % Number of different incoming signals   (AoAs)
SNR_dB = 20; 
d = 0.68; 

%% Grids
azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-45, 45, D_el);

%% Steering vector function for URA
% Steering Vector: For each angle pair (azimuth θ and elevation ϕ), 
% a unique steering vector of length 16x1 is generated for the URA.
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

% A = dftmtx(N);

%% Random beamforming matrix W
W = (1 / sqrt(N)) * exp(1j * 2 * pi * rand(N, K));

% Generate Bernoulli phases (0 or π)
% bernoulli_phases = pi * randi([0, 1], N, K);

% Construct W with Bernoulli-distributed phase shifts
% W = (1 / sqrt(N)) * exp(1j * bernoulli_phases);
cond(W);

%%
sigma_theta = 1; % Standard deviation of phase noise in radians

% Generate phase noise for each element
theta_noise = sigma_theta * randn(N, K); % Phase noise with Gaussian distribution

% Apply phase noise to the sensing matrix
W_noisy = W  .* exp(1j * theta_noise);

%% DFT matrix
% F = dftmtx(N);

%% Sensing matrix Phi
Phi = W' * A;

%% Random incoming signals (true AoAs)
true_azimuths = 75 ; % randsample(azimuth_angles, L, false);
true_elevations = 42 ;% randsample(elevation_angles, L, false);

%% Pilot signal
s = randn(1, L) + 1j*(randn(1,L));
% s = 0.7+0.7j;
%% The received signal X
% X = zeros(N, 16); % Initialize the received signal
% for i = 1:K
%     a = steering_vector_ura(true_azimuths(1), true_elevations(1), N_x, N_y, d);
%     X(i,:) = a * s(i).';
% end

%% Compressed received signal using random beamforming
% y_compressed = sum(W' .* (X./s.'), 2);

X = zeros(N, 1); % Initialize the received signal
for i = 1:L
    a = steering_vector_ura(true_azimuths(i), true_elevations(i), N_x, N_y, d);
    % X = X + a * s(i).';
    X = X + a * s(i) ;
end
% Apply AWGN noise after summing contributions from all angles
% X_noisy = awgn(X, SNR_dB, 'measured');

%% Compressed received signal using random beamforming
y_compressed = W_noisy' * X;


%% Noisy received signal
SNR = 10^(SNR_dB / 10); 
noise_power = norm(y_compressed, 'fro')^2 / (SNR * K); 
noise = sqrt(noise_power / 2) * (randn(K, 1) + 1j * randn(K, 1)); 
y_noisy_rf_chain = y_compressed + noise;

%% Displaying true AoAs for reference
disp('--------- True AoAs -----------')
disp('True Azimuth Angles (degrees):');
disp(true_azimuths);
disp('True Elevation Angles (degrees):');
disp(true_elevations);

%% Reconstruct it with the simplest mathematical model
basic_reconstruction = pinv(Phi)*y_noisy_rf_chain;
% basic_reconstruction = lsqr(Phi, y_noisy_rf_chain);
% Find indices of maximum values (estimated AoAs)
[~, max_idx] = max(abs(basic_reconstruction));
[estimated_az_idx, estimated_el_idx] = ind2sub([D_az, D_el], max_idx);

basic_reconstruction = reshape(abs(basic_reconstruction), length(azimuth_angles), length(elevation_angles));


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
max_iter = 10;      
tol = 1e-6;         

x_omp = omp(Phi, y_noisy_rf_chain, max_iter, tol);

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