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
    end
    
    methods(TestClassSetup)
        function setTransmissionSimulation(testCase)
            testCase.transmissionSim = TransmissionSimulation('simulation.json');
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
                % simulation evolution's properties have the same values.
                zone1 = trans.zones{1};
                isZoneToUpdate = zone1.isItTimeToUpdate(time, step);
                % controlCycle = zone1.setting.getControlCycleInSeconds();
                if isZoneToUpdate
                %if rem(time, controlCycle)==0
                    zone1 = trans.zones{1};
                    model1 = zone1.getModelEvolution();
                    simulation1 = zone1.getSimulationEvolution();
                    stateModel1 = model1.getState();
                    stateSim1 = simulation1.getState();
                    
                    FLOWmodel = stateModel1.getPowerFlow();
                    FLOWsim = stateSim1.getPowerFlow();
                    
                    PGmodel = stateModel1.getPowerGeneration();
                    PGsim = stateSim1.getPowerGeneration();
                    
                    PCmodel = stateModel1.getPowerCurtailment();
                    PCsim = stateSim1.getPowerCurtailment();
                    
                    PBmodel = stateModel1.getPowerBattery();
                    PBsim = stateSim1.getPowerBattery();
                    
                    EBmodel = stateModel1.getEnergyBattery();
                    EBsim = stateSim1.getEnergyBattery();
                    
                    PAmodel = stateModel1.getPowerAvailable();
                    PAsim = stateSim1.getPowerAvailable();
                    
                    deltaPAmodel = model1.getDisturbancePowerAvailable();
                    deltaPAsim = simulation1.getDisturbancePowerAvailable();
                    
                    deltaPTmodel = model1.getDisturbancePowerTransit();
                    deltaPTsim = simulation1.getDisturbancePowerTransit();
                    
                    aa = 5;
                    
                    testCase.verifyEqual(FLOWmodel, FLOWsim, "AbsTol",10^(-5));
                    testCase.verifyEqual(PGmodel, PGsim, "AbsTol",10^(-5));
                    testCase.verifyEqual(PCmodel, PCsim, "AbsTol",10^(-5));
                    testCase.verifyEqual(PBmodel, PBsim, "AbsTol",10^(-5));
                    testCase.verifyEqual(deltaPTmodel, deltaPTsim, "AbsTol",10^(-5));
                    testCase.verifyEqual(PAmodel, PAsim, "AbsTol",10^(-5));
                    
                    
                    %{
                    
                    testCase.verifyEqual(EBmodel, EBsim, "AbsTol",10^(-5));
                    
                    testCase.verifyEqual(deltaPAmodel, deltaPAsim, "AbsTol",10^(-5));
                    
                    %}
                end
            end
        end
    end
    
    
    
end