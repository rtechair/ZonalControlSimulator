function [mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase)
    % Return map giving the index in the basecase.bus matrix of a given bus
    % id, and vice versa
    %% INPUT
    % basecase: a basecase with a MatPower case struct
    %% OUTPUT
    % mapBus_id2idx: a map with key: bus id, and value: bus index in the
    % basecase.bus
    % mapBus_idx2id: a map with key = bus index, and value = bus id
    id = basecase.bus(:,1);
    idx = 1:size(basecase.bus,1); % = [1,2,...,numberOfBuses]
    % construct maps in both directions
    mapBus_id2idx = containers.Map(id,idx);
    mapBus_idx2id = containers.Map(idx,id);
end

