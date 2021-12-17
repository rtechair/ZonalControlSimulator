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
            for i = 1:obj.numberOfZones
                zone = obj.zones{i};
                % the initialization is for both the modelEvolution and the
                % simulationEvolution
                zone.initializePowerAvailable();
                zone.initializePowerGeneration();
                
                % the update of the grid is done using simulationEvolution's state
                zone.updateGrid(obj.grid);
            end
            
            obj.grid.runPowerFlow();
            
            for i = 1:obj.numberOfZones
                zone = obj.zones{i};
                zone.updatePowerFlowModel(obj.grid);
                zone.updatePowerFlowSimulation(obj.grid);
                
                zone.updatePowerTransitModel(obj.grid);
                zone.updatePowerTransitSimulation(obj.grid);
                
                zone.updatePowerTransitModel(obj.grid);
                zone.updatePowerTransitSimulation(obj.grid);
                
                % do not compute disturbance transit initially, as there is not enough data
                
                zone.transmitDataZone2Controller();
                zone.saveModelState();
                zone.saveSimulationState();
                
                zone.prepareForNextStepModelResult();
                zone.prepareForNextStepSimulationResult();
                
                zone.dropOldestPowerTransitModel();
                zone.dropOldestPowerTransitSimulation();
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
                    else
                        zone.simulateNoControlCycle();
                    end
                    zone.updateGrid(obj.grid);
                end
                
                obj.grid.runPowerFlow();
                
                for i = 1:obj.numberOfZones
                    zone = obj.zones{i};
                    updateZone = zone.isItTimeToUpdate(time, step);
                    if updateZone
                        zone.updateModel(obj.grid);
                        zone.updateSimulation(obj.grid);
                        zone.transmitDataZone2Controller();
                        
                        zone.saveModelResult();
                        zone.saveSimulationResultOnControlCycle();
                        
                        zone.modelResult.prepareForNextStep();
                        zone.simulationResult.prepareForNextStep();
                    else
                        zone.updateSimulation(obj.grid);
                        zone.saveSimulationResultNoControl();
                        zone.simulationResult.prepareForNextStep();
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
        
        function plotZonesModelResult(obj)
            for i = 1 : obj.numberOfZones
                obj.zones{i}.plotModelResult(obj.grid);
            end
        end
        
        function plotZonesSimulationResult(obj)
            for i = 1 : obj.numberOfZones
                obj.zones{i}.plotSimulationResult(obj.grid);
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