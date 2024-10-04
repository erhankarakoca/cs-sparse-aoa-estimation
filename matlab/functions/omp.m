function x_omp = omp(Phi, y, max_iter, tol)
    % OMP Algorithm for sparse signal recovery
    % Inputs:
    % - Phi: Sensing matrix
    % - y: Measured signal
    % - max_iter: Maximum number of iterations
    % - tol: Tolerance for residual norm to stop the algorithm
    % Output:
    % - x_omp: Reconstructed sparse signal
    
    % Initialize variables
    residual = y;  % Initial residual is the measured signal
    Phi_normalized = Phi ./ vecnorm(Phi);  % Normalize columns of Phi
    active_set = [];  % Initialize the active set
    x_omp = zeros(size(Phi, 2), 1);  % Initialize sparse solution

    for iter = 1:max_iter
        % Step 1: Find the index of the column most correlated with residual
        correlations = abs(Phi_normalized' * residual);  % Correlation with residual
        [~, idx] = max(correlations);  % Index of most correlated column
        active_set = [active_set, idx];  % Update active set
        
        % Step 2: Solve least-squares problem on selected columns
        Phi_active = Phi(:, active_set);
        x_ls = pinv(Phi_active) * y;  % Least-squares solution
        
        % Step 3: Update residual
        residual = y - Phi_active * x_ls;
        
        % Step 4: Check stopping condition (if residual norm is below tolerance)
        if norm(residual, 'fro') < tol
            disp("Stopping OMP");
            break;
        end
    end
    
    % Final solution: Assign values to the corresponding active set indices
    x_omp(active_set) = x_ls;
end
