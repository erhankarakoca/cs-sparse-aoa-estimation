function x_cosamp = cosamp(Phi, y, K, max_iter)
    % CoSaMP Algorithm for sparse recovery
    % Inputs:
    % - Phi: Sensing matrix (complex-valued)
    % - y: Measured signal (complex-valued)
    % - K: Sparsity level (number of non-zero elements)
    % - max_iter: Maximum number of iterations
    % Output:
    % - x_cosamp: Reconstructed sparse signal (complex-valued)
    
    % Initialize variables
    residual = y;  % Initial residual is the measurement vector
    x_cosamp = zeros(size(Phi, 2), 1);  % Sparse solution (complex-valued)
    support_set = [];  % Support set of selected atoms

    for iter = 1:max_iter
        % Step 1: Compute correlations
        correlations = abs(Phi' * residual);  % Complex correlations
        
        % Step 2: Identify the indices of the 2K largest correlations
        [~, idx] = sort(correlations, 'descend');
        selected_set = idx(1:2*K);  % Select 2K indices
        
        % Step 3: Merge with the current support set
        support_set = union(support_set, selected_set);
        
        % Step 4: Solve least-squares problem over selected atoms
        Phi_active = Phi(:, support_set);
        x_ls = pinv(Phi_active) * y;  % Least-squares estimate (complex)
        
        % Step 5: Prune to retain the K largest components
        [~, idx_ls] = sort(abs(x_ls), 'descend');
        significant_set = idx_ls(1:K);  % Retain only K largest
        
        % Step 6: Update the support set and sparse solution
        support_set = support_set(significant_set);
        x_cosamp = zeros(size(Phi, 2), 1);  % Reinitialize sparse solution
        x_cosamp(support_set) = x_ls(significant_set);  % Keep significant values
        
        % Step 7: Update residual
        residual = y - Phi(:, support_set) * x_cosamp(support_set);
        
        % Step 8: Stopping criterion
        if norm(residual) < 1e-3
            break;
        end
    end
end