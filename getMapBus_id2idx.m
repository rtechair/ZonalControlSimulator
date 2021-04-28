function [mapBus_id2idx] = getMapBus_id2idx(basecase)
    % basecase.bus matrix gives bus_id by providing bus_idx, but it is
    % necessary to access data the other way around, i.e. providing bus_id to
    % obtain bus_idx
    %% INPUT
    % basecase: a basecase with a MatPower case struct
    %% OUTPUT
    % mapBus_id2idx: a map with key: bus id, and value: bus index in the
    % basecase.bus
    id = basecase.bus(:,1);
    idx = 1:size(basecase.bus,1); % = [1,2,...,numberOfBuses]
    mapBus_id2idx = containers.Map(id,idx);
end