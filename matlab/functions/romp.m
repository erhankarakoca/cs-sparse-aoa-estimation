function x_romp = romp(Phi, y, K, max_iter)
    % ROMP algorithm for sparse recovery
    % Inputs:
    % - Phi: Sensing matrix
    % - y: Measured signal
    % - K: Sparsity level
    % - max_iter: Maximum number of iterations
    % Output:
    % - x_romp: Reconstructed sparse signal
    
    % Initialize variables
    residual = y;
    x_romp = zeros(size(Phi, 2), 1);
    active_set = [];

    for iter = 1:max_iter
        % Step 1: Correlation step
        correlations = abs(Phi' * residual);
        
        % Step 2: Group selection (sort correlations and select top K)
        [~, idx] = sort(correlations, 'descend');
        selected_set = idx(1:K);  % Select top K indices
        
        % Step 3: Update active set
        active_set = union(active_set, selected_set);
        
        % Step 4: Solve least-squares over the active set
        Phi_active = Phi(:, active_set);
        x_ls = pinv(Phi_active) * y;
        
        % Step 5: Threshold and prune
        [~, idx_ls] = sort(abs(x_ls), 'descend');
        x_ls_pruned = x_ls(idx_ls(1:K));
        active_set = active_set(idx_ls(1:K));
        
        % Step 6: Update the residual
        residual = y - Phi(:, active_set) * x_ls_pruned;
        
        % Step 7: Check stopping criterion
        if norm(residual) < 1e-3
            break;
        end
    end
    
    % Step 8: Final solution
    x_romp(active_set) = x_ls_pruned;
end