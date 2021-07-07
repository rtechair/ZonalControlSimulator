

filenameBasecase = 'case6468rte_zone1and2';
filenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

branchFlowLimit = 45;

durationSimulation = 600;

electricalGrid = ElectricalGrid(filenameBasecase);


loadInputZoneVTV;

topologyZoneVTV = TopologicalZone(inputZoneVTV.BusId, electricalGrid);

maxGen = electricalGrid.getMaxGeneration(topologyZoneVTV.GenOnIdx);

timeSeriesVTV = DynamicTimeSeries(filenameWindChargingRate, ...
    inputZoneVTV.StartTimeSeries, inputZoneVTV.SamplingTime, durationSimulation, ...
    maxGen, topologyZoneVTV.NumberOfGen);


simulatedZoneVTV = SimulatedZone(topologyZoneVTV.NumberOfBuses,...
    topologyZoneVTV.NumberOfGen, topologyZoneVTV.NumberOfBatt,...
     topologyZoneVTV.NumberOfBranches, inputZoneVTV.DelayCurt, inputZoneVTV.DelayBatt,...
     maxGen, inputZoneVTV.BattConstPowerReduc);
 
 
loadInputLimiterZoneVTV;

limiterZoneVTV = Limiter(branchFlowLimit, topologyZoneVTV.NumberOfGen, ...
    topologyZoneVTV.NumberOfBatt, inputLimiterZoneVTV.IncreaseCurtPercentEchelon, ...
    inputLimiterZoneVTV.DecreaseCurtPercentEchelon, inputLimiterZoneVTV.LowerThresholdPercent, ...
    inputLimiterZoneVTV.UpperThresholdPercent, inputZoneVTV.DelayCurt, maxGen);


%% Telecom
delayTelecomZoneVTV = 0;

telecomTimeSeries2Zone = TelecomTimeSeries2Zone(delayTelecomZoneVTV, topologyZoneVTV.NumberOfGen);

telecomController2Zone = TelecomController2Zone(delayTelecomZoneVTV, topologyZoneVTV.NumberOfGen, ...
    topologyZoneVTV.NumberOfBatt);

telecomZone2Controller = TelecomZone2Controller(delayTelecomZoneVTV, topologyZoneVTV.NumberOfGen, ...
    topologyZoneVTV.NumberOfBatt, topologyZoneVTV.NumberOfBuses, topologyZoneVTV.NumberOfBranches);

%% Memory of simulation
memoryZoneVTV = Memory(durationSimulation, inputZoneVTV.SamplingTime, ...
    topologyZoneVTV.NumberOfBuses, topologyZoneVTV.NumberOfBranches, ...
    topologyZoneVTV.NumberOfGen, topologyZoneVTV.NumberOfBatt, ...
    maxGen, topologyZoneVTV.GenOnIdx, topologyZoneVTV.BranchIdx,...
    inputZoneVTV.DelayCurt, inputZoneVTV.DelayBatt);

%% Initialization

% CHEATING: set PA(0) directly, need to be later changed
simulatedZoneVTV.State.PowerAvailable = timeSeriesVTV.PowerAvailableState(:,1);
simulatedZoneVTV.State.PowerGeneration = min(timeSeriesVTV.PowerAvailableState(:,1), maxGen);

electricalGrid.updateGeneration(topologyZoneVTV.GenOnIdx, simulatedZoneVTV.State.PowerGeneration);
electricalGrid.updateBattInjection(topologyZoneVTV.BattOnIdx, simulatedZoneVTV.State.PowerBattery);


electricalGrid.runPowerFlow();

simulatedZoneVTV.State.updatePowerBranchFlow(topologyZoneVTV.BranchIdx, electricalGrid);
simulatedZoneVTV.saveState(memoryZoneVTV);

telecomZone2Controller.receiveThenSend(simulatedZoneVTV, limiterZoneVTV);
limiterZoneVTV.computeControl();

memoryZoneVTV.prepareForNextStep();


%% an iteration for each zone
step = inputZoneVTV.SamplingTime;
start = step;

for k = start:step:durationSimulation
    telecomTimeSeries2Zone.receiveThenSend(timeSeriesVTV, simulatedZoneVTV);

    telecomController2Zone.receiveThenSend(limiterZoneVTV, simulatedZoneVTV);

    simulatedZoneVTV.computeDisturbanceGeneration();
    simulatedZoneVTV.updateState();

    electricalGrid.updateGeneration(topologyZoneVTV.GenOnIdx, simulatedZoneVTV.State.PowerGeneration);
    electricalGrid.updateBattInjection(topologyZoneVTV.BattOnIdx, simulatedZoneVTV.State.PowerBattery);


    electricalGrid.runPowerFlow();

    simulatedZoneVTV.State.updatePowerBranchFlow(topologyZoneVTV.BranchIdx, electricalGrid);

    telecomZone2Controller.receiveThenSend(simulatedZoneVTV, limiterZoneVTV);
    limiterZoneVTV.computeControl();
    
    simulatedZoneVTV.saveState(memoryZoneVTV);
    simulatedZoneVTV.saveControl(memoryZoneVTV);
    simulatedZoneVTV.saveDisturbance(memoryZoneVTV);
    memoryZoneVTV.prepareForNextStep();
end

%% Graphic Representation

P = topologyZoneVTV.plotLabeledGraph(electricalGrid);

figAbsFlowBranch = memoryZoneVTV.plotAbsoluteFlowBranch(electricalGrid);
figDeltaGenOn = memoryZoneVTV.plotControlAndDisturbanceGen(electricalGrid);
figStateGen = memoryZoneVTV.plotStateGen(electricalGrid);



