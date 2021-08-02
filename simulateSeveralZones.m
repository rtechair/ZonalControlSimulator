%{
Abstract:

INITIALIZATION PRIOR TO THE SIMULATION

- define the basecase used
- define the duration of simulation
- build the basecase as an 'ElectricalGrid' object, which is used during
the simulation
- load the zone setting 
- define the topology of the zone as a 'ZoneTopology' object
- define the time series used for the simulation as a 'TimeSeries' object
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


simulationSetting = decodeJsonFile('simulation.json');


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
   zoneSetting{l} = decodeJsonFile(zoneFilename{l}); 
end

% e.g. delayCurtVG = zoneSetting{1}.DelayInSeconds.curtailment

electricalGrid = ElectricalGrid(simulationSetting.basecase);

%% Zone
topologyZone = cell(numberOfZones,1);
for l = 1:numberOfZones
   topologyZone{l} = ZoneTopology(zoneName{l}, zoneSetting{l}.busId, electricalGrid); 
end

timeSeries = cell(numberOfZones,1);
for l = 1:numberOfZones
    filename = zoneSetting{l}.TimeSeries.filename;
    timeSeriesSetting = zoneSetting{l}.TimeSeries;
    
    startPossibility = struct2cell(timeSeriesSetting.StartPossibilityForGeneratorInSeconds);
    startSelected = timeSeriesSetting.startSelected;
    start = startPossibility{startSelected};
    controlCycle = zoneSetting{l}.controlCycle;
    duration = simulationSetting.durationInSeconds;
    maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    timeSeries{l} = TimeSeriesRenewableEnergy(filename, start, controlCycle, duration, maxPowerGeneration, numberOfGenOn);
end

simulatedZone = cell(numberOfZones,1);
for l = 1:numberOfZones
   numberOfBuses = topologyZone{l}.NumberOfBuses;
   numberOfBranches = topologyZone{l}.NumberOfBranches;
   numberOfGenOn = topologyZone{l}.NumberOfGen;
   numberOfBattOn = topologyZone{l}.NumberOfBatt;
   
   % cautious, here the delay is in seconds
   delayCurtSeconds = zoneSetting{l}.DelayInSeconds.curtailment;
   delayBattSeconds = zoneSetting{l}.DelayInSeconds.battery;
   controlCycle = zoneSetting{l}.controlCycle;
   maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
   battConstPowerReduc = zoneSetting{l}.batteryConstantPowerReduction;
   simulatedZone{l} = SimulatedZone(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn,...
       delayCurtSeconds, delayBattSeconds, controlCycle, maxPowerGeneration, battConstPowerReduc);
end

%% Limiter

limiterFilename = cell(numberOfZones,1);
for l = 1:numberOfZones
    limiterFilename{l} = ['limiter' zoneName{l} '.json'];
end

limiterSetting = cell(numberOfZones,1);
for l = 1:numberOfZones
    limiterSetting{l} = decodeJsonFile(limiterFilename{l}); 
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
    % cautious, here the delay is in iterations!
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
    
    telecom{l}.timeSeries2Zone = TelecomTimeSeries2Zone(numberOfGenOn, delayTimeSeries2Zone);
    telecom{l}.controller2Zone = TelecomController2Zone(...
        numberOfGenOn, numberOfBattOn, delayController2Zone);
    telecom{l}.zone2Controller = TelecomZone2Controller(...
        numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, delayZone2Controller); 
end

%% Result of simulation
resultZone = cell(numberOfZones, 1);
for l = 1:numberOfZones
    duration = simulationSetting.durationInSeconds;
    controlCycle = zoneSetting{l}.controlCycle;
    numberOfBuses = topologyZone{l}.NumberOfBuses;
    numberOfBranches = topologyZone{l}.NumberOfBranches;
    numberOfGenOn = topologyZone{l}.NumberOfGen;
    numberOfBattOn = topologyZone{l}.NumberOfBatt; 
    maxPowerGeneration = topologyZone{l}.MaxPowerGeneration;
    
    busId = topologyZone{l}.BusId;
    branchIdx = topologyZone{l}.BranchIdx;
    genOnIdx = topologyZone{l}.GenOnIdx;
    battOnIdx = topologyZone{l}.BattOnIdx;
    
    delayCurt = zoneSetting{l}.DelayInSeconds.curtailment /controlCycle;
    delayBatt = zoneSetting{l}.DelayInSeconds.battery / controlCycle;
    telecomSetting = zoneSetting{l}.DelayInSeconds.Telecom;
    delayTimeSeries2Zone = telecomSetting.timeSeries2Zone;
    delayController2Zone = telecomSetting.controller2Zone;
    delayZone2Controller = telecomSetting.zone2Controller;
    
    resultZone{l} = ResultGraphic(zoneName{l}, duration, controlCycle, ...
        numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, maxPowerGeneration, ...
        busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
        delayTimeSeries2Zone, delayController2Zone, delayZone2Controller);   
end

%% Initialization

for l = 1:numberOfZones
   simulatedZone{l}.setInitialPowerAvailable(timeSeries{l});
   simulatedZone{l}.setInitialPowerGeneration();
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
    
    %{
    The zone sends to the controller all the information about its state,
    but only one disturbance: the power transiting through the buses.
    That is why the zone uses an object 'State' but not an object
    'Disturbance' to store the Power Transit.
    %}
   simulatedZone{l}.State.updatePowerBranchFlow(electricalGrid, branchIdx);   
   simulatedZone{l}.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
   
   % do not compute disturbance transit initially, as there is not enough data 
   simulatedZone{l}.dropOldestPowerTransit();
   simulatedZone{l}.saveState(resultZone{l});
   
   telecom{l}.zone2Controller.transmitData(simulatedZone{l}, controller{l});   
   resultZone{l}.prepareForNextStep();    
end

%% An iteration for each zone
   
duration = simulationSetting.durationInSeconds;
step = simulationSetting.windowInSeconds;
start = step;

for time = start:step:duration 
    
    for l = 1:numberOfZones
        
        stepZone = zoneSetting{l}.controlCycle;
        isZoneToBeUpdated = mod(time, stepZone) == 0; 
       if isZoneToBeUpdated
           
           controller{l}.computeControl();
           controller{l}.saveControl(resultZone{l});
           telecom{l}.timeSeries2Zone.transmitData(timeSeries{l}, simulatedZone{l});
           telecom{l}.controller2Zone.transmitData(controller{l}, simulatedZone{l});

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
            simulatedZone{l}.State.updatePowerBranchFlow(electricalGrid, branchIdx);
            simulatedZone{l}.updatePowerTransit(electricalGrid, busId, branchIdx);
            
            % can update distrubance transit now, there is enough data
            simulatedZone{l}.updateDisturbanceTransit();
            simulatedZone{l}.dropOldestPowerTransit();

            telecom{l}.zone2Controller.transmitData(simulatedZone{l}, controller{l});

            simulatedZone{l}.saveState(resultZone{l});
            simulatedZone{l}.saveDisturbance(resultZone{l});
            
            simulatedZone{l}.dropOldestControl();
            resultZone{l}.prepareForNextStep();
        end
    end   

end
%% Graphic Representation

for l = 1:numberOfZones
   topologyZone{l}.plotLabeledGraph(electricalGrid); 
end

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