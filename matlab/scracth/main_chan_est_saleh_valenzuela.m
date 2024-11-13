clc; clear all; close all

%%
N1=4; N2=4; N=N1*N2; % the number of antennas
M=50; % the number of measurements
L=1; % the number of paths
d=0.5; % the space of antennas
type=2; % ULA or UPA
K=1;  % the number of samples

%%
fc = 28e9; % Carrier frequency (e.g., 28 GHz)
lambda = 3e8 / fc; % Wavelength
% d = lambda / 2; % Distance between antennas (half-wavelength)

% DFT matrix
if type==1
    UN=exp(1i*2*pi*[-(N-1):2:N-1]'/2*d*[-(N-1):2:N-1]*(1/N)); % (1/sqrt(N))* the DFT matrix
end
if type==2
    UN1=(1/sqrt(N1))*exp(1i*2*pi*[-(N1-1):2:N1-1]'/2*d*[-(N1-1):2:N1-1]*(1/N1)); % (1/sqrt(N1))*
    UN2=(1/sqrt(N2))*exp(1i*2*pi*[-(N2-1):2:N2-1]'/2*d*[-(N2-1):2:N2-1]*(1/N2)); % (1/sqrt(N2))*
    UN=kron(UN1,UN2); % the DFT matrix
end
dft_matrix = dftmtx(N);
H_spatial=zeros(N,K); % the spatial channel 
for k=1:K
    H_spatial(:,k)= generate_channel(N1,N2,L,type);
    H_angular(:,k)= UN.' * H_spatial(:,k);
end
figure; surf(abs(reshape(H_spatial,N1,N2)));
figure; surf(abs(reshape(H_angular,N1,N2)));

%% Steering vector gen
D_az=181;
D_el=91;

azimuth_angles = linspace(-90, 90, D_az);
elevation_angles = linspace(-45, 45, D_el);

steering_vector_ura = @(theta, phi, N1, N2, d) ...
    kron(exp(1j * 2 * pi * d * (0:N1-1).' * sind(theta)), ...
         exp(1j * 2 * pi * d * (0:N2-1).' * sind(phi)));

%% Full steering matrix A
A = [];
for phi = elevation_angles
    for theta = azimuth_angles
        A = [A, steering_vector_ura(theta, phi, N1, N2, d)];
    end
end

%% Compressive sampling of spatial sv channel 
pilot_signal = 1 ; 

W = exp(1j * 2 * pi * rand(N, M))'; % Random pilot matrix
received_signal = W * H_spatial * pilot_signal; % Received signals from pilot measurements
H_spatial_est = pinv(W) * received_signal; % Estimated channel in spatial domain
figure; surf(abs(reshape(H_spatial_est,N1,N2)));
figure; surf(abs(reshape( UN.' * H_spatial_est,N1,N2)));

H_angular_est = pinv(W*A) * received_signal; % Estimated channel in spatial domain
figure; surf(elevation_angles, azimuth_angles, abs(reshape(H_angular_est,D_az,D_el)));

H_angular_space = (A'* H_spatial);
figure; surf(elevation_angles, azimuth_angles, abs(reshape(H_angular_space,D_az,D_el)));




function [h] = generate_channel(N1,N2,L,type)

N=N1*N2;
d=0.5;
h=zeros(N,1);
alpha = (normrnd(0, 1, L, 1) + 1i*normrnd(0, 1, L, 1)) / sqrt(2);

if type==1 
    phi=pi*rand(1,L)-pi/2;
    for l = 1:L
        a = 1/sqrt(N)*exp(1i*2*pi*[-(N-1):2:N-1]'/2*d*sin(phi(l)));  
        h = h + alpha(l)*a;
    end
end

if type==2    
    phi1=pi*rand(1,L)-pi/2;
    disp(phi1)
    disp(rad2deg(phi1))
    phi2=pi*rand(1,L)-pi/2;
    disp(phi2)
    disp(rad2deg(phi2))
    for l = 1:L
        a1 = 1/sqrt(N1)*exp(-1i*2*pi*[-(N1-1):2:N1-1]'/2*d*sin(phi1(l))*sin(phi2(l)));
        a2 = 1/sqrt(N2)*exp(-1i*2*pi*[-(N2-1):2:N2-1]'/2*d*cos(phi2(l)));
        a=kron(a1,a2);
        h = h + alpha(l)*a;
    end
end

h=sqrt(N/L)*h;
end
