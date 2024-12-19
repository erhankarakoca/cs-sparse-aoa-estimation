% Global parameters
N_x = 4; 
N_y = 4; 
N = N_x * N_y; 

D_az = 181*4;   
D_el = 181*4; 

% Grids
azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-90, 90, D_el);

% Frequency and wavelength parameters
f = 25e9;
wavelength = physconst('LightSpeed')/f; 
d = 8.20e-3 / wavelength;

% 
fs = 491.52e6 ;
samples_per_symbol = 1000;
% t = (0:length(IQv)-1)/fs;
% estimated_freq = rootmusic(IQv,1,fs);
fif = 10e6;

% OMP global parameters
max_iter = 1;      
tol = 1e-11;         
% frequency_shift = exp(-1j*2*pi*fif*t);

% Precompute the steering matrix
A = zeros(N_x * N_y, D_az * D_el); 
index = 1;
for phi = elevation_angles
    for theta = azimuth_angles
        A(:, index) = kron(exp(1j * 2 * pi * d * (0:N_x-1).' * sind(theta)), ...
                           exp(1j * 2 * pi * d * (0:N_y-1).' * sind(phi)));
        index = index + 1;
    end
end

% Initialize figures for separate updating plots
figure;
subplot(1, 2, 1);
surf_basic = surf(elevation_angles, azimuth_angles, zeros(length(azimuth_angles), length(elevation_angles)));
title('Basic Reconstruction');
shading interp;

subplot(1, 2, 2);
surf_omp = surf(elevation_angles, azimuth_angles, zeros(length(azimuth_angles), length(elevation_angles)));
title('OMP Reconstruction');
shading interp;

while true
    IQv = get_new_IQ_data(); % Placeholder for data collection function

    % Call the processing function
    [basic_reconstruction, x_omp_mat, basic_est_az_idx, basic_est_el_idx, ...
        omp_est_az_idx, omp_est_el_idx] = process_IQ_data(...
        IQv, fs, fif, W_calibrated, A, K, samples_per_symbol, max_iter, tol, D_az, D_el, azimuth_angles, elevation_angles);
    
    % Update Basic Reconstruction plot
    set(surf_basic, 'ZData', abs(basic_reconstruction));
    title(sprintf('Basic Reconstruction\nAzimuth: %.2f°, Elevation: %.2f°', ...
        azimuth_angles(basic_est_az_idx), elevation_angles(basic_est_el_idx)));

    % Update OMP Reconstruction plot
    set(surf_omp, 'ZData', abs(x_omp_mat));
    title(sprintf('OMP Reconstruction\nAzimuth: %.2f°, Elevation: %.2f°', ...
        azimuth_angles(omp_est_az_idx), elevation_angles(omp_est_el_idx)));

    drawnow;
end


% Function for process
function [basic_reconstruction, x_omp_mat, ...
          basic_est_az_idx, basic_est_el_idx, ...
          omp_est_az_idx, omp_est_el_idx] = process_IQ_data(...
    IQv, fs, fif, W_calibrated, A, K, samples_per_symbol, max_iter, tol, D_az, D_el, azimuth_angles, elevation_angles)

    % Frequency shift removal
    t = (0:length(IQv)-1)/fs;
    frequency_shift = exp(-1j * 2 * pi * fif * t);
    IQv_shifted = IQv .* frequency_shift;

    IQv_filtered = lowpass(IQv_shifted, 10e6, fs);

    % FFT for each symbol
    measured_fft_samples = zeros(1, K);
    for k = 1:K
        IQ_time_sample = IQv_filtered((k-1)*samples_per_symbol + 1:k*samples_per_symbol);
        fft_samples = fft(IQ_time_sample, 1024 * 8);
        [~, index] = max(abs(fft_samples));
        measured_fft_samples(k) = fft_samples(index);
    end

    % Sensing matrix
    Phi = W_calibrated' * A;

    % Basic reconstruction
    basic_reconstruction = abs(pinv(Phi) * measured_fft_samples.');

    % Estimate AoA for basic reconstruction
    [~, basic_max_idx] = max(abs(basic_reconstruction));
    [basic_est_az_idx, basic_est_el_idx] = ind2sub([D_az, D_el], basic_max_idx);
    basic_reconstruction = reshape(basic_reconstruction, length(azimuth_angles), length(elevation_angles));

    % OMP reconstruction
    x_omp = omp(Phi, measured_fft_samples.', max_iter, tol);
    x_omp_mat = reshape(x_omp, length(azimuth_angles), length(elevation_angles));

    % Estimate AoA for OMP reconstruction
    [~, omp_max_idx] = max(abs(x_omp));
    [omp_est_az_idx, omp_est_el_idx] = ind2sub([D_az, D_el], omp_max_idx);
end


% function IQv = get_new_IQ_data()
%     fs = 491.52e6; % Sampling frequency
%     fif = 10e6;    % Intermediate frequency
%     duration = 0.00001; % Duration of the signal in seconds
%     t = (0:1/fs:duration-1/fs).'; % Time vector
%     IQv = exp(1j * 2 * pi * fif * t) + 0.1 * (randn(size(t)) + 1j * randn(size(t))); % Simulated IQ signal
% end