function [mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase)
    % Return 2 matrices serving as maps bus_id <-> bus_idx for the external basecase: 
    % 1) a sparse matrix serving as a bus map from id to index in the
    % basecase.bus
    % 2) inversely, a continuous indexing matrix serves as a bus map from
    % index to id in the basecase.bus
    %% INPUT
    % basecase: a basecase with a MatPower case struct
    %% OUTPUT
    % mapBus_id2idx: sparse matrix, converts identity -> index of buses in basecase.bus
    % mapBus_idx2id: continuous indexing matrix, convert index -> identity of buses in basecase.bus
    
    n_bus = size(basecase.bus,1);
    bus_id = basecase.bus(:,1);
    bus_idx = 1:n_bus;
    column = ones(n_bus, 1);
    % construct maps in both directions
    mapBus_id2idx = sparse(bus_id, column, bus_idx);
    mapBus_idx2id = bus_id;
end

