classdef ZoneSetting < handle
% Read and interpret the JSON file into an object to get the parameters of the zone.
% when the configuration of the JSON file is modified, the setters
% need to be modify as well to depict the changes.
    
    properties (SetAccess = protected)
        settings
        
        busId
        branchFlowLimit
        controlCycle % i.e. the time step of the zone
        
        timeSeriesFilename
        startGenInSeconds
        
        batteryConstantPowerReduction % corresponds to the product T*cb in the paper
        
        delayCurtInSeconds
        delayBattInSeconds
        delayTimeSeries2ZoneInSeconds
        delayController2ZoneInSeconds
        delayZone2ControllerInSeconds
    end
    
    methods
        function obj = ZoneSetting(zoneFilename)
            obj.settings = decodeJsonFile(zoneFilename);
            
            obj.setBusId();
            obj.setBranchFlowLimit();
            obj.setControlCycle();
            
            obj.setTimeSeriesFilename();
            obj.setStartGenInSeconds();
            
            obj.setBatteryConstantPowerReduction();
            
            obj.setDelayCurtInSeconds();
            obj.setDelayBattInSeconds();
            obj.setDelayTimeSeries2ZoneInSeconds();
            obj.setDelayController2ZoneInSeconds();
            obj.setDelayZone2ControllerInSeconds();
        end
    end
    
    methods (Access = private)
        %% SETTER
        function setBusId(obj)
            obj.busId = obj.settings.busId;
        end
        
        function setBranchFlowLimit(obj)
            obj.branchFlowLimit = obj.settings.branchFlowLimit;
        end
        
        function setControlCycle(obj)
            obj.controlCycle = obj.settings.controlCycle;
        end
        
        function setTimeSeriesFilename(obj)
            obj.timeSeriesFilename = obj.settings.TimeSeries.filename;
        end
        
        function setStartGenInSeconds(obj)
            timeSeries = obj.settings.TimeSeries;
            startPossibility = struct2cell(timeSeries.StartPossibilityForGeneratorInSeconds);
            startSelected = timeSeries.startSelected;
            obj.startGenInSeconds = startPossibility{startSelected};
        end
        
        function setBatteryConstantPowerReduction(obj)
            obj.batteryConstantPowerReduction = obj.settings.batteryConstantPowerReduction;
        end
        
        function setDelayCurtInSeconds(obj)
            obj.delayCurtInSeconds = obj.settings.DelayInSeconds.curtailment;
        end
        
        function setDelayBattInSeconds(obj)
            obj.delayBattInSeconds = obj.settings.DelayInSeconds.battery;
        end
        
        function setDelayTimeSeries2ZoneInSeconds(obj)
            obj.delayTimeSeries2ZoneInSeconds = obj.settings.DelayInSeconds.Telecom.timeSeries2Zone;
        end
        
        function setDelayController2ZoneInSeconds(obj)
            obj.delayController2ZoneInSeconds = obj.settings.DelayInSeconds.Telecom.controller2Zone;
        end
        
        function setDelayZone2ControllerInSeconds(obj)
            obj.delayZone2ControllerInSeconds = obj.settings.DelayInSeconds.Telecom.zone2Controller;
        end
        
    end
    
    methods
        %% GETTER
        function value = getBusId(obj)
            value = obj.busId;
        end
        
        function value = getBranchFlowLimit(obj)
            value = obj.branchFlowLimit;
        end
        
        function value = getControlCycle(obj)
            value = obj.controlCycle;
        end
        
        function value = getTimeSeriesFilename(obj)
            value = obj.timeSeriesFilename;
        end
        
        function value = getStartGenInSeconds(obj)
            value = obj.startGenInSeconds;
        end
        
        function value = getBatteryConstantPowerReduction(obj)
            value = obj.batteryConstantPowerReduction;
        end
        
        function value = getDelayCurtInSeconds(obj)
            value = obj.delayCurtInSeconds;
        end
        
        function value = getDelayBattInSeconds(obj)
            value = obj.delayBattInSeconds;
        end
        
        function value = getDelayTimeSeries2ZoneInSeconds(obj)
            value = obj.delayTimeSeries2ZoneInSeconds;
        end
        
        function value = getDelayController2ZoneInSeconds(obj)
            value = obj.delayController2ZoneInSeconds;
        end
        
        function value = getDelayZone2ControllerInSeconds(obj)
            value = obj.delayZone2ControllerInSeconds;
        end
    
    end
    
end