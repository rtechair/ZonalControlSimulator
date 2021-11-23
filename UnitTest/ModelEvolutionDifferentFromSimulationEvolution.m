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
classdef ModelEvolutionDifferentFromSimulationEvolution < matlab.unittest.TestCase
    
    properties
        transmissionSim
        stoppingTime
    end
    
    methods(TestClassSetup)
        function setTransmissionSimulation(testCase)
            testCase.transmissionSim = TransmissionSimulation('simulation.json');
        end
        
        function setTime(testCase)
            testCase.stoppingTime = 10;
        end
    end
    
    methods(Test)
        function test1(testCase)
            % the following code is adapted from
            % TransmissionSimulation>runSimulation
            trans = testCase.transmissionSim;
            step = trans.simulationSetting.getWindow();
            start = step;
            duration = trans.simulationSetting.getDuration();
            
            for time = start:step:duration
                for i = 1:trans.numberOfZones
                    zone = trans.zones{i};
                    updateZone = zone.isItTimeToUpdate(time, step);
                    if updateZone
                        zone.simulate();
                    else
                        zone.simulateNoControlCycle();
                    end
                    zone.updateGrid(trans.grid);
                end
                
                trans.grid.runPowerFlow();
                
                for i = 1:trans.numberOfZones
                    zone = trans.zones{i};
                    updateZone = zone.isItTimeToUpdate(time, step);
                    if updateZone
                        zone.update(trans.grid);
                        zone.saveResult();
                        zone.result.prepareForNextStep();
                    else
                        zone.updateNoControlCycle(trans.grid);
                    end
                end
                
                % check at every control cycle, model evolution and
                % simulation evolution have the same generated powers.
                zone1 = trans.zones{1};
                controlCycle = zone1.setting.getControlCycleInSeconds();
                if rem(time, controlCycle)==0
                    zone1 = trans.zones{1};
                    model1 = zone1.getModelEvolution();
                    simulation1 = zone1.getSimulationEvolution();
                    stateModel1 = model1.getState();
                    stateSim1 = simulation1.getState();

                    PGmodel = stateModel1.getPowerGeneration();
                    PGsim = stateSim1.getPowerGeneration();
                    testCase.verifyEqual(PGmodel, PGsim, "AbsTol",10^(-3));
                end
            end
        end
    end
    
    
    
end