function [basecase, basecaseInt, mapBus_id2idx, mapBus_idx2id, ...
    mapBus_id_e2i, mapBus_id_i2e, mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getBasecaseAndMap(basecaseName)
% Compute the external and internal basecase and the 6 associate maps. 'id' corresponds to the number of
% the element. 'idx' means index/indices, which is the row where the element is
% placed in the matpower case struct.
% INPUT
% basecaseName: name of the basecase file to load
% OUTPUT
% basecase: matpower case struct of the basecase to work on
% basecaseInt: internal basecase, which is used by matpower to do computations
% mapBus_id2idx: sparse column vector, converts identity -> index of buses in basecase.bus
% mapBus_idx2id: continuous indexing column vector, convert index -> identity of buses in basecase.bus
% mapBus_id_e2i: sparse column vector, convert external bus id -> internal bus id 
% mapBus_id_i2e: continuous indexing column vector, convert internal bus id -> external bus id 
% mapGenOn_idx_e2i: sparse column vector, converts exterior -> interior online generator index
% mapGenOn_idx_i2e: continuous indexing column vector, converts exterior -> interior online generator index

% load the external/human-oriented basecase structure
basecase = loadcase(basecaseName);
% convert to the internal basecase structure for Matpower
basecaseInt = ext2int(basecase);

% check if a bus or a branch has been deleted, currently the code does not
% handle the case if some are deleted/off
[isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecaseInt);
if isBusDeleted
    disp('in function getBasecasesAndMaps: a bus has been deleted, nothing has been made to handle this situation, the code should not work')
end
if isBranchDeleted
    disp('in function getBasecasesAndMaps: a branch has been deleted, nothing has been made to handle this situation, the code should not work')
end

% bus map
[mapBus_id2idx, mapBus_idx2id] = mapBus_id2idx_idx2id(basecase);
mapBus_id_e2i = basecaseInt.order.bus.e2i; % sparse column vector
mapBus_id_i2e = basecaseInt.order.bus.i2e; % full column vector

% online gen map, this include batteries
[mapGenOn_idx_e2i, mapGenOn_idx_i2e] = mapGenOn_idx_e2i_i2e(basecaseInt);
end