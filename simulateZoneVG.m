%{
Abstract:

INITIALIZATION PRIOR TO THE SIMULATION

- define the basecase used
- define the duration of simulation
- build the basecase as an 'ElectricalGrid' object, which is used during
the simulation
- load the zone setting 
- define the topology of the zone as a 'TopologicalZone' object
- define the time series used for the simulation as a 'DynamicTimeSeries' object
- define the simulated zone which is used during the simulation
- load the limiter setting
- define the limiter as a 'Limiter' object

- define the 3 telecommunications used during the simulation
    - TelecomTimeSeries2Zone
    - TelecomController2Zone
    - TelecomZone2Controller

- define the memory to save results of the simulation


INITIALIZATION / FIRST ITERATION OF THE SIMULATION

ITERATIONS OF THE SIMULATION

DISPLAY RESULTS

%}

filenameBasecase = 'case6468rte_zoneVGandVTV';


durationSimulation = 600;

electricalGrid = ElectricalGrid(filenameBasecase);


loadInputZoneVG;

settingZoneVG = inputZoneVG; % inputZoneVG is from loadInputZoneVG

topologyZoneVG = TopologicalZone(settingZoneVG.BusId, electricalGrid);

maxPowerGeneration = electricalGrid.getMaxPowerGeneration(topologyZoneVG.GenOnIdx);

timeSeriesVG = DynamicTimeSeries(settingZoneVG.FilenameWindChargingRate, ...
    settingZoneVG.StartTimeSeries, settingZoneVG.SamplingTime, durationSimulation, ...
    maxPowerGeneration, topologyZoneVG.NumberOfGen);


simulatedZoneVG = SimulatedZone(topologyZoneVG.NumberOfBuses,...
    topologyZoneVG.NumberOfGen, topologyZoneVG.NumberOfBatt,...
     topologyZoneVG.NumberOfBranches, settingZoneVG.DelayCurt, settingZoneVG.DelayBatt,...
     maxPowerGeneration, settingZoneVG.BattConstPowerReduc);
 
 
loadInputLimiterZoneVG;

limiterZoneVG = Limiter(settingZoneVG.BranchFlowLimit, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt, inputLimiterZoneVG.IncreaseCurtPercentEchelon, ...
    inputLimiterZoneVG.DecreaseCurtPercentEchelon, inputLimiterZoneVG.LowerThresholdPercent, ...
    inputLimiterZoneVG.UpperThresholdPercent, settingZoneVG.DelayCurt, maxPowerGeneration);


%% Telecom
delayTelecomZoneVG = 0;

telecomTimeSeries2Zone = TelecomTimeSeries2Zone(delayTelecomZoneVG, topologyZoneVG.NumberOfGen);

telecomController2Zone = TelecomController2Zone(delayTelecomZoneVG, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt);

telecomZone2Controller = TelecomZone2Controller(delayTelecomZoneVG, topologyZoneVG.NumberOfGen, ...
    topologyZoneVG.NumberOfBatt, topologyZoneVG.NumberOfBuses, topologyZoneVG.NumberOfBranches);

%% Memory of simulation
memoryZoneVG = Memory(durationSimulation, settingZoneVG.SamplingTime, ...
    topologyZoneVG.NumberOfBuses, topologyZoneVG.NumberOfBranches, ...
    topologyZoneVG.NumberOfGen, topologyZoneVG.NumberOfBatt, ...
    maxPowerGeneration, topologyZoneVG.BusId, topologyZoneVG.BranchIdx, topologyZoneVG.GenOnIdx,...
    settingZoneVG.DelayCurt, settingZoneVG.DelayBatt);

%% Initialization

% CHEATING: set PA(0) directly, need to be later changed
simulatedZoneVG.State.PowerAvailable = timeSeriesVG.PowerAvailableState(:,1);
simulatedZoneVG.State.PowerGeneration = min(timeSeriesVG.PowerAvailableState(:,1), maxPowerGeneration);

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
step = settingZoneVG.SamplingTime;
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
figDisturbTransit = memoryZoneVG.plotDisturbanceTransit();



