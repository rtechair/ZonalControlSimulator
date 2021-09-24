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

classdef StateOfZone < handle
    
    properties (SetAccess = protected)
       powerFlow        % Fij
       powerCurtailment % PC
       powerBattery     % PB, if PB > 0, the battery is used. if PB < 0, the battery is recharged.
       energyBattery    % EB
       powerGeneration  % PG
       powerAvailable   % PA
    end
    
    methods
        function obj = StateOfZone(numberOfBranches, numberOfGenerators, numberOfBatteries)
            obj.powerFlow = zeros(numberOfBranches, 1);
            obj.powerCurtailment = zeros(numberOfGenerators, 1);
            obj.powerBattery = zeros(numberOfBatteries, 1);
            obj.energyBattery = zeros(numberOfBatteries, 1);
            obj.powerGeneration = zeros(numberOfGenerators, 1);
            obj.powerAvailable = zeros(numberOfGenerators, 1);
        end
        
        function value = getPowerFlow(obj)
            value = obj.powerFlow;
        end
        
        function value = getPowerCurtailment(obj)
            value = obj.powerCurtailment;
        end
        
        function value = getPowerBattery(obj)
            value = obj.powerBattery;
        end
        
        function value = getEnergyBattery(obj)
            value = obj.energyBattery;
        end
        
        function value = getPowerGeneration(obj)
            value = obj.powerGeneration;
        end
        
        function value = getPowerAvailable(obj)
            value = obj.powerAvailable;
        end
        
        function setPowerFlow(obj, value)
            obj.powerFlow = value;
        end
        
        function setPowerCurtailment(obj, value)
            obj.powerCurtailment = value;
        end
        
        function setPowerBattery(obj, value)
            obj.powerBattery = value;
        end
        
        function setEnergyBattery(obj, value)
            obj.energyBattery = value;
        end
        
        function setPowerGeneration(obj, value)
            obj.powerGeneration = value;
        end
        
        function setPowerAvailable(obj, value)
            obj.powerAvailable = value;
        end
        
    end
end