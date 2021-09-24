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

classdef TimeSeries < handle
   
    properties (SetAccess = protected)
        windChargingRate
        ProfilePowerAvailable
        ProfileDisturbancePowerAvailable
        step
    end
    
    properties (SetAccess = immutable)
        startGen
        numberOfIterations
        maxPowerGeneration
        numberOfGen
    end
    
    methods
        
        function obj = TimeSeries(filenameWindChargingRate, ...
                startGenInSeconds, controlCycle, ...
                durationSimulation, maxPowerGeneration, numberOfGen)
            obj.startGen = startGenInSeconds;
            obj.numberOfIterations = floor(durationSimulation / controlCycle);
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.numberOfGen = numberOfGen;
            
            % step starts at 0 because of initialization, later updated to 1 to start the simulation
            obj.step = 0;
            
            obj.setWindChargingRate(filenameWindChargingRate);
            obj.checkInitialIterationCorrectness(controlCycle)
            
            obj.setProfilePowerAvailable(controlCycle);
            obj.setProfileDisturbancePowerAvailable();
        end
        
        function value = getInitialPowerAvailable(obj)
            value = obj.ProfilePowerAvailable(:,1);
        end
        
        function object = getDisturbancePowerAvailable(obj)
            % The telecommunication needs an object, not a matrix of the
            % value. Thus, the method returns an object wrapping the value
            % of the disturbance power available
            value = obj.getDisturbancePowerAvailableValue();
            object = DisturbancePowerAvailable(value);
        end
        
       function prepareForNextStep(obj)
            obj.step = obj.step + 1;
       end 
        
    end
    
    methods (Access = protected)
       
        
        function setWindChargingRate(obj, filenameWindChargingRate)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           obj.windChargingRate = table2array(readtable(filenameWindChargingRate))';
        end
        
       function setProfilePowerAvailable(obj, controlCycle)
           genWindRate = zeros(obj.numberOfGen, obj.numberOfIterations + 1);
           for i = 1:obj.numberOfGen
               start = obj.startGen(i);
               last = start + obj.numberOfIterations*controlCycle;
               range = start : controlCycle : last;
               genWindRate(i,:) = obj.windChargingRate(1, range);
           end
           obj.ProfilePowerAvailable = obj.maxPowerGeneration .* genWindRate;
       end
       
       function setProfileDisturbancePowerAvailable(obj)
           obj.ProfileDisturbancePowerAvailable = zeros(obj.numberOfGen, obj.numberOfIterations);
           for time = 1:obj.numberOfIterations
               obj.ProfileDisturbancePowerAvailable(:,time) = obj.ProfilePowerAvailable(:, time+1) ...
                   - obj.ProfilePowerAvailable(:, time);
           end
       end
       
       function checkInitialIterationCorrectness(obj, controlCycle)
           sampleDuration = size(obj.windChargingRate,2);
           % the following '-1' is due to the initialization step
           maxStartingTimeForGen = sampleDuration - 1 - controlCycle*obj.numberOfIterations;
           isThereAnyStartOfGenTooLate = any(obj.startGen > maxStartingTimeForGen);
           if isThereAnyStartOfGenTooLate
                obj.errorStartingIterationExceedsMax(maxStartingTimeForGen)
           end
       end
       
       function errorStartingIterationExceedsMax(obj, upperBound)
           message = ['the starting iterations chosen for wind time series of the generators exceeds ' ...
            'the max discrete range, check in the JSON file, that the selected starts for generators are < ' ...
            num2str(upperBound) ', in the load data zone script'];
        error(message)
       end
       
       function value = getDisturbancePowerAvailableValue(obj)
           value = obj.ProfileDisturbancePowerAvailable(:,obj.step);
       end
       
    end
    
end