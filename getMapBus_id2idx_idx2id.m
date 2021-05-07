function [mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase)
    % Return 2 matrices: 
    % 1) a sparse matrix serving as a map for buses from id to index in the
    % basecase.bus
    % 2) inversely, the map for buses from index to id is returned as continuous indexing matrix
    %% INPUT
    % basecase: a basecase with a MatPower case struct
    %% OUTPUT
    % mapBus_id2idx: a sparse matrix serving as a map: bus_id -> bus_idx
    % where bus_id and bus_idx are the identity and index of the bus
    % respectively in the basecase.bus
    % mapBus_idx2id: a matrix with continuous indexing serving as a map: bus_idx -> bus_id
    n_bus = size(basecase.bus,1);
    id = basecase.bus(:,1);
    idx = 1:n_bus;
    col = ones(n_bus, 1);
    % construct maps in both directions
    mapBus_id2idx = sparse(id, col, idx);
    mapBus_idx2id = id;
end

