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
       
       modelResult
       simulationResult
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
            obj.setResult(simulationWindow, duration);
            
            isControllerApproximateLinearModel = false;
            isControllerLimiter = false;
            isControllerMixedLogicalModel = true;
            isMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal = false;
            isMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA = false;

            if isControllerApproximateLinearModel
                obj.setApproximateLinearMPC();
            elseif isControllerLimiter
                obj.setControllerLimiterSetting();
                obj.setControllerLimiter();
            elseif isControllerMixedLogicalModel
                obj.setMixedLogicalDynamicalModelPredictiveController();
            elseif isMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal
                obj.setMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal();
            elseif isMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA
                obj.setMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA();
            else
                except = MException('The choice of controller is incorrect, ',...
                    'one of the controller must be selected in Zone.m');
                throw(except)
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
        
        function setResult(obj, simulationWindow, duration)
            obj.modelResult = buildModelResult(obj.setting, obj.topology, obj.delayInIterations, duration, ...
                obj.name);
            obj.simulationResult = buildSimulationResult(obj.setting, obj.topology, obj.delayInIterations, duration, ...
                obj.name, simulationWindow);
        end

        function limiterFilename = getLimiterFilename(obj)
            limiterFilename = ['limiter' obj.name '.json'];
        end
        
        function setControllerLimiterSetting(obj)
           obj.controllerSetting = decodeJsonFile(obj.getLimiterFilename());
        end
        
        function setControllerLimiter(obj)
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
        
        function setApproximateLinearMPC(obj)
            delayCurt = obj.delayInIterations.getDelayCurt();
            delayBatt = obj.delayInIterations.getDelayBatt();
            delayTelecom = obj.delayInIterations.getDelayController2Zone();
            controlCycleInSeconds = obj.setting.getControlCycleInSeconds();
            % TODO: add to mpc.json the following info
            horizonInSeconds = 50;
            numberOfScenarios = 1;
            
            obj.controller = MpcWithUncertainty(obj.name, delayCurt, delayBatt, delayTelecom, ...
                controlCycleInSeconds, horizonInSeconds, numberOfScenarios);
            
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

        function setApproximateLinearMPC_PAunknown_DeltaPCreal(obj)
            delayCurt = obj.delayInIterations.getDelayCurt();
            delayBatt = obj.delayInIterations.getDelayBatt();
            delayTelecom = obj.delayInIterations.getDelayController2Zone();
            controlCycleInSeconds = obj.setting.getControlCycleInSeconds();
            % TODO: add to mpc.json the following info
            horizonInSeconds = 50;
            numberOfScenarios = 1;
            
            obj.controller = ApproximateLinearMPC_PAunknown_DeltaPCreal(obj.name, delayCurt, delayBatt, delayTelecom, ...
                controlCycleInSeconds, horizonInSeconds, numberOfScenarios);
            
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
        
        function setMixedLogicalDynamicalModelPredictiveController(obj)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = obj.setting.getBusId();
            batteryCoef = obj.setting.getBatteryConstantPowerReduction();
            timestep = obj.setting.controlCycleInSeconds();

            delayCurt = ceil(obj.setting.getDelayCurtInSeconds() / timestep);
            delayBatt = ceil(obj.setting.getDelayBattInSeconds() / timestep);
            delayTelecom = ceil(obj.setting.getDelayController2ZoneInSeconds() / timestep);
            % TODO: add to the json file the information about hte horizon
            horizonInSeconds = 50;
            horizonInIterations = ceil( horizonInSeconds / timestep);

            numberOfBuses = obj.topology.getNumberOfBuses();
            numberOfBranches = obj.topology.getNumberOfBranches();
            numberOfGen = obj.topology.getNumberOfGenOn();
            numberOfBatt = obj.topology.getNumberOfBattOn();

            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);

            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, delayCurt, delayBatt);

            operatorStateExtended = model.getOperatorStateExtended();
            operatorControlExtended = model.getOperatorControlExtended();
            operatorNextPowerGenerationExtended = model.getOperatorNextPowerGenerationExtended();
            operatorDisturbanceExtended = model.getOperatorDisturbanceExtended();

            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            minPowerBattery = obj.topology.getMinPowerBattery();
            maxPowerBattery = obj.topology.getMaxPowerBattery();
            maxEnergyBattery = 10000; %arbitrary, TODO: write it in the json of the zone
            flowLimit = obj.setting.getBranchFlowLimit();
            
            obj.controller = MixedLogicalDynamicalModelPredictiveController(delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit);
        end

        function setMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal(obj)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = obj.setting.getBusId();
            batteryCoef = obj.setting.getBatteryConstantPowerReduction();
            timestep = obj.setting.controlCycleInSeconds();

            delayCurt = ceil(obj.setting.getDelayCurtInSeconds() / timestep);
            delayBatt = ceil(obj.setting.getDelayBattInSeconds() / timestep);
            delayTelecom = ceil(obj.setting.getDelayController2ZoneInSeconds() / timestep);
            % TODO: add to the json file the information about hte horizon
            horizonInSeconds = 50;
            horizonInIterations = ceil( horizonInSeconds / timestep);

            numberOfBuses = obj.topology.getNumberOfBuses();
            numberOfBranches = obj.topology.getNumberOfBranches();
            numberOfGen = obj.topology.getNumberOfGenOn();
            numberOfBatt = obj.topology.getNumberOfBattOn();

            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);

            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, delayCurt, delayBatt);

            operatorStateExtended = model.getOperatorStateExtended();
            operatorControlExtended = model.getOperatorControlExtended();
            operatorNextPowerGenerationExtended = model.getOperatorNextPowerGenerationExtended();
            operatorDisturbanceExtended = model.getOperatorDisturbanceExtended();

            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            minPowerBattery = obj.topology.getMinPowerBattery();
            maxPowerBattery = obj.topology.getMaxPowerBattery();
            maxEnergyBattery = 10000; %arbitrary, TODO: write it in the json of the zone
            flowLimit = obj.setting.getBranchFlowLimit();

            obj.controller = MixedLogicalDynamicalMPC_PAunknown_DeltaPCreal(delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit);
        end

        function setMixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA(obj)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = obj.setting.getBusId();
            batteryCoef = obj.setting.getBatteryConstantPowerReduction();
            timestep = obj.setting.controlCycleInSeconds();

            delayCurt = ceil(obj.setting.getDelayCurtInSeconds() / timestep);
            delayBatt = ceil(obj.setting.getDelayBattInSeconds() / timestep);
            delayTelecom = ceil(obj.setting.getDelayController2ZoneInSeconds() / timestep);
            % TODO: add to the json file the information about hte horizon
            horizonInSeconds = 50;
            horizonInIterations = ceil( horizonInSeconds / timestep);

            numberOfBuses = obj.topology.getNumberOfBuses();
            numberOfBranches = obj.topology.getNumberOfBranches();
            numberOfGen = obj.topology.getNumberOfGenOn();
            numberOfBatt = obj.topology.getNumberOfBattOn();

            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);

            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, delayCurt, delayBatt);

            operatorStateExtended = model.getOperatorStateExtended();
            operatorControlExtended = model.getOperatorControlExtended();
            operatorNextPowerGenerationExtended = model.getOperatorNextPowerGenerationExtended();
            operatorDisturbanceExtended = model.getOperatorDisturbanceExtended();

            maxPowerGeneration = obj.topology.getMaxPowerGeneration();
            minPowerBattery = obj.topology.getMinPowerBattery();
            maxPowerBattery = obj.topology.getMaxPowerBattery();
            maxEnergyBattery = 10000; %arbitrary, TODO: write it in the json of the zone
            flowLimit = obj.setting.getBranchFlowLimit();

            coefficientDeltaPA = 0.25;

            obj.controller = MixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA(delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit, coefficientDeltaPA);
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
            control = copy(obj.controller.getControl());
            obj.telecomController2Zone.receiveControl(control);
            sentControl = copy(obj.telecomController2Zone.sendControl());
            obj.modelEvolution.receiveControl(sentControl);
            obj.simulationEvolution.receiveControl(sentControl);
        end
        
        function transmitDataTimeSeries2Model(obj)
            obj.modelTimeSeries.sendDisturbancePowerAvailable(obj.modelEvolution);
        end
        
        function transmitDataTimeSeries2Simulation(obj)
            obj.simulationTimeSeries.sendDisturbancePowerAvailable(obj.simulationEvolution);
        end
        
        function transmitDataZone2Controller(obj)
            state = copy(obj.simulationEvolution.getState());
            disturbancePowerTransit = obj.modelEvolution.getDisturbancePowerTransit();
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
        
        function prepareForNextStepModelResult(obj)
            obj.modelResult.prepareForNextStep();
        end
        
        function prepareForNextStepSimulationResult(obj)
            obj.simulationResult.prepareForNextStep();
        end
        
        function dropOldestPowerTransitModel(obj)
            obj.modelEvolution.dropOldestPowerTransit();
        end
        
        function dropOldestPowerTransitSimulation(obj)
            obj.simulationEvolution.dropOldestPowerTransit();
        end
        
        function boolean = isItTimeToUpdate(obj, currentTime, timeStep)
            previousTime = currentTime - timeStep;
            controlCycle = obj.setting.getControlCycleInSeconds();
            
            % Iterations are defined by the euclidian division:
            % time = iterations * controlCycle + remainder, with 0 <= remainder < controlCycle
            previousIteration = floor(previousTime / controlCycle);
            currentIteration = floor(currentTime / controlCycle);
            
            boolean = currentIteration > previousIteration;
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
        
        function updateModel(obj, electricalGrid)
            obj.updatePowerFlowModel(electricalGrid);
            obj.updatePowerTransitModel(electricalGrid);
            obj.modelEvolution.updateDisturbancePowerTransit();
            obj.modelEvolution.dropOldestPowerTransit();
        end
        
        function updateSimulation(obj, electricalGrid)
            obj.updatePowerFlowSimulation(electricalGrid);
            obj.updatePowerTransitSimulation(electricalGrid);
            obj.simulationEvolution.updateDisturbancePowerTransit();
            obj.simulationEvolution.dropOldestPowerTransit();
        end
        
        %% SAVE
        function saveModelResult(obj)
            obj.modelEvolution.saveState(obj.modelResult);
            obj.controller.saveControl(obj.modelResult);
            obj.modelEvolution.saveDisturbance(obj.modelResult);
        end
        
        function saveSimulationResultOnControlCycle(obj)
            obj.simulationEvolution.saveState(obj.simulationResult);
            obj.controller.saveControl(obj.simulationResult);
            obj.simulationEvolution.saveDisturbance(obj.simulationResult);
        end
        
        function saveSimulationResultNoControl(obj)
            obj.simulationEvolution.saveState(obj.simulationResult);
            
            numberOfGen = obj.topology.getNumberOfGenOn();
            numberOfBatt = obj.topology.getNumberOfBattOn();
            noControlCurtailment = zeros(numberOfGen, 1);
            noControlBatteryInjection = zeros(numberOfBatt, 1);
            obj.simulationResult.saveControl(noControlCurtailment, noControlBatteryInjection);
            
            obj.simulationEvolution.saveDisturbance(obj.simulationResult);
        end
        
        function saveModelState(obj)
            % used in the initialization of TransmissionSimulation
            obj.modelEvolution.saveState(obj.modelResult);
        end
        
        function saveSimulationState(obj)
            % used in the initialization of TransmissionSimulation
            obj.simulationEvolution.saveState(obj.simulationResult);
        end
        
        %% PLOT
        function graphPlot = plotTopology(obj)
            graphPlot = obj.topology.plotTopology();
        end
        
        function plotModelResult(obj, electricalGrid)
            obj.modelResult.plotAllFigures(electricalGrid);
        end
        
        function plotSimulationResult(obj, electricalGrid)
            obj.simulationResult.plotAllFigures(electricalGrid);
        end
        
        %% GETTER
        function object = getModelEvolution(obj)
            object = obj.modelEvolution;
        end
        
        function object = getSimulationEvolution(obj)
            object = obj.simulationEvolution;
        end
    end
end