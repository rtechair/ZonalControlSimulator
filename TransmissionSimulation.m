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

classdef TransmissionSimulation < handle
% Act as the global simulator of transmission

    properties (SetAccess = protected)
       simulationSetting
       
       grid
       numberOfZones
       zones
    end
   
    methods
        function obj = TransmissionSimulation(simulationFilename)
            %% set elements
            obj.simulationSetting = SimulationSetting(simulationFilename);
            obj.numberOfZones = obj.simulationSetting.getNumberOfZones();
            
            obj.setGrid();
            obj.setZones();
            
            obj.initialize();
        end
    end
    
    methods (Access = protected)
        %% CONSTRUCTOR METHODS
        function setGrid(obj)
            basecase = obj.simulationSetting.getBasecase();
            obj.grid = ElectricalGrid(basecase);
        end
        
        function setZones(obj)
            obj.zones = cell(obj.numberOfZones,1);
            window = obj.simulationSetting.getWindow();
            duration = obj.simulationSetting.getDuration();
            zoneNames = obj.simulationSetting.getZoneName();
            for i = 1:obj.numberOfZones
                name = zoneNames{i};
                obj.zones{i} = Zone(name, obj.grid, window, duration);
            end
        end
        
        function initialize(obj)
            % Beware the following methods apply their actions to all the
            % zones, no matter their control cycle. They should not be used during the simulation,
            % as the zones might not share the same control cyle.
            obj.initializeZonesPowerAvailable();
            obj.initializeZonesPowerGeneration();
            
            obj.updateGridForAllZones();
            
            obj.grid.runPowerFlow();
            
            obj.updateZonesPowerFlow();
            obj.updateZonesPowerTransit();
            
            % do not compute disturbance transit initially, as there is not enough data
            obj.transmitDataZone2Controller();
            obj.saveZonesState();
            
            obj.prepareZonesForFirstStep();
            obj.dropZonesOldestPowerTransit();
        end
        
        function initializeZonesPowerAvailable(obj)
            for i = 1:obj.numberOfZones
               obj.zones{i}.initializePowerAvailable();
            end
        end
        
        function initializeZonesPowerGeneration(obj)
           for i = 1:obj.numberOfZones
              obj.zones{i}.initializePowerGeneration();
           end
        end
        
        function updateGridForAllZones(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.updateGrid(obj.grid);
            end
        end
        
        function updateZonesPowerFlow(obj)
           for i = 1:obj.numberOfZones
               obj.zones{i}.updatePowerFlow(obj.grid);
           end
        end
        
        function updateZonesPowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.updatePowerTransit(obj.grid);
            end
        end
        
        function saveZonesState(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.saveState();
            end
        end
        
        function transmitDataZone2Controller(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.transmitDataZone2Controller();
            end
        end
        
        function prepareZonesForNextStep(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.prepareForNextStep();
            end
        end
        
        function prepareZonesForFirstStep(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.prepareResultForNextStep();
            end
        end
        
        function dropZonesOldestPowerTransit(obj)
            for i= 1:obj.numberOfZones
                obj.zones{i}.dropOldestPowerTransit();
            end
        end
    end
    
    methods
        %% SIMULATION
        function runSimulation(obj)
            step = obj.simulationSetting.getWindow();
            start = step;
            duration = obj.simulationSetting.getDuration();
            
            for time = start:step:duration
                for i = 1:obj.numberOfZones
                    zone = obj.zones{i};
                    updateZone = zone.isItTimeToUpdate(time, step);
                    if updateZone
                        zone.simulate();
                        zone.updateGrid(obj.grid);
                    end
                end
                
                obj.grid.runPowerFlow();
                
                for i = 1:obj.numberOfZones
                    zone = obj.zones{i};
                    updateZone = zone.isItTimeToUpdate(time, step);
                    if updateZone
                        zone.update(obj.grid);
                        zone.saveResult();
                        zone.prepareForNextStep();
                        zone.dropOldestPowerTransit();
                    end
                end
            end
        end
        
        %% PLOT
        function plotZonesTopology(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.plotTopology(obj.grid);
            end
        end
        
        function plotZonesResult(obj)
            for i = 1 : obj.numberOfZones
                obj.zones{i}.plotResult(obj.grid);
            end
        end
        
        %% GETTER
        function value = getNumberOfZones(obj)
            value = obj.numberOfZones;
        end
        
        function cell = getZones(obj)
            cell = obj.zones;
        end
    end
end