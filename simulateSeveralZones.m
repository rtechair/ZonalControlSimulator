simulationSetting = jsonDecodeFile('simulation.json');

%TODO: put the following action into the simulation.json file
%startSelectionPerZone{1} = 2;

% In the following, the 'cell' data structure is used instead of 'matrix' because a matrix of char arrays
% will merge them into a single char array, which is not the desired behavior

zoneName = struct2cell(simulationSetting.Zone);
numberOfZones = size(zoneName,1);

zoneFilename = cell(numberOfZones,1);
for l = 1:numberOfZones
    % the matrix merges the char arrays together
    zoneFilename{l} = ['zone' zoneName{l} '.json'];
end

zoneSetting = cell(numberOfZones,1);
for l = 1:numberOfZones
   zoneSetting{l} = jsonDecodeFile(zoneFilename{l}); 
end

% e.g. delayCurtVG = zoneSetting{1}.DelayInSeconds.curtailment

electricalGrid = ElectricalGrid(simulationSetting.basecase);

%% Zone
topologyZone = cell(numberOfZones,1);
for l = 1:numberOfZones
   topologyZone{l} = TopologicalZone(zoneSetting{l}.busId, electricalGrid); 
end

%TODO put maxPowerGeneration as a topologicalZone's property
timeSeries = cell(numberOfZones,1);
for l = 1:numberOfZones
    filename = zoneSetting{l}.TimeSeries.filename;
    timeSeriesSetting = zoneSetting{l}.TimeSeries;
    
    startPossibility = struct2cell(timeSeriesSetting.StartPossibilityForGeneratorInSeconds);
    startSelected = timeSeriesSetting.startSelected;
    start = startPossibility{startSelected};
    %start = zoneSetting{l}.TimeSeries.StartGeneratorInSeconds.x1; % TODO: in the json file, this is in iterations not seconds
    controlCycle = zoneSetting{l}.controlCycle;
    duration = simulationSetting.durationInSeconds;
    maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    timeSeries{l} = DynamicTimeSeries(filename, start, controlCycle, duration, maxPowerGeneration, numberOfGenOn);
end

simulatedZone = cell(numberOfZones,1);
for l = 1:numberOfZones
   numberOfBuses = topologyZone{l}.NumberOfBuses;
   numberOfGenOn = topologyZone{l}.NumberOfGen;
   numberOfBattOn = topologyZone{l}.NumberOfBatt;
   numberOfBranches = topologyZone{l}.NumberOfBranches;
   delayCurtSeconds = zoneSetting{l}.DelayInSeconds.curtailment;
   delayBattSeconds = zoneSetting{l}.DelayInSeconds.battery;
   controlCycle = zoneSetting{l}.controlCycle;
   maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
   battConstPowerReduc = zoneSetting{l}.batteryConstantPowerReduction;
   % TODO, change the order of attributes of simulatedZone constructor
   simulatedZone{l} = SimulatedZone(numberOfBuses, numberOfGenOn, numberOfBattOn, numberOfBranches,...
       delayCurtSeconds, delayBattSeconds, controlCycle, maxPowerGeneration, battConstPowerReduc);
end

%% Limiter

limiterFilename = cell(numberOfZones,1);
for l = 1:numberOfZones
    limiterFilename{l} = ['limiter' zoneName{l} '.json'];
end

limiterSetting = cell(numberOfZones,1);
for l = 1:numberOfZones
    limiterSetting{l} = jsonDecodeFile(limiterFilename{l}); 
end

