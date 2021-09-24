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

classdef SimulationSetting < handle
% Read and interpret the JSON file into an object to get the parameters of the simulation.
% when the configuration of the JSON file is modified, the setters
% need to be modify as well to depict the changes.

    properties (SetAccess = protected)
        % All parameters from the JSON file are in the property 'settings'. The Setter methods
        % extract the parameters into the other properties.
        settings
        
        basecase
        duration
        window % i.e. the time step of the simulation
        zoneName
        numberOfZones
    end
    
    methods
        
        function obj = SimulationSetting(simulationFilename)
            obj.settings = decodeJsonFile(simulationFilename);
            
            obj.setBasecase();
            obj.setDuration();
            obj.setWindow();
            obj.setZoneName();
            obj.setNumberOfZones();
        end
        
        %% SETTER
        function setBasecase(obj)
            obj.basecase = obj.settings.basecase;
        end
        
        function setDuration(obj)
            obj.duration = obj.settings.durationInSeconds;
        end
        
        function setWindow(obj)
            obj.window = obj.settings.windowInSeconds;
        end
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.zoneName = struct2cell(obj.settings.Zone);
        end
        
        function setNumberOfZones(obj)
            obj.numberOfZones = size(obj.zoneName,1);
        end
        
        %% GETTER
        function string = getBasecase(obj)
            string = obj.basecase;
        end
        
        function value = getDuration(obj)
            value = obj.duration;
        end
        
        function value = getWindow(obj)
            value = obj.window;
        end
        
        function cell = getZoneName(obj)
            cell = obj.zoneName;
        end
        
        function value = getNumberOfZones(obj)
            value = obj.numberOfZones;
        end
    end
end