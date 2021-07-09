

filenameBasecase = 'case6468rte_zone1and2';
filenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

branchFlowLimit = 45;

durationSimulation = 600;

electricalGrid = ElectricalGrid(filenameBasecase);


loadInputZoneVG;

topologyZoneVG = TopologicalZone(inputZoneVG.BusId, electricalGrid);

maxGen = electricalGrid.getMaxGeneration(topologyZoneVG.GenOnIdx);

timeSeriesVG = DynamicTimeSeries(filenameWindChargingRate, ...
    inputZoneVG.StartTimeSeries, inputZoneVG.SamplingTime, durationSimulation, ...
    maxGen, topologyZoneVG.NumberOfGen);


simulatedZoneVG = SimulatedZone(topologyZoneVG.NumberOfBuses,...
    topologyZoneVG.NumberOfGen, topologyZoneVG.NumberOfBatt,...
     topologyZoneVG.NumberOfBranches, inputZoneVG.DelayCurt, inputZoneVG.DelayBatt,...
     maxGen, inputZoneVG.BattConstPowerReduc);
 
 
loadInputLimiterZoneVG;

limiterZoneVG = Limiter(branchFlowLimit, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt, inputLimiterZoneVG.IncreaseCurtPercentEchelon, ...
    inputLimiterZoneVG.DecreaseCurtPercentEchelon, inputLimiterZoneVG.LowerThresholdPercent, ...
    inputLimiterZoneVG.UpperThresholdPercent, inputZoneVG.DelayCurt, maxGen);


%% Telecom
delayTelecomZoneVG = 0;

telecomTimeSeries2Zone = TelecomTimeSeries2Zone(delayTelecomZoneVG, topologyZoneVG.NumberOfGen);

telecomController2Zone = TelecomController2Zone(delayTelecomZoneVG, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt);

telecomZone2Controller = TelecomZone2Controller(delayTelecomZoneVG, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt, topologyZoneVG.NumberOfBuses, topologyZoneVG.NumberOfBranches);

%% Memory of simulation
memoryZoneVG = Memory(durationSimulation, inputZoneVG.SamplingTime, ...
    topologyZoneVG.NumberOfBuses, topologyZoneVG.NumberOfBranches, ...
    topologyZoneVG.NumberOfGen, topologyZoneVG.NumberOfBatt, ...
    maxGen, topologyZoneVG.GenOnIdx, topologyZoneVG.BranchIdx,...
    inputZoneVG.DelayCurt, inputZoneVG.DelayBatt);

%% Initialization

% CHEATING: set PA(0) directly, need to be later changed
simulatedZoneVG.State.PowerAvailable = timeSeriesVG.PowerAvailableState(:,1);
simulatedZoneVG.State.PowerGeneration = min(timeSeriesVG.PowerAvailableState(:,1), maxGen);

electricalGrid.updateGeneration(topologyZoneVG.GenOnIdx, simulatedZoneVG.State.PowerGeneration);
electricalGrid.updateBattInjection(topologyZoneVG.BattOnIdx, simulatedZoneVG.State.PowerBattery);


electricalGrid.runPowerFlow();

simulatedZoneVG.State.updatePowerBranchFlow(topologyZoneVG.BranchIdx, electricalGrid);
simulatedZoneVG.updatePowerTransit(electricalGrid, topologyZoneVG.BusId, topologyZoneVG.BranchBorderIdx);
% do not compute disturbance Transit, as there is not enough data initially
simulatedZoneVG.dropOldestPowerTransit();
simulatedZoneVG.saveState(memoryZoneVG);

telecomZone2Controller.receiveThenSend(simulatedZoneVG, limiterZoneVG);
limiterZoneVG.computeControl();

memoryZoneVG.prepareForNextStep();


%% an iteration for each zone
step = inputZoneVG.SamplingTime;
start = step;


for k = start:step:durationSimulation
    telecomTimeSeries2Zone.receiveThenSend(timeSeriesVG, simulatedZoneVG);

    telecomController2Zone.receiveThenSend(limiterZoneVG, simulatedZoneVG);

    simulatedZoneVG.computeDisturbanceGeneration();
    simulatedZoneVG.updateState();

    electricalGrid.updateGeneration(topologyZoneVG.GenOnIdx, simulatedZoneVG.State.PowerGeneration);
    electricalGrid.updateBattInjection(topologyZoneVG.BattOnIdx, simulatedZoneVG.State.PowerBattery);


    electricalGrid.runPowerFlow();

    simulatedZoneVG.State.updatePowerBranchFlow(topologyZoneVG.BranchIdx, electricalGrid);
    simulatedZoneVG.updatePowerTransit(electricalGrid, topologyZoneVG.BusId, topologyZoneVG.BranchBorderIdx);
    % can update disturbance transit now, there is enough data
    simulatedZoneVG.updateDisturbanceTransit();
    simulatedZoneVG.dropOldestPowerTransit();
    
    telecomZone2Controller.receiveThenSend(simulatedZoneVG, limiterZoneVG);
    limiterZoneVG.computeControl();
    
    simulatedZoneVG.saveState(memoryZoneVG);
    simulatedZoneVG.saveControl(memoryZoneVG);
    simulatedZoneVG.saveDisturbance(memoryZoneVG);
    memoryZoneVG.prepareForNextStep();
end

%% Graphic Representation

P = topologyZoneVG.plotLabeledGraph(electricalGrid);

figAbsFlowBranch = memoryZoneVG.plotAbsoluteFlowBranch(electricalGrid);
figDeltaGenOn = memoryZoneVG.plotControlAndDisturbanceGen(electricalGrid);
figStateGen = memoryZoneVG.plotStateGen(electricalGrid);