controller = cell(numberOfZones,1);
for l = 1:numberOfZones
    branchFlowLimit = zoneSetting{l}.branchFlowLimit;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    numberOfBattOn = topologyZone{l}.NumberOfBatt;
    increasingEchelon = limiterSetting{l}.IncreaseCurtPercentEchelon;
    decreasingEchelon = limiterSetting{l}.DecreaseCurtPercentEchelon;
    lowerThreshold = limiterSetting{l}.LowerThresholdPercent;
    upperThreshold = limiterSetting{l}.UpperThresholdPercent;
    controlCycle = zoneSetting{l}.controlCycle;
    delayCurt = zoneSetting{l}.DelayInSeconds.curtailment / controlCycle;
    delayBatt = zoneSetting{l}.DelayInSeconds.battery / controlCycle;
    maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
    controller{l} = Limiter(branchFlowLimit, numberOfGenOn, numberOfBattOn, ...
        increasingEchelon, decreasingEchelon, lowerThreshold, upperThreshold, ...
        delayCurt, maxPowerGeneration);
end

%% Telecom

telecom = cell(numberOfZones,1);
for l = 1:numberOfZones
    telecomSetting = zoneSetting{l}.DelayInSeconds.Telecom;
    delayTimeSeries2Zone = telecomSetting.timeSeries2Zone;
    delayController2Zone = telecomSetting.controller2Zone;
    delayZone2Controller = telecomSetting.zone2Controller;
    
    numberOfBuses = topologyZone{l}.NumberOfBuses;
    numberOfBranches = topologyZone{l}.NumberOfBranches;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    numberOfBattOn = topologyZone{l}.NumberOfBatt; 
    
    % TODO, change the order of attributes of the Telecom constructors
    telecom{l}.timeSeries2Zone = TelecomTimeSeries2Zone(delayTimeSeries2Zone, numberOfGenOn);
    telecom{l}.controller2Zone = TelecomController2Zone(delayController2Zone, numberOfGenOn, ...
        numberOfBattOn);
    telecom{l}.zone2Controller = TelecomZone2Controller(delayZone2Controller, numberOfGenOn, ...
        numberOfBattOn, numberOfBuses, numberOfBranches); 
end

%% Result of simulation
resultZone = cell(numberOfZones, 1);
for l = 1:numberOfZones
    duration = simulationSetting.durationInSeconds;
    controlCycle = zoneSetting{l}.controlCycle;
    numberOfBuses = topologyZone{l}.NumberOfBuses;
    numberOfBranches = topologyZone{l}.NumberOfBranches;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    numberOfBattOn = topologyZone{l}.NumberOfBuses; 
    maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
    
    busId = topologyZone{l}.BusId;
    branchIdx = topologyZone{l}.BranchIdx;
    genOnIdx = topologyZone{l}.GenOnIdx;
    
    delayCurt = zoneSetting{l}.DelayInSeconds.curtailment /controlCycle;
    delayBatt = zoneSetting{l}.DelayInSeconds.battery / controlCycle;
    
    %TODO the results will later need info about battery to display
    %PowerBattery and EnergyBattery
    %TODO rename class into GraphicResult
    resultZone{l} = ResultGraphic(duration, controlCycle, ...
        numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, maxPowerGeneration, ...
        busId, branchIdx, genOnIdx, delayCurt, delayBatt);   
end

%% Initialization

% TODO: cheating, here, the properties of objects are directly accessed and set.
% This should not be done likewise. Later change it

for l = 1:numberOfZones
    
    % TODO: setInitialPA for SimulatedZone class
   simulatedZone{l}.State.PowerAvailable = timeSeries{l}.getInitialPowerAvailable();
   powerAvailable = simulatedZone{l}.State.PowerAvailable;
   maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
   % TODO: setInitialPG for SimulatedZone class, or is there an alternative?
   simulatedZone{l}.State.PowerGeneration = min(powerAvailable, maxPowerGeneration);
   
   genOnIdx = topologyZone{l}.GenOnIdx;
   powerGeneration = simulatedZone{l}.State.PowerGeneration;
   electricalGrid.updateGeneration(genOnIdx, powerGeneration);
   
   
   battOnIdx = topologyZone{l}.BattOnIdx;
   powerBattery = simulatedZone{l}.State.PowerBattery;
   electricalGrid.updateBattInjection(battOnIdx, powerBattery);
end

electricalGrid.runPowerFlow();

