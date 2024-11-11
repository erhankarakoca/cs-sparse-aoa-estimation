clear all;
close all;
clc;
% Define system parameters

k = 16; % Rows in URA
n = 16; % Columns in URA
N = k*n; % Total number of antennas in URA (e.g., 4x4 array, N = 16)
fc = 28e9; % Carrier frequency (e.g., 28 GHz)
lambda = 3e8 / fc; % Wavelength
d = lambda / 2; % Distance between antennas (half-wavelength)
azimuth_range = -90:1:90; % Azimuth angles to span (-90° to 90°)
elevation_range = -45:1:45; % Elevation angles (-45° to 45°)
[AZ, EL] = meshgrid(azimuth_range, elevation_range);

L = 1; % Number of paths
angles = [0, -15, 10; 0, 25, 5]; % [Azimuth; Elevation] angles for each path
alpha = (randn(1, L) + 1i * randn(1, L)) / sqrt(2); % Random complex path gains

% Initialize the channel matrix H
H = zeros(k, n);

% Loop over each path to build the channel matrix
for l = 1:L
    az = angles(1, l);
    el = angles(2, l);
    a = steering_vector_ura(k, n, az, el, d, lambda); % Steering vector for (az, el)
    H = H + alpha(l) * reshape(a, k, n); % Add contribution of each path
end

% Create steering matrix A spanning all azimuth-elevation pairs
A = zeros(N, length(azimuth_range) * length(elevation_range));
for az_idx = 1:length(azimuth_range)
    for el_idx = 1:length(elevation_range)
        az = azimuth_range(az_idx);
        el = elevation_range(el_idx);
        a = steering_vector_ura(k, n, az, el, d, lambda);
        A(:, (az_idx - 1) * length(elevation_range) + el_idx) = a;
    end
end

% Transform H to angular domain (angular channel equivalent)
H_angular = A' * H(:);
H_angular = reshape(H_angular, length(elevation_range), length(azimuth_range));


% Simulate pilot signals
num_pilots = N;
W = exp(1j * 2 * pi * rand(N, num_pilots)); % Random pilot matrix
received_signal = W' * H(:); % Received signals from pilot measurements
H_est = W' * pinv(W') * received_signal; % Estimated channel in spatial domain
H_est = reshape(H_est, k, n);

H_est_angular = A' * H_est(:);
H_est_angular = reshape(H_est_angular, length(elevation_range), length(azimuth_range));

% Plot original spatial channel matrix
figure; imagesc(abs(H));
title('Original Channel Matrix (Spatial Domain)');
xlabel('Antenna Element (x)'); ylabel('Antenna Element (y)');
colorbar;

% Plot original angular domain equivalent
figure; imagesc(azimuth_range, elevation_range, abs(H_angular));
title('Original Channel in Angular Domain');
xlabel('Azimuth Angle (°)'); ylabel('Elevation Angle (°)');
colorbar;

% Plot estimated spatial channel matrix
figure; imagesc(abs(H_est));
title('Estimated Channel Matrix (Spatial Domain)');
xlabel('Antenna Element (x)'); ylabel('Antenna Element (y)');
colorbar;

% Plot estimated angular domain channel matrix
figure; imagesc(azimuth_range, elevation_range, abs(H_est_angular));
title('Estimated Channel in Angular Domain');
xlabel('Azimuth Angle (°)'); ylabel('Elevation Angle (°)');
colorbar;


function a = steering_vector_ura(k, n, az, el, d, lambda)
    % Compute steering vector for URA given azimuth and elevation angles
    [m, p] = meshgrid(0:k-1, 0:n-1);
    a = exp(1j * 2 * pi * d / lambda * (m(:) * sin(deg2rad(el)) * cos(deg2rad(az)) ...
                                        + p(:) * sin(deg2rad(el)) * sin(deg2rad(az))));
end
