function [mapBus_id2idx] = getMapBus_id2idx(basecase)
    % basecase.bus matrix gives bus_id by providing bus_idx, but it is
    % necessary to access data the other way around, i.e. providing bus_id to
    % obtain bus_idx
    %{
    mapBus_id2idx = containers.Map('KeyType','double','ValueType','double');
    for k = 1:size(basecase.bus,1)
        mapBus_id2idx(basecase.bus(k,1)) = k;
    end
    %}
    id = basecase.bus(:,1);
    idx = 1:size(basecase.bus,1);
    mapBus_id2idx = containers.Map(id,idx);
end