for l = 1:numberOfZones
    busId = topologyZone{l}.BusId;
    branchIdx = topologyZone{l}.BranchIdx;
    branchBorderIdx = topologyZone{l}.BranchBorderIdx;
    % TODO: why in the following 2 methods, one is associated to State,
    % while the other is not associate to Disturbance?
   simulatedZone{l}.State.updatePowerBranchFlow(branchIdx, electricalGrid);
   % TODO: why in the previous methods, 'electricalGrid' takes the 2nd
   % attribute, while in the next method it is the 1st attribute
   
   simulatedZone{l}.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
   % do not compute disturbance transit initially, as there is not enough data 
   simulatedZone{l}.dropOldestPowerTransit();
   simulatedZone{l}.saveState(resultZone{l});
   
   telecom{l}.zone2Controller.receiveThenSend(simulatedZone{l}, controller{l});
   
   controller{l}.computeControl();
   
   resultZone{l}.prepareForNextStep();    
end

%% An iteration for each zone
   
duration = simulationSetting.durationInSeconds;
step = simulationSetting.windowInSeconds;
start = step; % TODO check 'start' is correct

for time = start:step:duration 
    
    for l = 1:numberOfZones
        
        stepZone = zoneSetting{l}.controlCycle;
        isZoneToBeUpdated = mod(time, stepZone) == 0; 
       if isZoneToBeUpdated
           telecom{l}.timeSeries2Zone.receiveThenSend(timeSeries{l}, simulatedZone{l});
           telecom{l}.controller2Zone.receiveThenSend(controller{l}, simulatedZone{l});

           simulatedZone{l}.computeDisturbanceGeneration();
           simulatedZone{l}.updateState();

           genOnIdx = topologyZone{l}.GenOnIdx;
           powerGeneration = simulatedZone{l}.State.PowerGeneration;
           electricalGrid.updateGeneration(genOnIdx, powerGeneration);

           battOnIdx = topologyZone{l}.BattOnIdx;
           powerBattery = simulatedZone{l}.State.PowerBattery;
           electricalGrid.updateBattInjection(battOnIdx, powerBattery);
       end
    end
    
    electricalGrid.runPowerFlow();
    
    for l = 1:numberOfZones
        
        stepZone = zoneSetting{l}.controlCycle;
        isZoneToBeUpdated = mod(time, stepZone) == 0; 
        if isZoneToBeUpdated
            busId = topologyZone{l}.BusId;
            branchIdx = topologyZone{l}.BranchIdx;
            simulatedZone{l}.State.updatePowerBranchFlow(branchIdx, electricalGrid);
            simulatedZone{l}.updatePowerTransit(electricalGrid, busId, branchIdx);
            % can update distrubance transit now, there is enough data
            simulatedZone{l}.updateDisturbanceTransit();
            simulatedZone{l}.dropOldestPowerTransit();

            telecom{l}.zone2Controller.receiveThenSend(simulatedZone{l}, controller{l});
            controller{l}.computeControl();

            simulatedZone{l}.saveState(resultZone{l});
            simulatedZone{l}.saveControl(resultZone{l});
            simulatedZone{l}.saveDisturbance(resultZone{l});
            resultZone{l}.prepareForNextStep();
        end
    end   

end
    
%% Graphic Representation

%TODO, check that in the names of the graphics, there is the name of the
%zone

%figTopologyGraph = cell(numberOfZones,1);
for l = 1:numberOfZones
   topologyZone{l}.plotLabeledGraph(electricalGrid); 
end


%figAbsFlowBranch = cell(numberOfZones,1);
for l = 1:numberOfZones
   resultZone{l}.plotAbsoluteFlowBranch(electricalGrid); 
end

for l = 1:numberOfZones
   resultZone{l}.plotControlAndDisturbanceGen(electricalGrid);
end

for l = 1:numberOfZones
   resultZone{l}.plotStateGen(electricalGrid);
end

for l = 1:numberOfZones
   resultZone{l}.plotDisturbanceTransit();
end

