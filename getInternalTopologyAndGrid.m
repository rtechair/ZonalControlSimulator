function [internalTopology, internalGrid] = getInternalTopologyAndGrid(basecaseFilename, zoneName)
% Create the topology of a zone but with ID and IDX matching those of the internal matpowercase.
% the matpowercase of the internalGrid is the internal matpowercase.
% Goal: access easily the information of the zone of the internal matpowercase.
% A usecase is to check the matrices of the mathematical model.


    grid = ElectricalGrid(basecaseFilename);
    zoneFilename = ['zone' zoneName '.json'];
    zoneSetting = decodeJsonFile(zoneFilename);
    busId = zoneSetting.busId;
    
    % internal elements
    mapBus_id_e2i = grid.getMapBus_id_e2i();
    % because the mapping is sparse, it will return a sparse matrix, hence
    % the need for the function 'full'
    internalBusId = full(mapBus_id_e2i(busId));
    internalGrid = grid;
    internalGrid.replaceExternalByInternalMatpowercase();
    internalTopology = ZoneTopology(zoneName, internalBusId, internalGrid);
end