function object = getMathematicalModel(basecaseFilename, zoneName)
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
    internalBranchIdx = branchIdx; % because no branch is deleted during the internal conversion
    internalGenOnIdx = mapGenOn_idx_e2i(genOnIdx);
    internalBattOnIdx = mapGenOn_idx_e2i(battOnIdx);
    batteryConstantPowerReduction = zoneSetting.batteryConstantPowerReduction; 
    
    object = MathematicalModel(internalMatpowercase, internalBusId, internalBranchIdx, ...
        internalGenOnIdx, internalBattOnIdx, batteryConstantPowerReduction);
end