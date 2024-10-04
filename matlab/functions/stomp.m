function x_stomp = stomp(Phi, y, K, max_iter)
    % STOMP algorithm for sparse recovery
    % Inputs:
    % - Phi: Sensing matrix
    % - y: Measured signal
    % - K: Sparsity level
    % - max_iter: Maximum number of iterations
    % Output:
    % - x_stomp: Reconstructed sparse signal
    
    % Initialize variables
    x_stomp = zeros(size(Phi, 2), 1);
    residual = y;
    active_set = [];

    for iter = 1:max_iter
        % Step 1: Correlation step
        correlations = abs(Phi' * residual);
        
        % Step 2: Select multiple indices with significant correlation (top K)
        [~, idx] = sort(correlations, 'descend');
        new_set = idx(1:K);  % Select top K indices
        
        % Step 3: Update the active set (union with current)
        active_set = union(active_set, new_set);
        
        % Step 4: Solve least-squares over the active set
        Phi_active = Phi(:, active_set);
        x_ls = pinv(Phi_active) * y;
        
        % Step 5: Update the residual
        residual = y - Phi_active * x_ls;
        
        % Step 6: Stop if residual is small enough
        if norm(residual) < 1e-3
            break;
        end
    end
    
    % Step 7: Update the solution with the non-zero coefficients
    x_stomp(active_set) = x_ls;
end
