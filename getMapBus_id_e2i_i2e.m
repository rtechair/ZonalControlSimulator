function [mapBus_id_e2i, mapBus_id_i2e] = getMapBus_id_e2i_i2e(basecase_int, mapBus_id2idx, mapBus_idx2id, mapBus_idx_e2i, mapBus_idx_i2e)
% Return 2 maps: one to obtain interior buses id from their exterior bus
% id, and vice versa, respectively
%% Input
% basecase_int: the internal basecase
%% Output
% mapBus_id_e2i: the Exterior -> Interior bus_id Map
% mapBus_id_i2e: the Interior -> Exterior bus_id map

% get the keys and values to create the maps
bus_id = basecase_int.order.ext.bus(:,1);
bus_idx = 1:size(bus_id);
% bus_idx = getValues(mapBus_id2idx, bus_id);  % TODO check function works before deleting              
bus_int_idx = mapBus_idx_e2i(bus_idx); % TODO check function works before deleting  
bus_int_idx2 = nonzeros(mapBus_idx_e2i);
% create the maps:
mapBus_id_e2i = containers.Map(bus_id,bus_int_idx);
mapBus_id_i2e = containers.Map(bus_int_idx, bus_id);
end
