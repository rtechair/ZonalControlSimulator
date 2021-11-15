%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

classdef ZoneSetting < handle
% Read and interpret the JSON file into an object to get the parameters of the zone.
% when the configuration of the JSON file is modified, the setters
% need to be modify as well to depict the changes.
    
    properties (SetAccess = protected)
        % All parameters from the JSON file are in the property 'settings'. The Setter methods
        % extract the parameters into the other properties.
        settings
        
        busId
        branchFlowLimit
        controlCycleInSeconds % i.e. the time step of the zone
        
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
            obj.setcontrolCycleInSeconds();
            
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
        
        function setcontrolCycleInSeconds(obj)
            obj.controlCycleInSeconds = obj.settings.controlCycleInSeconds;
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
        
        function value = getControlCycleInSeconds(obj)
            value = obj.controlCycleInSeconds;
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