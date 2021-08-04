classdef Zone < handle
   
    properties
       name
       setting
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
            maxPowerGeneration = obj.topology.MaxPowerGeneration;
            numberOfGenOn = obj.topology.NumberOfGen;
            obj.timeSeries = TimeSeriesRenewableEnergy(...
                filename, start, controlCycle, duration, maxPowerGeneration, numberOfGenOn);
        end
        
        function setZoneEvolution(obj)
            numberOfBuses = obj.topology.NumberOfBuses;
            numberOfBranches = obj.topology.NumberOfBranches;
            numberOfGenOn = obj.topology.NumberOfGen;
            numberOfBattOn = obj.topology.NumberOfBatt;

            % cautious, here the delay is in seconds
            delayCurtSeconds = obj.setting.DelayInSeconds.curtailment;
            delayBattSeconds = obj.setting.DelayInSeconds.battery;
            controlCycle = obj.setting.controlCycle;
            maxPowerGeneration = obj.topology.MaxPowerGeneration;
            battConstPowerReduc = obj.setting.batteryConstantPowerReduction;

            obj.zoneEvolution = SimulatedZone(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn,...
                delayCurtSeconds, delayBattSeconds, controlCycle, maxPowerGeneration, battConstPowerReduc);
        end
        
        function setTelecom(obj)
            telecomSetting = obj.setting.DelayInSeconds.Telecom;
            delayTimeSeries2Zone = telecomSetting.timeSeries2Zone;
            delayController2Zone = telecomSetting.controller2Zone;
            delayZone2Controller = telecomSetting.zone2Controller;

            numberOfBuses = obj.topology.NumberOfBuses;
            numberOfBranches = obj.topology.NumberOfBranches;
            numberOfGenOn = obj.topology.NumberOfGen;
            numberOfBattOn = obj.topology.NumberOfBatt;
            
            obj.telecomTimeSeries2Zone = TelecomTimeSeries2Zone(numberOfGenOn, delayTimeSeries2Zone);
            obj.telecomController2Zone = TelecomController2Zone(...
                numberOfGenOn, numberOfBattOn, delayController2Zone);
            obj.telecomZone2Controller = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, delayZone2Controller);
        end
        
        function setResult(obj, duration)
            controlCycle = obj.setting.controlCycle;
            numberOfBuses = obj.topology.NumberOfBuses;
            numberOfBranches = obj.topology.NumberOfBranches;
            numberOfGenOn = obj.topology.NumberOfGen;
            numberOfBattOn = obj.topology.NumberOfBatt;
            maxPowerGeneration = obj.topology.MaxPowerGeneration;
            
            busId = obj.topology.BusId;
            branchIdx = obj.topology.BranchIdx;
            genOnIdx = obj.topology.GenOnIdx;
            battOnIdx = obj.topology.BattOnIdx;
            
            % The delays here are in number of iterations, not in seconds
            delayCurt = obj.setting.DelayInSeconds.curtailment / controlCycle;
            delayBatt = obj.setting.DelayInSeconds.battery / controlCycle;
            % TODO: cautious here, what is the unit of the telecom delays?
            telecomSetting = obj.setting.DelayInSeconds.Telecom;
            delayTimeSeries2Zone = telecomSetting.timeSeries2Zone;
            delayController2Zone = telecomSetting.controller2Zone;
            delayZone2Controller = telecomSetting.zone2Controller;
            
            obj.result = ResultGraphic(obj.name, duration, controlCycle,...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, maxPowerGeneration, ...
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
        function setController(obj)
            branchFlowLimit = obj.setting.branchFlowLimit;
            numberOfGenOn = obj.topology.NumberOfGen;
            numberOfBattOn = obj.topology.NumberOfBatt;
            increasingEchelon = obj.controllerSetting.IncreaseCurtPercentEchelon;
            decreasingEchelon = obj.controllerSetting.DecreaseCurtPercentEchelon;
            lowerThreshold = obj.controllerSetting.LowerThresholdPercent;
            upperThreshold = obj.controllerSetting.UpperThresholdPercent;
            controlCycle = obj.setting.controlCycle;
            % cautious, here the delay is in iterations!
            delayCurt = obj.setting.DelayInSeconds.curtailment / controlCycle;
            delayBatt = obj.setting.DelayInSeconds.battery / controlCycle; % unused
            maxPowerGeneration = obj.topology.MaxPowerGeneration;
            
            obj.controller = Limiter(branchFlowLimit, numberOfGenOn, numberOfBattOn, ...
                increasingEchelon, decreasingEchelon, lowerThreshold, upperThreshold, ...
                delayCurt, maxPowerGeneration);
        end
        
        function initializePowerAvailable(obj)
            obj.zoneEvolution.setInitialPowerAvailable(obj.timeSeries);
        end
        
        function initializePowerGeneration(obj)
           obj.zoneEvolution.setInitialPowerGeneration();
        end
        
        function genOnIdx = getGenOnIdx(obj)
            genOnIdx = obj.topology.GenOnIdx;
        end
        
        function powerGeneration = getPowerGeneration(obj)
           powerGeneration = obj.zoneEvolution.State.powerGeneration;
        end
    end
end