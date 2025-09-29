basecaseFilename = "case6468rte_zone_VG_VTV_BLA.m";
grid = ElectricalGrid(basecaseFilename);
busId = [1445, 2076, 2135, 2745, 4720, 10000];
topology = ZoneTopology(" VGsmall", busId, grid);

frontierBusId = topology.getFrontierBusId();
branchIdx = topology.getBranchIdx();
genIdx = topology.getGenOnIdx();
battIdx = topology.getBattOnIdx();

setGenerationToZero(genIdx, grid);
setPowerBatteryToZero(battIdx, grid);
grid.setNetworkPTDF();

ptdfConstruction = PTDFConstruction(busId, frontierBusId, branchIdx, genIdx, battIdx);

ptdfConstruction.setPTDF(grid);

ptdfBusAtZero = ptdfConstruction.getPTDFBus();
ptdfGenAtZero = ptdfConstruction.getPTDFGen();
ptdfBattAtZero = ptdfConstruction.getPTDFBatt();

isGeneratorUpdatedToMaxValue = false;
if isGeneratorUpdatedToMaxValue
    maxPG = topology.getMaxPowerGeneration();
    maxPB = topology.getMaxPowerBattery();
    
    grid.updateGeneration(genIdx, maxPG);
    grid.updateBattInjection(battIdx, maxPB);
    grid.setNetworkPTDF();
    ptdfConstruction.setPTDF(grid);
    ptdfBusAtMax = ptdfConstruction.getPTDFBus();

    ptdfDiff = ptdfBusAtMax - ptdfBusAtZero;
end

isGenerationEnormous = false;
if isGenerationEnormous
    grid.updateGeneration(genIdx, 100*maxPG);
    grid.updateBattInjection(battIdx, 100*maxPB);
    grid.setNetworkPTDF();
    ptdfConstruction.setPTDF(grid);
    ptdfImpossible = ptdfConstruction.getPTDFBus();
    
    ptdfDiff2 = ptdfImpossible - ptdfBusAtZero;
end

%{
Conclusion: the PTDF do not change despite the substantial changes of
power generations of generators in the zone. An interpretation is that
PTDFs are independent of the watts on the buses and on the lines.
%}

% branch 6 is: 2745    10000

isBranchSwitchedOff = false;
if isBranchSwitchedOff
    statusBranchOff = 0;
    grid.setBranchStatus(branchIdx(6), statusBranchOff);
    
    grid.setNetworkPTDF();
    ptdfConstruction.setPTDF(grid);
    ptdfBus4 = ptdfConstruction.getPTDFBus();
end

function setGenerationToZero(genIdx, electricalGrid)
    nGen = length(genIdx);
    electricalGrid.updateGeneration(genIdx, zeros(nGen,1));
end

function setPowerBatteryToZero(battIdx, electricalGrid)
    nBatt = length(battIdx);
    electricalGrid.updateBattInjection(battIdx, zeros(nBatt,1));
end