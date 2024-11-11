clear all;
close all;
clc;

% System parameters
k = 16; % Rows in URA
n = 16; % Columns in URA
N = k*n; % Total number of antennas in URA (e.g., 4x4 array, N = 16)

M = 50; % Number of pilot signals, less than N for compressed sensing
L = 1; % Number of paths (multipath components)
fc = 28e9; % Carrier frequency (e.g., 28 GHz)
lambda = 3e8 / fc; % Wavelength
d = lambda / 2; % Distance between antennas (half-wavelength)

% Azimuth and elevation angles span for angular domain analysis
azimuth_range = -90:1:90; 
elevation_range = -45:1:45; 
[AZ, EL] = meshgrid(azimuth_range, elevation_range);

% Define angles for each path (e.g., [azimuth; elevation] for each path)
angles = [0, -15, 10; 10, 25, 5]; % Example angles for the paths
alpha = (randn(1, L) + 1i * randn(1, L)) / sqrt(2); % Random complex gains

% Initialize the channel matrix H in spatial domain
H = zeros(k, n);
for l = 1:L
    az = angles(1, l);
    el = angles(2, l);
    a = steering_vector_ura(k, n, az, el, d, lambda);
    H = H + alpha(l) * reshape(a, k, n); % Sum contributions from each path
end

% Generate random sensing matrix W (M x N) for compressed sensing
W = exp(1j * 2 * pi * rand(M, N));

% Flatten H to a vector and simulate the measurement process
y = W * H(:); % Compressed measurements of the channel

% Create steering matrix A for angular domain
A = zeros(N, length(azimuth_range) * length(elevation_range));
for az_idx = 1:length(azimuth_range)
    for el_idx = 1:length(elevation_range)
        az = azimuth_range(az_idx);
        el = elevation_range(el_idx);
        a = steering_vector_ura(k, n, az, el, d, lambda);
        A(:, (az_idx - 1) * length(elevation_range) + el_idx) = a;
    end
end

% OMP-based sparse recovery for the angular channel estimation
H_est_angular = omp(W * A, y, L); % Assume L is the number of non-zero elements expected
H_est_angular = reshape(H_est_angular, length(elevation_range), length(azimuth_range));

% Reconstruct the estimated spatial channel matrix
H_est = A * H_est_angular(:); % Map back to spatial domain
H_est = reshape(H_est, k, n);

H_est_angular_pinv = pinv(W) * y;
H_est_angular_pinv = A' * H_est_angular_pinv;
H_est_angular_pinv = reshape(H_est_angular_pinv,  length(elevation_range), length(azimuth_range));
% Plot true spatial domain channel matrix
figure; imagesc(abs(H));
title('True Channel Matrix (Spatial Domain)');
xlabel('Antenna Element (x)'); ylabel('Antenna Element (y)');
colorbar;

% Plot estimated spatial domain channel matrix
figure; imagesc(abs(H_est));
title('Estimated Channel Matrix (Spatial Domain)');
xlabel('Antenna Element (x)'); ylabel('Antenna Element (y)');
colorbar;

% Plot true angular domain channel matrix
H_angular = A' * H(:);
H_angular = reshape(H_angular, length(elevation_range), length(azimuth_range));
figure; imagesc(azimuth_range, elevation_range, abs(H_angular));
title('True Channel Matrix (Angular Domain)');
xlabel('Azimuth Angle (°)'); ylabel('Elevation Angle (°)');
colorbar;

% Plot estimated angular domain channel matrix
figure; imagesc(azimuth_range, elevation_range, abs(H_est_angular));
title('Estimated Channel Matrix (Angular Domain)');
xlabel('Azimuth Angle (°)'); ylabel('Elevation Angle (°)');
colorbar;

% Plot true spatial domain channel matrix
figure; imagesc(abs(H_est_angular_pinv));
title('pinv');
xlabel('Antenna Element (x)'); ylabel('Antenna Element (y)');
colorbar;


function a = steering_vector_ura(k, n, az, el, d, lambda)
    % URA steering vector
    [m, p] = meshgrid(0:k-1, 0:n-1);
    a = exp(1j * 2 * pi * d / lambda * (m(:) * sin(deg2rad(el)) * cos(deg2rad(az)) ...
                                        + p(:) * sin(deg2rad(el)) * sin(deg2rad(az))));
end

function x_hat = omp(D, y, sparsity)
    % Orthogonal Matching Pursuit (OMP) for sparse recovery
    % D: Dictionary matrix (W * A)
    % y: Measurement vector
    % sparsity: number of non-zero elements expected
    r = y; % Initialize residual
    x_hat = zeros(size(D, 2), 1); % Solution vector
    support = []; % Support set

    for i = 1:sparsity
        % Find the index that best matches the residual
        [~, idx] = max(abs(D' * r));
        support = [support, idx]; % Add index to the support set

        % Solve least squares problem over current support
        x_temp = zeros(size(D, 2), 1);
        x_temp(support) = D(:, support) \ y;

        % Update residual
        r = y - D * x_temp;
    end
    x_hat = x_temp; % Final estimated sparse vector
end

