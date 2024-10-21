function [x_hat] = bayesian_omp(A, y, max_iter, noise_var)
    % Bayesian OMP for Complex Signals
    % Inputs:
    % y         : Measurement vector (Mx1, complex-valued)
    % A         : Sensing matrix (MxN, complex-valued)
    % max_iter  : Maximum number of iterations (stopping criteria)
    % noise_var : Estimated noise variance (scalar, real-valued)
    % Outputs:
    % x_hat     : Estimated sparse signal (Nx1, complex-valued)
    % support   : Indices of selected atoms (non-zero positions)

    [M, N] = size(A);  
    residual = y;  % Initialize residual with measurements
    support = [];  % Stores selected atoms
    x_hat = zeros(N, 1);  % Initialize sparse signal

    % Precompute for faster access
    A_conjT = A';  % Conjugate transpose of A

    % Iterative support selection
    for iter = 1:max_iter
        % Step 1: Compute posterior mean for each atom
        proj = A_conjT * residual;  % Correlation with residual
        posterior_var = noise_var ./ sum(abs(A).^2, 1).';  % Posterior variance
        posterior_mean = proj ./ (1 + noise_var ./ posterior_var);  % Posterior mean

        % Step 2: Select atom with maximum posterior mean magnitude
        [~, idx] = max(abs(posterior_mean));
        support = [support; idx];  % Add selected index to support

        % Step 3: Solve least squares over selected support
        A_support = A(:, support);  % Select columns in support
        x_support = A_support \ y;  % Solve for sparse coefficients

        % Step 4: Update estimate and residual
        x_hat(support) = x_support;  % Update sparse solution
        residual = y - A_support * x_support;  % Update residual

        % Check stopping criteria (early termination if residual is small)
        if norm(residual) < 1e-6
            break;
        end
    end
end
