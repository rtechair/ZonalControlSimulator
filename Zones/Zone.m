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

classdef Zone < handle
% Column vectors are used instead of row vectors, e.g.
% busId, branchIdx, modelEvolution's properties, etc.
% The reason is for consistency with column vectors obtained from Matpower
% functions [1].
% Hence, rows corresponds to elements, such as buses, branches, generators and
% batteries, while columns corresponds to time steps.
%  
% [1] https://matpower.org/docs/ref/


    properties (SetAccess = protected)
       name
       setting
       
       delayInIterations
       topology
       
       modelEvolution
       simulationEvolution
       
       telecomZone2Controller
       telecomController2Zone
       
       controllerSetting
       controller
       
       modelTimeSeries
       simulationTimeSeries
       
       result
    end
    
    methods
        function obj = Zone(name, electricalGrid, simulationWindow, duration)
            arguments
                name char
                electricalGrid
                simulationWindow int64
                duration int64
            end
            obj.name = name;
            obj.setSetting();
            obj.setDelayInIterations();
            obj.setTopology(electricalGrid);
            
            obj.setModelTimeSeries(duration);
            obj.setSimulationTimeSeries(simulationWindow, duration);
            
            obj.setModelEvolution();
            obj.setSimulationEvolution();
            
            obj.setTelecom();
            obj.setResult(duration);
            
            isControllerMPC = true;
            
            if isControllerMPC
                obj.setModelPredictiveController();
            else
                obj.setControllerSetting();
                obj.setController();
            end
        end
        
        function setSetting(obj)
            filename = obj.getFilename();
            obj.setting = ZoneSetting(filename);
        end
        
        function zoneFilename = getFilename(obj)
            zoneFilename = ['zone' obj.name '.json'];
        end
        
        function setDelayInIterations(obj)
            obj.delayInIterations = buildDelayInIterations(obj.setting);
        end
        
        function setTopology(obj, electricalGrid)
           busId = obj.setting.getBusId();
           obj.topology = ZoneTopology(obj.name, busId, electricalGrid);
        end
        
        function setModelTimeSeries(obj, duration)
            controlCycle = obj.setting.getControlCycleInSeconds();
            obj.modelTimeSeries = buildTimeSeries(obj.setting, obj.topology, controlCycle, duration);
        end
        
        function setSimulationTimeSeries(obj, window, duration)
            obj.simulationTimeSeries = buildTimeSeries(obj.setting, obj.topology, window, duration);
        end
        
        function setModelEvolution(obj)
            obj.modelEvolution = buildModelEvolution(obj.setting, obj.topology, obj.delayInIterations);
        end
        
        function setSimulationEvolution(obj)
            obj.simulationEvolution = buildModelEvolution(obj.setting, obj.topology, obj.delayInIterations);
        end
        
        function setTelecom(obj)
            [obj.telecomController2Zone, obj.telecomZone2Controller] = ...
                buildTelecom(obj.topology, obj.delayInIterations);
        end
        
        function setResult(obj, duration)
            obj.result = buildResult(obj.setting, obj.topology, obj.delayInIterations, duration, ...
                obj.name);
        end
        
        % WARNING: the following function is for the limiter,
        % it can not be used for other types of controllers.
        % Hence, it will be later modified TODO
        function limiterFilename = getLimiterFilename(obj)
            limiterFilename = ['limiter' obj.name '.json'];
        end
        
        function setControllerSetting(obj)
           obj.controllerSetting = decodeJsonFile(obj.getLimiterFilename());
        end
        
        % WARNING: actually this function sets a limiter as the controller
        % TODO: handle the case when it is not the limiter
        function setController(obj)
            branchFlowLimit = obj.setting.getBranchFlowLimit();
            numberOfBattOn = obj.topology.getNumberOfBattOn();
            increasingEchelon = obj.controllerSetting.IncreaseCurtPercentEchelon;
            decreasingEchelon = obj.controllerSetting.DecreaseCurtPercentEchelon;
            lowerThreshold = obj.controllerSetting.LowerThresholdPercent;
            upperThreshold = obj.controllerSetting.UpperThresholdPercent;
            
            delayCurt = obj.delayInIterations.getDelayCurt();
            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            
            obj.controller = Limiter(branchFlowLimit, numberOfBattOn, ...
                increasingEchelon, decreasingEchelon, lowerThreshold, upperThreshold, ...
                delayCurt, maxPowerGeneration);
        end
        
        % WARMING: this is an attempt at an MPC
        function setModelPredictiveController(obj)
            delayCurt = obj.delayInIterations.getDelayCurt();
            delayBatt = obj.delayInIterations.getDelayBatt();
            delayTelecom = obj.delayInIterations.getDelayController2Zone();
            controlCycleInSeconds = obj.setting.getControlCycleInSeconds();
            
            predictionHorizon = 10;
            numberOfScenarios = 1;
            
            obj.controller = MpcWithUncertainty(obj.name, delayCurt, delayBatt, delayTelecom, ...
                controlCycleInSeconds, predictionHorizon, numberOfScenarios);
            
            amplifierQ_ep1 = 10^7;
            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            minPowerBattery = obj.topology.getMinPowerBattery();
            maxPowerBattery = obj.topology.getMaxPowerBattery();
            maxEnergyBattery = 800;
            flowLimit = obj.setting.getBranchFlowLimit();
            maxEpsilon = 0.05;
            
            obj.controller.setOtherElements(amplifierQ_ep1, maxPowerGeneration, ...
                minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit, maxEpsilon);
        end
        
        function initializePowerAvailable(obj)
            obj.simulationEvolution.setInitialPowerAvailable(obj.simulationTimeSeries);
            obj.modelEvolution.setInitialPowerAvailable(obj.modelTimeSeries);
        end
        
        function initializePowerGeneration(obj)
            obj.simulationEvolution.setInitialPowerGeneration();
            obj.modelEvolution.setInitialPowerGeneration();
        end
        
        function updatePowerFlowModel(obj, electricalGrid)
            branchIdx = obj.topology.getBranchIdx();
            powerFlow = electricalGrid.getPowerFlow(branchIdx);
            obj.modelEvolution.setPowerFlow(powerFlow);
        end
        
        function updatePowerFlowSimulation(obj, electricalGrid)
            branchIdx = obj.topology.getBranchIdx();
            powerFlow = electricalGrid.getPowerFlow(branchIdx);
            obj.simulationEvolution.setPowerFlow(powerFlow);
        end
        
        function updatePowerTransitModel(obj, electricalGrid)
            busId = obj.topology.getBusId();
            branchBorderIdx = obj.topology.getBranchBorderIdx();
            obj.modelEvolution.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
        end
        
        function updatePowerTransitSimulation(obj, electricalGrid)
            busId = obj.topology.getBusId();
            branchBorderIdx = obj.topology.getBranchBorderIdx();
            obj.simulationEvolution.updatePowerTransit(electricalGrid, busId, branchBorderIdx);
        end
        
        function updateGrid(obj,electricalGrid)
            obj.updateGridGeneration(electricalGrid);
            obj.updateGridBattInjection(electricalGrid);
        end
        
        function updateGridGeneration(obj, electricalGrid)
            genOnIdx = obj.topology.getGenOnIdx();
            powerGeneration = obj.simulationEvolution.getPowerGeneration();
            electricalGrid.updateGeneration(genOnIdx, powerGeneration);
        end
        
        function updateGridBattInjection(obj, electricalGrid)
            battOnIdx = obj.topology.getBattOnIdx();
            powerBattery = obj.simulationEvolution.getPowerBattery();
            electricalGrid.updateBattInjection(battOnIdx, powerBattery);
        end
        
        function transmitDataController2Zone(obj)
            control = obj.controller.getControl();
            obj.telecomController2Zone.receiveControl(control);
            sentControl = obj.telecomController2Zone.sendControl();
            obj.modelEvolution.receiveControl(sentControl);
            obj.simulationEvolution.receiveControl(sentControl);
        end
        
        function transmitDataTimeSeries2Zone(obj)
            disturbancePowerAvailable = obj.modelTimeSeries.getDisturbancePowerAvailable();
            obj.modelEvolution.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
        end
        
        function transmitDataTimeSeries2Model(obj)
            obj.modelTimeSeries.sendDisturbancePowerAvailable(obj.modelEvolution);
        end
        
        function transmitDataTimeSeries2Simulation(obj)
            obj.simulationTimeSeries.sendDisturbancePowerAvailable(obj.simulationEvolution);
        end
        
        function transmitDataZone2Controller(obj)
            state = obj.simulationEvolution.getState();
            disturbancePowerTransit = obj.simulationEvolution.getDisturbancePowerTransit();
            disturbancePowerAvailable = obj.modelEvolution.getDisturbancePowerAvailable();
            
            obj.telecomZone2Controller.receiveState(state);
            obj.telecomZone2Controller.receiveDisturbancePowerTransit(disturbancePowerTransit);
            obj.telecomZone2Controller.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
            
            obj.telecomZone2Controller.sendState(obj.controller);
            obj.telecomZone2Controller.sendDisturbancePowerTransit(obj.controller);
            obj.telecomZone2Controller.sendDisturbancePowerAvailable(obj.controller);
        end
        
        function prepareForNextStepSimulation(obj)
            obj.simulationTimeSeries.goToNextStep();
        end
        
        function prepareResultForNextStep(obj)
            obj.result.prepareForNextStep();
        end
        
        function dropOldestPowerTransit(obj)
            % FIXME: temporary method, later deleted
            obj.modelEvolution.dropOldestPowerTransit();
            obj.simulationEvolution.dropOldestPowerTransit();
        end
        
        function simulateBothCases(obj, currentTime, timeStep)
            % FIXME: maybe delete this method, if TransmissionSimulation
            % does this
            timeForControlCycle = isItTimeToUpdate(currentTime, timeStep)
            if timeForControlCycle
                obj.simulate();
            else
                obj.simulateNoControlCycle();
            end
        end
        
        function boolean = isItTimeToUpdate(obj, currentTime, timeStep)
            previousTime = currentTime - timeStep;
            controlCycle = obj.setting.getControlCycleInSeconds();
            
            % Iterations are defined by the euclidian division:
            % time = iterations * controlCycle + remainder, with 0 <= remainder < controlCycle
            previousIteration = obj.getEuclideanQuotient(previousTime, controlCycle);
            currentIteration = obj.getEuclideanQuotient(currentTime, controlCycle);
            
            boolean = currentIteration > previousIteration;
        end
        
        % This method does not use the object, it is here to be close to its caller method
        function quotient = getEuclideanQuotient(obj, dividend, divisor)
            % dividend = divisor * quotient + remainder, with 0 <= remainder < quotient
            quotient = floor(dividend / divisor);
        end
        
        function simulate(obj)
            obj.controller.computeControl();
            
            obj.transmitDataController2Zone();
            
            obj.modelEvolution.applyControlFromController();
            obj.simulationEvolution.applyControlFromController();
            
            obj.transmitDataTimeSeries2Model();
            obj.transmitDataTimeSeries2Simulation();
            
            obj.modelEvolution.computeDisturbancePowerGeneration();
            obj.modelEvolution.updateState();
            
            obj.simulationEvolution.computeDisturbancePowerGeneration();
            obj.simulationEvolution.updateState();
        end
        
        function simulateNoControlCycle(obj)
            obj.simulationEvolution.applyNoControl();
            obj.transmitDataTimeSeries2Simulation();
            obj.simulationEvolution.computeDisturbancePowerGeneration();
            obj.simulationEvolution.updateState();
        end
        
        function update(obj, electricalGrid)
            obj.updatePowerFlowModel(electricalGrid);
            obj.updatePowerFlowSimulation(electricalGrid);
            
            obj.updatePowerTransitModel(electricalGrid);
            obj.updatePowerTransitSimulation(electricalGrid);
            
            obj.modelEvolution.updateDisturbancePowerTransit();
            obj.simulationEvolution.updateDisturbancePowerTransit();
            
            obj.modelEvolution.dropOldestPowerTransit();
            obj.simulationEvolution.dropOldestPowerTransit();
            
            obj.transmitDataZone2Controller();
        end
        
        function updateNoControlCycle(obj, electricalGrid)
            obj.updatePowerFlowSimulation(electricalGrid);
        end
        
        function saveResult(obj)
            obj.modelEvolution.saveState(obj.result);
            obj.controller.saveControl(obj.result);
            obj.modelEvolution.saveDisturbance(obj.result);
        end
        
        function saveState(obj)
            % used in the initialization of TransmissionSimulation
            obj.modelEvolution.saveState(obj.result);
        end
        
        function plotTopology(obj, electricalGrid)
            obj.topology.plotLabeledGraph(electricalGrid);
        end
        
        function plotResult(obj, electricalGrid)
            obj.result.plotAbsoluteFlowBranch(electricalGrid);
            obj.result.plotControlAndDisturbanceGen(electricalGrid);
            obj.result.plotStateGen(electricalGrid);
            obj.result.plotDisturbanceTransit();
            obj.result.plotStateAndControlBattery(electricalGrid);
        end
        
        %% GETTER
        function object = getModelEvolution(obj)
            object = obj.modelEvolution;
        end
    end
end