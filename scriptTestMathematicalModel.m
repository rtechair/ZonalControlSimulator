filenameBasecase = 'case6468rte_zone1and2';
filenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

electricalGrid = ElectricalGrid(filenameBasecase);


loadInputZoneVG;

topologyZoneVG = TopologicalZone(inputZoneVG.BusId, electricalGrid);

internalZoneVGBusId = electricalGrid.MapBus_id_e2i(topologyZoneVG.BusId);
internalZoneVGGenIdx = electricalGrid.MapGenOn_idx_e2i(topologyZoneVG.GenOnIdx); 
internalZoneVGBattIdx = electricalGrid.MapGenOn_idx_e2i(topologyZoneVG.BattOnIdx);

dynamicModelZoneVG = MathematicalModel(electricalGrid.InternalMatpowercase,...
    internalZoneVGBusId, topologyZoneVG.BranchIdx, internalZoneVGGenIdx,...
    internalZoneVGBattIdx, inputZoneVG.BattConstPowerReduc);


alessioMatrices = load('alessioABCmatrices');

