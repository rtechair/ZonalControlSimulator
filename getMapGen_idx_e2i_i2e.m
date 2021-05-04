function [mapGen_idx_e2i, mapGen_idx_i2e] = getMapGen_idx_e2i_i2e(basecase_int)
    % Return map doing the conversion of indices between the index of the
    % external basecase and the internal basecase, and vice versa
    %% Input
    % basecase_int: 
    %% Output
    % mapGen_idx_e2i:
    % mapGen_idx_i2e:k
    genOn_idx_ext = basecase_int.order.gen.status.on; % each line indicates what line (=index) is each On generator in the original basecase
    genOn_idx_int = 1:size(genOn_idx_ext,1); % = [1,2,...,numberOfGenOn]
    % construct maps in both directions
    mapGen_idx_e2i = containers.Map(genOn_idx_ext, genOn_idx_int);
    mapGen_idx_i2e = containers.Map(genOn_idx_int, genOn_idx_ext);
end