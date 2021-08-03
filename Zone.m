classdef Zone < handle
   
    properties
       name
       setting
       topology
       zoneEvolution
       
       telecomZone2Controller
       telecomController2Zone
       telecomTimeSeries2Zone
       
       controller
       timeSeries
    end
    
    methods
        function obj = Zone(name, electricalGrid, duration)
            obj.name = name;
            obj.setSetting();
            obj.setTopology(electricalGrid);
            obj.setTimeSeries(duration);
            obj.setZoneEvolution();
            obj.setTelecom();
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
    end
end