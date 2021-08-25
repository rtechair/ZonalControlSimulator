function object = buildMathematicalModel(basecaseFilename, zoneName)
% Get the MathematicalModel of a zone.

% This function:
%   - loads settings of a zone
%   - sets up an electrical grid
%   - sets up the topology of a zone
%   - set up the associate mathematical model
% As a consequence, reading the source code could help understanding how to
% create and manipulate objects which are used with the simulator.
    grid = ElectricalGrid(basecaseFilename);
    zoneFilename = ['zone' zoneName '.json'];
    zoneSetting = decodeJsonFile(zoneFilename);
    
    busId = zoneSetting.busId;
    zoneTopology = ZoneTopology(zoneName, busId, grid);
    branchIdx = zoneTopology.getBranchIdx();
    genOnIdx = zoneTopology.getGenOnIdx();
    battOnIdx = zoneTopology.getBattOnIdx();
    
    % internal elements
    mapBus_id_e2i = grid.getMapBus_id_e2i();
    mapGenOn_idx_e2i = grid.getMapGenOn_idx_e2i();
    
    internalMatpowercase = grid.getInternalMatpowercase();
    internalBusId = mapBus_id_e2i(busId);
    
    % because no branch is deleted during the internal conversion, the
    % branch indices are the same for the external and the internal matpowercase
    internalBranchIdx = branchIdx;
    internalGenOnIdx = mapGenOn_idx_e2i(genOnIdx);
    internalBattOnIdx = mapGenOn_idx_e2i(battOnIdx);
    batteryConstantPowerReduction = zoneSetting.batteryConstantPowerReduction; 
    
    object = MathematicalModel(internalMatpowercase, internalBusId, internalBranchIdx, ...
        internalGenOnIdx, internalBattOnIdx, batteryConstantPowerReduction);
end