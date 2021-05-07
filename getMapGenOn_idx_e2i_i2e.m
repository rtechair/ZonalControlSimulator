function [mapOnGen_idx_e2i, mapOnGen_idx_i2e] = getMapGenOn_idx_e2i_i2e(basecase_int)
    % Return 2 matrices serving as maps for the Online generators indices:
    % external <-> internal basecases:
    % 1) a sparse matrix serving as an On gen idx map from external to
    % internal basecase
    % 2) inversely, a continuous indexing matrix serves as an On gen idx
    % from internal to external basecase
    %% INPUT
    % basecase_int: internal basecase
    %% OUTPUT
    % mapGen_idx_e2i: sparse matrix, converts exterior -> interior online generator index
    % mapGen_idx_i2e: continuous indexing matrix, converts exterior -> interior online generator index
    
    genOn_idx_ext = basecase_int.order.gen.status.on; % each line indicates what line (=index) is each Online generator in the original basecase
    n_genOn = size(genOn_idx_ext,1);
    column = ones(n_genOn,1);
    % construct maps in both directions
    mapOnGen_idx_e2i = sparse(genOn_idx_ext, column, 1:n_genOn);
    mapOnGen_idx_i2e = genOn_idx_ext;
end