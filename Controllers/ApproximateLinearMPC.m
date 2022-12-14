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
classdef ApproximateLinearMPC < Controller
    
    properties (SetAccess = private)
        %% Parameters
        numberOfBuses
        numberOfBranches
        numberOfGen
        numberOfBatt
        delayCurt
        delayBatt
        horizon

        maxPowerGeneration
        minControlCurt
        maxControlCurt
        minControlBatt
        maxControlBatt
        minPowerBattery
        maxPowerBattery
        maxEnergyBattery
        maxFlow

        minExtendedControl
        maxExtendedControl

        operatorStateExtended
        operatorControlExtended
        operatorDisturbancePowerGenerationExtended
        operatorDisturbancePowerTransitExtended
        
        %% Yalmip
        x
        dk_in
        dk_out
        u
        epsilon
        
        constraints
        objective
        sdp_setting
        controller

        %% Closed-loop simulation
       ucK_delay % over the prediction horizon
       ucK_new % new curt control decided now by the controller, but will be applied after delay
       ubK_delay % over the prediction horizon
       ubK_new % new battery control decided now by the controller, but delayed
       Delta_PA_est
       Delta_PC_est
       Delta_PT_est
       PA_est
       PC_est
       PG_est       % #gen x #iterations
       Delta_PG_est % #gen x predictionHorizon x #simIterations
       infeasibilityHistory % #simIterations
       
       xK_extend % a column vector
       
       result
       infeas
       
        % elements received
        state
        disturbancePowerTransit
        disturbancePowerAvailable
        
        countControls
    end
    
    
    methods
        function obj = ApproximateLinearMPC(delayCurtailment, delayBattery, delayTelecom, ...
                horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorDisturbancePowerGenerationExtended, operatorDisturbancePowerTransitExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit)
            
            obj.operatorStateExtended = operatorStateExtended;
            obj.operatorControlExtended = operatorControlExtended;
            obj.operatorDisturbancePowerGenerationExtended = operatorDisturbancePowerGenerationExtended;
            obj.operatorDisturbancePowerTransitExtended = operatorDisturbancePowerTransitExtended;
            
            obj.numberOfBuses = numberOfBuses;
            obj.numberOfBranches = numberOfBranches;
            obj.numberOfGen = numberOfGen;
            obj.numberOfBatt = numberOfBatt;
            
            obj.delayCurt = delayCurtailment + delayTelecom;
            obj.delayBatt = delayBattery + delayTelecom;
            obj.horizon = horizonInIterations;

            obj.maxPowerGeneration = maxPowerGeneration;
            obj.minControlCurt = zeros(obj.numberOfGen, 1);
            obj.maxControlCurt = obj.maxPowerGeneration;

            obj.minPowerBattery = minPowerBattery;
            obj.maxPowerBattery = maxPowerBattery;
            obj.minControlBatt = obj.minPowerBattery - obj.maxPowerBattery;
            obj.maxControlBatt = obj.maxPowerBattery - obj.minPowerBattery;
            obj.maxEnergyBattery = maxEnergyBattery;
            obj.maxFlow = flowLimit;

            obj.setMinControl();
            obj.setMaxControl();
            
            obj.setYalmipVar();
            obj.setConstraints();
            obj.setObjective();
            obj.setSolver();
            obj.setController();

            obj.initializePastCurtControls();
            obj.initializePastBattControls();
            obj.countControls = 0;
        end
        
        %% CLOSED LOOP SIMULATION
        function initializePastCurtControls(obj)
            obj.ucK_delay = zeros(obj.numberOfGen, obj.delayCurt);
        end
        
        function initializePastBattControls(obj)
            obj.ubK_delay = zeros(obj.numberOfBatt, obj.delayBatt);
        end
        
        function receiveState(obj, stateOfZone)
            obj.state = stateOfZone;
        end
        
        function receiveDisturbancePowerTransit(obj, disturbancePowerTransit)
            obj.disturbancePowerTransit = disturbancePowerTransit;
            % 08/06/2022: Sorin advises the controller should not consider any disturbance form outside the zone currently
            obj.disturbancePowerTransit = zeros(obj.numberOfBuses, 1);
        end
        
        function receiveDisturbancePowerAvailable(obj, disturbancePowerAvailable)
            obj.disturbancePowerAvailable = disturbancePowerAvailable;
        end
        
        function computeControl(obj)
            obj.countControls = obj.countControls + 1;

            realDeltaPA = obj.disturbancePowerAvailable;
            realDeltaPT = obj.disturbancePowerTransit;

            obj.initializeStateEstimation();
            
            obj.setDelta_PA_est_constant_over_horizon(realDeltaPA);
            obj.setPA_over_horizon();
            
            obj.setDelta_PT_over_horizon(realDeltaPT);

            obj.setDelta_PC_est_over_horizon();
            obj.setPC_est_over_horizon();

            obj.setDelta_PG_and_PG_est_over_horizon();
            
            obj.set_xK_extend();
            
            obj.doControl();
            
            obj.checkSolvingFeasibility();
            obj.interpretResult();
            
            obj.saveInfeas();
            
            obj.updatePastCurtControls();
            obj.updatePastBattControls();
        end
        
        function object = getControl(obj)
            curtControl = obj.ucK_new;
            battControl = obj.ubK_new;
            object = ControlOfZone(curtControl, battControl);
        end
        
        function initializeStateEstimation(obj)
            obj.PA_est(:,1) = obj.state.getPowerAvailable();
            obj.PC_est(:,1) = obj.state.getPowerCurtailment();
            obj.PG_est(:,1) = obj.state.getPowerGeneration();
        end
        
        function setDelta_PA_est_constant_over_horizon(obj, realDeltaPA)
            % Pre-requisite: PA set up, i.e. correct PA_est(:,1)
            areAllDeltaPANonNegative = all(realDeltaPA >= 0);
            if areAllDeltaPANonNegative
                obj.Delta_PA_est = repmat(realDeltaPA, 1, obj.horizon);
            else
                for g = 1:obj.numberOfGen
                    deltaPAOfGen = realDeltaPA(g,1);
                    if deltaPAOfGen >= 0
                        obj.Delta_PA_est(g,1:obj.horizon) = deltaPAOfGen;
                    else
                        obj.computeCorrectDisturbanceOfGen(g, deltaPAOfGen);
                    end
                end
            end
        end
        
        function computeCorrectDisturbanceOfGen(obj, genIndex, deltaPAOfGen)
            realPAOfGen = obj.PA_est(genIndex,1);
            % n is the last iteration such that deltaPA(gen ,k) = deltaPAOfGen
            n = floor(realPAOfGen / -deltaPAOfGen);
            if n >= obj.horizon
                obj.Delta_PA_est(genIndex, 1:obj.horizon) = deltaPAOfGen;
            else
                obj.Delta_PA_est(genIndex, 1:n) = deltaPAOfGen;
                
                DeltaPAToReachZero = - realPAOfGen - deltaPAOfGen * n;
                obj.Delta_PA_est(genIndex, n + 1) = DeltaPAToReachZero;
                
                obj.Delta_PA_est(genIndex, n+2 : obj.horizon) = 0;
            end
        end
        
        function setPA_over_horizon(obj)
            %{
            Cautious, the original equation:
                obj.PA_est(:,k+1) = obj.PA_est(:,k) + obj.Delta_PA_est(:,k)
            is not used.
            This is due to the unaccuracy of floating-point data.
            Using the original equation would result in approximate PA at
            each iteration which are then used for the computation of the
            following iteration. Summing these approximations can lead to
            having some PA < 0 while PA = 0 is desired.
            %}
            for k = 1:obj.horizon
                obj.PA_est(:,k+1) = obj.PA_est(:,1) + sum(obj.Delta_PA_est(:,1:k),2);
            end
        end
        
        function setDelta_PT_over_horizon(obj, realDeltaPT)
            obj.Delta_PT_est = repmat(realDeltaPT, 1, obj.horizon);
        end
        
        function set_xK_extend(obj)
            stateVector = obj.state.getStateAsVector();
            stateVectorMinusPA = stateVector(1: end-obj.numberOfGen);
            pastCurtControlVector = reshape(obj.ucK_delay, [], 1);
            pastBattControlVector = reshape(obj.ubK_delay, [], 1);
            
            obj.xK_extend = [stateVectorMinusPA ; ...
                             pastCurtControlVector ; ...
                             pastBattControlVector];
        end
        
        function doControl(obj)
            [obj.result, obj.infeas] = obj.controller{obj.xK_extend, obj.Delta_PG_est, obj.Delta_PT_est};
        end
        
        function checkSolvingFeasibility(obj)
            if obj.infeas ~= 0
                disp(yalmiperror(obj.infeas))
            end
        end
        
        function saveInfeas(obj)
            obj.infeasibilityHistory(end+1) = obj.infeas;
        end
        
        function interpretResult(obj)
            optimalControlOverHorizon = obj.result{1};
            optimalNextControl = optimalControlOverHorizon(:,1);
            rangeGen = 1:obj.numberOfGen;
            optimalCurtControl = optimalNextControl(rangeGen,1);
            obj.ucK_new = optimalCurtControl;
            rangeBatt = obj.numberOfGen+1 : obj.numberOfGen+obj.numberOfBatt;
            optimalBattControl = optimalNextControl(rangeBatt,1);
            obj.ubK_new = optimalBattControl;
        end
        
        function updatePastCurtControls(obj)
            leftCurtControls = obj.ucK_delay(:,2 :obj.delayCurt);
            obj.ucK_delay = [leftCurtControls obj.ucK_new];
        end
        
        function updatePastBattControls(obj)
            leftBattControls = obj.ubK_delay(:, 2: obj.delayBatt);
            obj.ubK_delay = [leftBattControls obj.ubK_new];
        end

        function saveControl(obj, memory)
            curtControl = obj.ucK_new;
            battControl = obj.ubK_new;
            memory.saveControl(curtControl, battControl);
        end


        %% new code:

        function setYalmipVar(obj)
            yalmip('clear');
            numberOfExtendedStateVar = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt + obj.numberOfGen*obj.delayCurt + obj.numberOfBatt * obj.delayBatt;
            obj.x = sdpvar(numberOfExtendedStateVar, obj.horizon + 1, 'full');
            obj.u = sdpvar(obj.numberOfGen + obj.numberOfBatt, obj.horizon, 'full');
            obj.dk_in = sdpvar(obj.numberOfGen, obj.horizon, 'full');
            obj.dk_out = sdpvar(obj.numberOfBuses, obj.horizon, 'full');
            obj.epsilon = sdpvar(obj.numberOfBranches, obj.horizon, 'full');
        end

        function setMinControl(obj)
            obj.minExtendedControl = [obj.minControlCurt ; obj.minControlBatt];
        end

        function setMaxControl(obj)
            obj.maxExtendedControl = [obj.maxControlCurt ; obj.maxControlBatt];
        end

        function setConstraints(obj)
            obj.constraints = [];
            obj.setConstraintNoOverflowAfterDelayCurt();
            obj.setConstraintLowerBoundControl();
            obj.setConstraintUpperBoundControl();
            obj.setConstraintNonNegativeOverflow();
            obj.setConstraintDynamicalEvolution();
            
            obj.setConstraintLowerBoundFlow();
            obj.setConstraintUpperBoundFlow();
            obj.setConstraintMinPowerCurtailment();
            obj.setConstraintMaxPowerCurtailment();
            obj.setConstraintMinPowerBattery();
            obj.setConstraintMaxPowerBattery();
        end

        function setConstraintNoOverflowAfterDelayCurt(obj)
            noOverflowAfterDelayCurt = obj.epsilon(:, obj.delayCurt+1 : end) == 0;
            obj.constraints = [obj.constraints, noOverflowAfterDelayCurt];
        end

        function setConstraintLowerBoundControl(obj)
            minExtendedControlOverHorizon = repmat(obj.minExtendedControl, 1, obj.horizon);
            constraint = obj.u >= minExtendedControlOverHorizon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintUpperBoundControl(obj)
            maxControloverHorizon = repmat(obj.maxExtendedControl, 1, obj.horizon);
            constraint = obj.u <= maxControloverHorizon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintNonNegativeOverflow(obj)
            constraint = obj.epsilon >= 0;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintDynamicalEvolution(obj)
            constraint = ...
                obj.x(:, 2:end) == obj.operatorStateExtended * obj.x(:, 1: end-1) + obj.operatorControlExtended * obj.u + obj.operatorDisturbancePowerGenerationExtended * obj.dk_in + obj.operatorDisturbancePowerTransitExtended * obj.dk_out;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintLowerBoundFlow(obj)
            flowVar = obj.x(1:obj.numberOfBranches, 2:end);
            constraint = flowVar >=  - obj.maxFlow * ones(obj.numberOfBranches, obj.horizon) - obj.epsilon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintUpperBoundFlow(obj)
            flowVar = obj.x(1:obj.numberOfBranches, 2:end);
            constraint = flowVar <=  obj.maxFlow * ones(obj.numberOfBranches, obj.horizon) + obj.epsilon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintMinPowerCurtailment(obj)
            start = obj.numberOfBranches + 1;
            finish = start + obj.numberOfGen - 1;
            powerCurtailmentVar = obj.x(start:finish, 2:end);
            constraint = powerCurtailmentVar >= 0;
            obj.constraints = [ obj.constraints, constraint];
        end

        function setConstraintMaxPowerCurtailment(obj)
            start = obj.numberOfBranches + 1;
            finish = start + obj.numberOfGen - 1;
            powerCurtailmentVar = obj.x(start:finish, 2:end);
            maxPowerGenerationOverHorizon = repmat(obj.maxPowerGeneration, 1, obj.horizon);
            constraint = powerCurtailmentVar <= maxPowerGenerationOverHorizon;
            obj.constraints = [ obj.constraints, constraint];

        end

        function setConstraintMinPowerBattery(obj)
            start = obj.numberOfBranches + obj.numberOfGen + 1;
            finish = start + obj.numberOfBatt - 1;
            powerBatteryVar = obj.x(start:finish, 2:end);
            minPowerBatteryOverHorizon = repmat(obj.minPowerBattery, 1, obj.horizon);
            constraint = powerBatteryVar >= minPowerBatteryOverHorizon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setConstraintMaxPowerBattery(obj)
            start = obj.numberOfBranches + obj.numberOfGen + 1;
            finish = start + obj.numberOfBatt - 1;
            powerBatteryVar = obj.x(start:finish, 2:end);
            maxPowerBatteryOverHorizon = repmat(obj.maxPowerBattery, 1, obj.horizon);
            constraint = powerBatteryVar <= maxPowerBatteryOverHorizon;
            obj.constraints = [obj.constraints, constraint];
        end

        function setObjective(obj)
            isObjective_Guillaume1 = true;
            isObjective_Guillaume2 = false;
            isObjective_Guillaume3 = false;
            isObjective_Guillaume1_NoBattery = false;

            if isObjective_Guillaume1
                obj.setObjective_Guillaume1();
            elseif isObjective_Guillaume2
                obj.setObjective_Guillaume2();
            elseif isObjective_Guillaume3
                obj.setObjective_Guillaume3();
            elseif isObjective_Guillaume1_NoBattery
                obj.setObjective_Guillaume1_NoBattery();
            else
                print('No objective selected. Select an objective');
            end

        end

        function setObjective_Guillaume1(obj)
            highCoef = obj.horizon * obj.minPowerBattery^2;
            overflowObj = highCoef * sum(obj.epsilon, "all");

            curtCtrl = obj.u(1:obj.numberOfGen, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            battIdxRange = (obj.numberOfGen + 1) : (obj.numberOfGen + obj.numberOfBatt);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = sum(battCtrl .^ 2, "all");

            indexFirstPB = obj.numberOfBranches + obj.numberOfGen + 1;
            indexLastPB = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.numberOfBatt+1 :end);
            battStateObj = sum(batteryState .^2, "all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Guillaume2(obj)
            highCoef = obj.horizon * obj.minPowerBattery^2;
            overflowObj = highCoef * sum(obj.epsilon, "all");

            curtCtrl = obj.u(1:obj.numberOfGen, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            battIdxRange = (obj.numberOfGen + 1) : (obj.numberOfGen + obj.numberOfBatt);
            battCtrl = obj.u(battIdxRange, :);
            allButFirstBattCtrl = battCtrl(:, 2:end);
            battCtrlObj = highCoef * sum(allButFirstBattCtrl .^ 2, "all");

            indexFirstPB = obj.numberOfBranches + obj.numberOfGen + 1;
            indexLastPB = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.numberOfBatt+1 :end);
            battStateObj = sum(batteryState .^2, "all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Guillaume3(obj)
            highCoef = obj.horizon * obj.minPowerBattery^2;
            overflowObj = highCoef * sum(obj.epsilon, "all");

            curtCtrl = obj.u(1:obj.numberOfGen, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            indexFirstPB = obj.numberOfBranches + obj.numberOfGen + 1;
            indexLastPB = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.numberOfBatt+1 :end);
            battStateObj = sum(batteryState .^2, "all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Guillaume1_NoBattery(obj)
            overflowObj = sum(obj.epsilon, "all");
            curtCtrl = obj.u(1:obj.numberOfGen, :);
            curtCtrlObj = sum(curtCtrl, "all");
            obj.objective = overflowObj + curtCtrlObj;

            battIdxRange = (obj.numberOfGen + 1 ) : (obj.numberOfGen + obj.numberOfBatt);
            battCtrl = obj.u(battIdxRange, :);
            obj.constraints = [obj.constraints, battCtrl == 0];
        end

        function setSolver(obj, solverName)
            arguments
                obj
                solverName string = [];
            end
            if isempty(solverName)
                obj.sdp_setting = [];
            else
                obj.sdp_setting = sdpsettings('solver', solverName);
            end
        end

        function setController(obj)
            parameters = {obj.x(:,1), obj.dk_in, obj.dk_out};
            outputs = {obj.u, obj.epsilon, obj.x};
            obj.controller = optimizer(obj.constraints, obj.objective, obj.sdp_setting, parameters, outputs);
        end

        function setDelta_PC_est_over_horizon(obj)
            numberOfStepsAfterDelay = obj.horizon - obj.delayCurt;
            noCurtControlAfter = zeros(obj.numberOfGen, numberOfStepsAfterDelay);
            obj.Delta_PC_est = [obj.ucK_delay, noCurtControlAfter];
        end

        function setPC_est_over_horizon(obj)
            for k = 1: obj.horizon
                obj.PC_est(:,k+1) = obj.PC_est(:,k) + obj.Delta_PC_est(:,k);
            end
        end

        function setDelta_PG_and_PG_est_over_horizon(obj)
            for k = 1: obj.horizon
                f = obj.PA_est(:,k+1) - obj.PG_est(:,k) + obj.Delta_PC_est(:,k);
                g = obj.maxPowerGeneration - obj.PC_est(:,k) - obj.PG_est(:,k);
                obj.Delta_PG_est(:,k) = min(f, g);
                obj.PG_est(:,k+1) = obj.PG_est(:,k) + obj.Delta_PG_est(:,k) - obj.Delta_PC_est(:,k);
            end
        end
    
    end
end