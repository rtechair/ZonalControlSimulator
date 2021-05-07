function [mapBus_id_e2i, mapBus_id_i2e] = getMapBus_id_e2i_i2e(basecase_int, mapBus_id2idx, mapBus_idx2id, mapBus_idx_e2i, mapBus_idx_i2e)
% Return 2 matrices serving as maps, for the bus id, exterior <-> interior basecase:
% 1) a sparse matrix serving as a map for bus id, from the external to the internal basecase
% 2) inversely, a continuous indexing matrix serves as a map for bus id, from the internal to the external basecase
%% Input
% basecase_int: the internal basecase
%% Output
% mapBus_id_e2i: exterior -> interior bus_id sparse matrix
% mapBus_id_i2e: interior -> exterior bus_id matrix with continuous indexing

% get the keys and values to create the maps
bus_id = basecase_int.order.ext.bus(:,1);
bus_idx = 1:size(bus_id);
% bus_idx = getValues(mapBus_id2idx, bus_id);  % TODO check function works before deleting              
bus_int_idx = mapBus_idx_e2i(bus_idx); % TODO check function works before deleting  

% create the maps:
mapBus_id_e2i = containers.Map(bus_id,bus_int_idx);
mapBus_id_i2e = containers.Map(bus_int_idx, bus_id);
end
