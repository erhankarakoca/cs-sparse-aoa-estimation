import numpy as np
from scipy.linalg import lstsq
import matplotlib.pyplot as plt

# Parameters
N_x = 4  # Number of elements in x-dimension
N_y = 4  # Number of elements in y-dimension
N = N_x * N_y  # Total number of elements in URA
D_az = 181  # Azimuth angle range
D_el = 91  # Elevation angle range
K = 10  # Number of measurements (snapshots)
L = 1  # Number of incoming signals
SNR_dB = 20  # Signal-to-noise ratio in dB
d = 0.5  # Element spacing in wavelengths

# Grids
azimuth_angles = np.linspace(-90, 90, D_az)
elevation_angles = np.linspace(-45, 45, D_el)

# Steering vector function for URA
def steering_vector_ura(theta, phi, N_x, N_y, d):
    return np.kron(
        np.exp(1j * 2 * np.pi * d * np.arange(N_x).reshape(-1, 1) * np.sin(np.radians(theta))),
        np.exp(1j * 2 * np.pi * d * np.arange(N_y).reshape(-1, 1) * np.sin(np.radians(phi)))
    )

# Full steering matrix A
A = np.empty((N, 0), dtype=complex)
for phi in elevation_angles:
    for theta in azimuth_angles:
        A = np.hstack((A, steering_vector_ura(theta, phi, N_x, N_y, d)))

# Random beamforming matrix W
W = (1 / np.sqrt(N)) * np.exp(1j * 2 * np.pi * np.random.rand(N, K))

# Sensing matrix Phi
Phi = W.conj().T @ A

# Random incoming signals (true AoAs)
true_azimuths = np.random.choice(azimuth_angles, L, replace=False)
true_elevations = np.random.choice(elevation_angles, L, replace=False)

# Pilot signal
s = np.ones(L)

# The received signal X
X = np.zeros((N, 1), dtype=complex)  # Initialize the received signal
for i in range(L):
    a = steering_vector_ura(true_azimuths[i], true_elevations[i], N_x, N_y, d)
    X += a * s[i]

# Compressed received signal using random beamforming
y_compressed = W.conj().T @ X

# Noisy received signal
SNR = 10 ** (SNR_dB / 10)
noise_power = np.linalg.norm(y_compressed.reshape(-1,1), 'fro') ** 2 / (SNR * K)
noise = np.sqrt(noise_power / 2) * (np.random.randn(K, 1) + 1j * np.random.randn(K, 1))
y_noisy_rf_chain = y_compressed + noise

# Displaying true AoAs for reference
print("True Azimuth Angles (degrees):", true_azimuths)
print("True Elevation Angles (degrees):", true_elevations)

# Reconstruct it with the simplest mathematical model (using pinv)
basic_reconstruction = np.linalg.pinv(Phi) @ y_noisy_rf_chain
# Find the indices of the maximum values (estimated AoAs)
max_idx = np.argmax(np.abs(basic_reconstruction))
estimated_az_idx, estimated_el_idx = np.unravel_index(max_idx, [D_az, D_el])

basic_reconstruction = np.abs(basic_reconstruction.reshape(len(elevation_angles), len(azimuth_angles)))

# Corresponding angles
estimated_azimuth = azimuth_angles[estimated_az_idx]
estimated_elevation = elevation_angles[estimated_el_idx]

# Plot the basic reconstruction using pinv
fig = plt.figure(figsize=(10, 7))
ax = fig.add_subplot(projection='3d')
azimuth_mesh, elevation_mesh = np.meshgrid(azimuth_angles, elevation_angles)

ax.plot_surface(azimuth_mesh, elevation_mesh, basic_reconstruction, cmap='viridis', edgecolor='none')
ax.set_xlabel('Elevation Angle (degrees)')
ax.set_ylabel('Azimuth Angle (degrees)')
ax.set_zlabel('Magnitude')
ax.set_title(f'Basic Reconstruction (Azimuth: {estimated_azimuth:.2f}°, Elevation: {estimated_elevation:.2f}°)')
plt.show()

# Reconstruction with OMP algorithm
def omp(Phi, y, max_iter, tol):
    residual = y
    idx_set = []
    x_hat = np.zeros(Phi.shape[1], dtype=complex).reshape(-1,1)

    for _ in range(max_iter):
        # Correlation step
        correlations = np.abs(Phi.conj().T.dot(residual))
        idx = np.argmax(correlations)
        idx_set.append(idx)

        # Solve least squares problem
        Phi_selected = Phi[:, idx_set]
        x_ls, _, _, _ = lstsq(Phi_selected, y)

        # Update residual
        residual = y - Phi_selected.dot(x_ls)

        # Check for convergence
        if np.linalg.norm(residual) < tol:
            break

    # Construct sparse signal
    x_hat[idx_set] = x_ls
    return x_hat


max_iter = 10
tol = 1e-5

x_omp = omp(Phi, y_noisy_rf_chain, max_iter, tol)
# Find the indices of the maximum values (estimated AoAs)
max_idx = np.argmax(np.abs(x_omp))
estimated_az_idx, estimated_el_idx = np.unravel_index(max_idx, [D_az, D_el])

x_omp_mat = x_omp.reshape(len(elevation_angles), len(azimuth_angles))

fig = plt.figure(figsize=(10, 7))
ax = fig.add_subplot(projection='3d')
# Plot reconstruction using OMP
ax.plot_surface(azimuth_mesh, elevation_mesh,  np.abs(x_omp_mat), cmap=plt.cm.YlGnBu_r)
ax.set_xlabel('Elevation Angle (degrees)')
ax.set_ylabel('Azimuth Angle (degrees)')
ax.set_zlabel('Magnitude')
ax.set_title(f'Algorithm Reconstruction (Azimuth: {estimated_azimuth:.2f}°, Elevation: {estimated_elevation:.2f}°)')
plt.show()