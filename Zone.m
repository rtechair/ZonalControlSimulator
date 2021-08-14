classdef Zone < handle
   
    properties
       name
       setting
       delayInIterations
       topology
       zoneEvolution
       
       telecomZone2Controller
       telecomController2Zone
       telecomTimeSeries2Zone
       
       controllerSetting
       controller
       timeSeries
       
       result
    end
    
    methods
        function obj = Zone(name, electricalGrid, duration)
            obj.name = name;
            obj.setSetting();
            obj.setDelayInIterations();
            obj.setTopology(electricalGrid);
            obj.setTimeSeries(duration);
            obj.setZoneEvolution();
            obj.setTelecom();
            obj.setResult(duration);
            obj.setControllerSetting();
            obj.setController();
        end
        
        function setSetting(obj)
            filename = obj.getFilename();
            obj.setting = decodeJsonFile(filename);
        end
        
        function zoneFilename = getFilename(obj)
            zoneFilename = ['zone' obj.name '.json'];
        end
        
        function setDelayInIterations(obj)
            controlCycle = obj.setting.controlCycle;
            delayInSeconds = obj.setting.DelayInSeconds;
            delayCurtInSeconds = delayInSeconds.curtailment;
            delayBattInSeconds = delayInSeconds.battery;
            delayTimeSeries2ZoneInSeconds = delayInSeconds.Telecom.timeSeries2Zone;
            delayController2ZoneInSeconds = delayInSeconds.Telecom.controller2Zone;
            delayZone2ControllerInSeconds = delayInSeconds.Telecom.zone2Controller;
            obj.delayInIterations = DelayInIterations(...
                controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayTimeSeries2ZoneInSeconds, ...
                delayController2ZoneInSeconds, ...
                delayZone2ControllerInSeconds);
            
        end
        
        function setTopology(obj, electricalGrid)
           busId = obj.setting.busId;
           obj.topology = ZoneTopology(obj.name, busId, electricalGrid);
        end
        
        function setTimeSeries(obj, duration)
            filename = obj.setting.TimeSeries.filename;
            
            % Analyze the section of the json file regarding the TimeSeries setting
            timeSeriesSetting = obj.setting.TimeSeries;
            startPossibility = struct2cell(timeSeriesSetting.StartPossibilityForGeneratorInSeconds);
            startSelected = timeSeriesSetting.startSelected;
            start = startPossibility{startSelected};
            controlCycle = obj.setting.controlCycle;
            maxPowerGeneration = obj.topology.maxPowerGeneration;
            numberOfGenOn = obj.topology.numberOfGenOn;
            obj.timeSeries = TimeSeriesRenewableEnergy(...
                filename, start, controlCycle, duration, maxPowerGeneration, numberOfGenOn);
        end
        
        function setZoneEvolution(obj)
            numberOfBuses = obj.topology.numberOfBuses;
            numberOfBranches = obj.topology.numberOfBranches;
            numberOfGenOn = obj.topology.numberOfGenOn;
            numberOfBattOn = obj.topology.numberOfBattOn;

            delayCurt = obj.delayInIterations.curt;
            delayBatt = obj.delayInIterations.batt;
            
            maxPowerGeneration = obj.topology.maxPowerGeneration;
            battConstPowerReduc = obj.setting.batteryConstantPowerReduction;

            obj.zoneEvolution = ZoneEvolution(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn,...
                delayCurt, delayBatt, maxPowerGeneration, battConstPowerReduc);
        end
        
        function setTelecom(obj)
            delayTimeSeries2Zone = obj.delayInIterations.timeSeries2Zone;
            delayController2Zone = obj.delayInIterations.controller2Zone;
            delayZone2Controller = obj.delayInIterations.zone2Controller;
            
            numberOfBuses = obj.topology.numberOfBuses;
            numberOfBranches = obj.topology.numberOfBranches;
            numberOfGenOn = obj.topology.numberOfGenOn;
            numberOfBattOn = obj.topology.numberOfBattOn;
            
            obj.telecomTimeSeries2Zone = TelecomTimeSeries2Zone(numberOfGenOn, delayTimeSeries2Zone);
            obj.telecomController2Zone = TelecomController2Zone(...
                numberOfGenOn, numberOfBattOn, delayController2Zone);
            obj.telecomZone2Controller = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, delayZone2Controller);
        end
        
        function setResult(obj, duration)
            controlCycle = obj.setting.controlCycle;
            numberOfBuses = obj.topology.numberOfBuses;
            numberOfBranches = obj.topology.numberOfBranches;
            numberOfGenOn = obj.topology.numberOfGenOn;
            numberOfBattOn = obj.topology.numberOfBattOn;
            maxPowerGeneration = obj.topology.maxPowerGeneration;
            branchFlowLimit = obj.setting.branchFlowLimit;
            
            busId = obj.topology.busId;
            branchIdx = obj.topology.branchIdx;
            genOnIdx = obj.topology.genOnIdx;
            battOnIdx = obj.topology.battOnIdx;
            
            delayCurt = obj.delayInIterations.curt;
            delayBatt = obj.delayInIterations.batt;
            delayTimeSeries2Zone = obj.delayInIterations.timeSeries2Zone;
            delayController2Zone = obj.delayInIterations.controller2Zone;
            delayZone2Controller = obj.delayInIterations.zone2Controller;
            
            obj.result = ResultGraphic(obj.name, duration, controlCycle,...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, ...
                maxPowerGeneration, branchFlowLimit, ...
                busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller);
        end
        
        % WARNING: the following function is for the limiter,
        % it can not be used for other types of controllers.
        % Hence, it will be later modified TODO
        function limiterFilename = getLimiterFilename(obj)
            limiterFilename = ['limiter' obj.name '.json'];
        end
        
        function setControllerSetting(obj)
           obj.controllerSetting = decodeJsonFile(obj.getLimiterFilename());
        end
        
        % WARNING: actually this function sets a limiter as the controller
        % TODO: handle the case when it is not the limiter
        function setController(obj)
            branchFlowLimit = obj.setting.branchFlowLimit;
            numberOfGenOn = obj.topology.numberOfGenOn;
            numberOfBattOn = obj.topology.numberOfBattOn;
            increasingEchelon = obj.controllerSetting.IncreaseCurtPercentEchelon;
            decreasingEchelon = obj.controllerSetting.DecreaseCurtPercentEchelon;
            lowerThreshold = obj.controllerSetting.LowerThresholdPercent;
            upperThreshold = obj.controllerSetting.UpperThresholdPercent;
            controlCycle = obj.setting.controlCycle;
            % cautious, here the delay is in iterations!
            delayCurt = obj.setting.DelayInSeconds.curtailment / controlCycle;
            delayBatt = obj.setting.DelayInSeconds.battery / controlCycle; % unused
            maxPowerGeneration = obj.topology.maxPowerGeneration;
            
            obj.controller = Limiter(branchFlowLimit, numberOfBattOn, ...
                increasingEchelon, decreasingEchelon, lowerThreshold, upperThreshold, ...
                delayCurt, maxPowerGeneration);
        end
        
        function initializePowerAvailable(obj)
            obj.zoneEvolution.setInitialPowerAvailable(obj.timeSeries);
        end
        
        function initializePowerGeneration(obj)
           obj.zoneEvolution.setInitialPowerGeneration();
        end
        
        %{
        The zone sends to the controller all the information about its state,
        but only one disturbance: the power transiting through the buses.
        That is why the zone uses an object 'state' but not an object
        'Disturbance' to store the Power Transit.
        %}
        function updatePowerFlow(obj, electricalGrid)
            branchIdx = obj.topology.branchIdx;
            state = obj.zoneEvolution.state;
            powerFlow = electricalGrid.getPowerFlow(branchIdx);
            state.setPowerFlow(powerFlow);
        end
        
        function updatePowerTransit(obj, electricalGrid)
            busId = obj.topology.busId;
            branchBorderIdx = obj.topology.branchBorderIdx;
            obj.zoneEvolution.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
        end
        
        function updateGrid(obj,electricalGrid)
            obj.updateGridGeneration(electricalGrid);
            obj.updateGridBattInjection(electricalGrid);
        end
        
        function updateGridGeneration(obj, electricalGrid)
            % TODO: the access to 'powerGeneration' is strange
            genOnIdx = obj.topology.genOnIdx;
            powerGeneration = obj.zoneEvolution.state.getPowerGeneration;
            electricalGrid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridBattInjection(obj, electricalGrid)
            % TODO: the access to 'powerBattery' is strange
            battOnIdx = obj.topology.battOnIdx;
            powerBattery = obj.zoneEvolution.state.getPowerBattery;
            electricalGrid.updateBattInjection(battOnIdx, powerBattery);
        end
        
        function dropOldestPowerTransit(obj)
            obj.zoneEvolution.dropOldestPowerTransit();
        end
        
        function saveState(obj)
            obj.zoneEvolution.saveState(obj.result);
        end
        
        function transmitDataController2Zone(obj)
            obj.telecomController2Zone.transmitData(obj.controller, obj.zoneEvolution);
        end
        
        function transmitDataTimeSeries2Zone(obj)
            obj.telecomTimeSeries2Zone.transmitData(obj.timeSeries, obj.zoneEvolution);
        end
        
        function transmitDataZone2Controller(obj)
            obj.telecomZone2Controller.transmitData(obj.zoneEvolution, obj.controller);
        end
        
        function prepareForNextStep(obj)
            obj.timeSeries.prepareForNextStep();
            obj.result.prepareForNextStep();
            
            obj.zoneEvolution.dropOldestPowerTransit();
            obj.zoneEvolution.dropOldestControl();
        end
        
        function boolean = isToBeSimulated(obj, currentTime)
            boolean = mod(currentTime, obj.setting.controlCycle) == 0;
        end
        
        function simulate(obj)
            obj.controller.computeControl();
            obj.controller.saveControl(obj.result);
            obj.transmitDataController2Zone()
            obj.transmitDataTimeSeries2Zone();
            obj.zoneEvolution.computeDisturbancePowerGeneration();
            obj.zoneEvolution.updateState();
        end
        
        function update(obj, electricalGrid)
            obj.updatePowerFlow(electricalGrid);
            obj.updatePowerTransit(electricalGrid);
            obj.zoneEvolution.updateDisturbancePowerTransit();
            
            obj.transmitDataZone2Controller();
        end
        
        function saveResult(obj)
            obj.zoneEvolution.saveState(obj.result);
            obj.zoneEvolution.saveDisturbance(obj.result);
        end
        
        function plotTopology(obj, electricalGrid)
            obj.topology.plotLabeledGraph(electricalGrid);
        end
        
        function plotResult(obj, electricalGrid)
            obj.result.plotAbsoluteFlowBranch(electricalGrid);
            obj.result.plotControlAndDisturbanceGen(electricalGrid);
            obj.result.plotStateGen(electricalGrid);
            obj.result.plotDisturbanceTransit();
        end
        %% GETTER
        
        function busId = getBusId(obj)
            busId = obj.topology.busId;
        end
        
        function branchIdx = getBranchIdx(obj)
            branchIdx = obj.topology.branchIdx;
        end
        
        function branchBorderIdx = getBranchBorderIdx(obj)
            branchBorderIdx = obj.topology.branchBorderIdx;
        end
        
        function genOnIdx = getGenOnIdx(obj)
            genOnIdx = obj.topology.genOnIdx;
        end
        
        function battOnIdx = getBattOnIdx(obj)
            battOnIdx = obj.topology.battOnIdx;
        end
        
        function powerGeneration = getPowerGeneration(obj)
           powerGeneration = obj.zoneEvolution.state.powerGeneration;
        end
        
        function powerBattery = getPowerBattery(obj)
            powerBattery = obj.zoneEvolution.state.powerBattery;
        end
    end
end