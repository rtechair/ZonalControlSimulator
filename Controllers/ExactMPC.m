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
classdef ExactMPC < Controller
    % The optimization problem is written based on Guillaume Ganet--Lepage's ECC2023 paper
    properties (SetAccess = private)
        curtailmentDelay
        batteryDelay
        horizon
        nBus
        nFrontierBus
        nBranch
        nGen
        nBatt

        PTDFBus
        PTDFFrontierBus
        PTDFGen
        PTDFBatt
        
        maxPowerGeneration
        minPowerBattery
        maxPowerBattery
        maxEnergyBattery
        
        minPowerFlow
        maxPowerFlow
        
        batteryCoef
        timestep

        controller
        solver
        
        estimPowerAvailable

        % Result of controller
        result
        infeasibility

        pastCurtCtrls
        pastBattCtrls
        newCurtCtrl
        newBattCtrl
        
        countControls

        % YALMIP
        varPowerFlow
        varPowerCurtailment
        varPowerAvailable
        varPowerGeneration
        varPowerBattery
        varEnergyBattery
        varBatteryPowerControl
        varCurtailmentPowerControl

        varTransitPowerDisturbance_Frontier
        varTransitPowerDisturbance_Bus
        varPtdfBus
        varPtdfFrontierBus
        varPtdfGen
        varPtdfBatt
        varSlackPowerFlow

        constraints
        objective

        % Received elements
        state
        disturbPowerTransit
        disturbPowerAvailable
    end

    methods
        function obj = ExactMPC(curtailmentDelay, batteryDelay, horizonInIterations, ...
                numberOfBuses, numberOfFrontierBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                PTDFBus, PTDFFrontierBus, PTDFGen, PTDFBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, minPowerFlow, maxPowerFlow, ...
                batteryCoef, timestepInSeconds, solverName)
            obj.curtailmentDelay = curtailmentDelay;
            obj.batteryDelay = batteryDelay;
            obj.horizon = horizonInIterations;
            obj.nBus = numberOfBuses;
            obj.nFrontierBus = numberOfFrontierBuses;
            obj.nBranch = numberOfBranches;
            obj.nGen = numberOfGen;
            obj.nBatt = numberOfBatt;
            obj.PTDFBus = PTDFBus;
            obj.PTDFFrontierBus = PTDFFrontierBus;
            obj.PTDFGen =PTDFGen;
            obj.PTDFBatt = PTDFBatt;
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.minPowerBattery = minPowerBattery;
            obj.maxPowerBattery = maxPowerBattery;
            obj.maxEnergyBattery = maxEnergyBattery;
            obj.minPowerFlow = minPowerFlow;
            obj.maxPowerFlow = maxPowerFlow;
            obj.batteryCoef = batteryCoef;
            obj.timestep = timestepInSeconds;
            obj.solver = solverName;

            obj.countControls = 0;

            obj.setYalmipVariables();

            obj.setConstraints();
            obj.setDynamicEquations();
            obj.setObjectiveGuillaume1();

            obj.setController();
            obj.initializePastCurtControls();
            obj.initializePastBattControls();
        end

        function receiveState(obj, stateOfZone)
            arguments
                obj
                stateOfZone (1,1) StateOfZone
            end
            obj.state = stateOfZone;
        end

        function receiveDisturbancePowerAvailable(obj, disturbancePowerAvailable)
            obj.disturbPowerAvailable = disturbancePowerAvailable;
        end

        function receiveDisturbancePowerTransit(obj, disturbancePowerTransit)
            obj.disturbPowerTransit = disturbancePowerTransit;
            % 2022-06-08: Sorin advises the controller should not consider any disturbance form outside the zone currently
            obj.disturbPowerTransit = zeros(obj.nFrontierBus,1);
        end

        function setPtdfBus(obj, ptdf)
            obj.PTDFBus = ptdf;
        end

        function setPtdfFrontierBus(obj, ptdf)
            obj.PTDFFrontierBus = ptdf;
        end

        function setPtdfGen(obj, ptdf)
            obj.PTDFGen = ptdf;
        end

        function setPtdfBatt(obj, ptdf)
            obj.PTDFBatt = ptdf;
        end

        function object = getControl(obj)
            object = ControlOfZone(obj.newCurtCtrl, obj.newBattCtrl);
        end

        function computeControl(obj)
            obj.countControls = obj.countControls + 1;

            obj.setAvailablePowerEstimation();
            obj.solveOptimizationProblem();
            obj.checkSolvingFeasibility();
            obj.interpretResult();
            obj.checkBatteryCtrlFeasilibility();
            obj.neglectNumericalErrorCurt();
            obj.neglectNumericalErrorBattery();

            obj.updatePastCurtCtrl();
            obj.updatePastBattCtrl();
        end

        function saveControl(obj, memory)
            memory.saveControl(obj.newCurtCtrl, obj.newBattCtrl);
        end

    end % public methods

    methods (Access = 'protected')
        function setYalmipVariables(obj)
                obj.varPowerFlow = sdpvar(obj.nBranch, obj.horizon+1, 'full');
                obj.varPowerCurtailment = sdpvar(obj.nGen, obj.horizon + 1, 'full');
                obj.varPowerAvailable = sdpvar(obj.nGen, obj.horizon + 1, 'full');
                obj.varPowerGeneration = sdpvar(obj.nGen, obj.horizon + 1, 'full');
                obj.varPowerBattery = sdpvar(obj.nBatt, obj.horizon + 1, 'full');
                obj.varEnergyBattery = sdpvar(obj.nBatt, obj.horizon + 1, 'full');

                obj.varBatteryPowerControl = sdpvar(obj.nBatt, obj.horizon, 'full');
                obj.varCurtailmentPowerControl = sdpvar(obj.nGen, obj.horizon, 'full');

                obj.varTransitPowerDisturbance_Frontier = sdpvar(obj.nFrontierBus, obj.horizon, 'full');
                obj.varTransitPowerDisturbance_Bus = sdpvar(obj.nBus, obj.horizon, 'full');

                obj.varPtdfBus = sdpvar(obj.nBranch, obj.nBus, 'full');
                obj.varPtdfFrontierBus = sdpvar(obj.nBranch, obj.nFrontierBus, 'full');
                obj.varPtdfGen = sdpvar(obj.nBranch, obj.nGen, 'full');
                obj.varPtdfBatt = sdpvar(obj.nBranch, obj.nBatt, 'full');

                obj.varSlackPowerFlow = sdpvar(obj.nBranch, obj.curtailmentDelay - obj.batteryDelay, 'full'); % 1, ..., curtDelay, even though in reality: curtBatt + 1, ... curtDelay
                
        end

        function setConstraints(obj)
            obj.constraints = [];
            constraintPositiveSlack = [obj.varSlackPowerFlow >= 0]:'slack positivity';
            timeRange = obj.batteryDelay+2 : obj.curtailmentDelay+1; % battDelay +1, ..., , curtDelay, but +1 overall due to the initial state at time 0
            lengthOfRange = obj.curtailmentDelay - obj.batteryDelay;
            constraintAllowNegativeOverflow = [obj.varPowerFlow(:, timeRange) >= repmat(obj.minPowerFlow, 1, lengthOfRange) - obj.varSlackPowerFlow]:'positive overflow allowed';
            constraintAllowPositiveOverflow = [obj.varPowerFlow(:, timeRange) <= repmat(obj.maxPowerFlow, 1, lengthOfRange) + obj.varSlackPowerFlow]:'positive overflow allowed';
            constraintNoOverflowMin = [obj.varPowerFlow(:, obj.curtailmentDelay+2 :end) >= obj.minPowerFlow]:'min power flow';
            constraintNoOverflowMax = [obj.varPowerFlow(:, obj.curtailmentDelay+2 :end) <= obj.maxPowerFlow]:'max power flow';
            

            constraintMinPowerGeneration = [obj.varPowerGeneration >= 0]:'positive generation';
            constraintMaxPowerGeneration = [obj.varPowerGeneration <= repmat(obj.maxPowerGeneration, 1, obj.horizon+1) ]:'max generation';

            constraintMinPowerCurtailment = [obj.varPowerCurtailment >= 0]:'positive curtailment';
            constraintMaxPowerCurtailment = [obj.varPowerCurtailment <= repmat(obj.maxPowerGeneration, 1, obj.horizon+1)]:'max curtailment';
            constraintFeasibleFutureCurtailmentMin = 0 <= obj.varPowerCurtailment(:, end) + obj.varCurtailmentPowerControl(:, end);
            constraintFeasibleFutureCurtailmentMax = obj.varPowerCurtailment(:, end) + obj.varCurtailmentPowerControl(:, end) <= obj.maxPowerGeneration;
            
            %constraintPositiveCurtailmentCtrl = obj.varCurtailmentPowerControl >= 0;

            constraintMinPowerBattery = [obj.varPowerBattery >= obj.minPowerBattery]:'min battery power';
            constraintMaxPowerBattery = [obj.varPowerBattery <= obj.maxPowerBattery]:'max battery power';
            
            constraint =  constraintPositiveSlack;
            constraint =  [constraint, constraintAllowNegativeOverflow];
            constraint =  [constraint, constraintAllowPositiveOverflow];
            constraint =  [constraint, constraintNoOverflowMin];
            constraint =  [constraint, constraintNoOverflowMax];
            constraint =  [constraint, constraintMinPowerGeneration];
            constraint =  [constraint, constraintMaxPowerGeneration];
            constraint =  [constraint, constraintMinPowerCurtailment];
            constraint =  [constraint, constraintMaxPowerCurtailment];
            constraint =  [constraint, constraintFeasibleFutureCurtailmentMin];
            constraint =  [constraint, constraintFeasibleFutureCurtailmentMax];
            constraint =  [constraint, constraintMinPowerBattery];
            constraint =  [constraint, constraintMaxPowerBattery];
            
            %constraint = [constraint, constraintPositiveCurtailmentCtrl];

            obj.constraints = constraint;
        end

        function setDynamicEquations(obj)
            dynamicsPowerCurtailment = [obj.varPowerCurtailment(:, 2:end) == obj.varPowerCurtailment(:, 1: end-1) + obj.varCurtailmentPowerControl]:'curtailment power dynamics';
            %dynamicsPowerAvailable = [obj.varPowerAvailable(:, 2:end) == obj.varPowerAvailable(:, 1: end-1) + obj.varAvailablePowerDisturbance]:'available power dynamics';
            dynamicsPowerBattery = [obj.varPowerBattery(:, 2:end) == obj.varPowerBattery(:, 1:end-1) + obj.varBatteryPowerControl]:'battery power dynamics';
            
            % Beware of the .* for: batteryCoef .* varPowerBattery, in case of several batteries with each their own battery coef, the equation should work
            dynamicsEnergyBattery = [obj.varEnergyBattery(:, 2:end) == obj.varEnergyBattery(:, 1: end-1) + obj.timestep * obj.batteryCoef .* obj.varPowerBattery(:, 2:end)]:'battery energy dynamics';

            dynamicsPowerGeneration = [obj.varPowerGeneration(:, 2:end) == min(obj.varPowerAvailable(:, 2:end), repmat(obj.maxPowerGeneration,1, obj.horizon) - obj.varPowerCurtailment(:, 2:end))]:'generation power dynamics';
            
            dynamicsPowerFlow = [obj.varPowerFlow(:, 2:end) == obj.varPowerFlow(:, 1: end-1) ...
                                                                                                + obj.varPtdfGen * ( obj.varPowerGeneration(:, 2:end) - obj.varPowerGeneration(:, 1: end-1) )...
                                                                                                + obj.varPtdfBatt * obj.varBatteryPowerControl...
                                                                                                + obj.varPtdfFrontierBus * obj.varTransitPowerDisturbance_Frontier]:'power flow dynamics';
            constraint = dynamicsPowerCurtailment;
            %constraint = [constraint, dynamicsPowerAvailable];
            constraint = [constraint, dynamicsPowerBattery];
            constraint = [constraint, dynamicsEnergyBattery];
            constraint = [constraint, dynamicsPowerGeneration];
            constraint = [constraint, dynamicsPowerFlow];

            obj.constraints = [obj.constraints, constraint];
        end

        function setObjectiveGuillaume1(obj)
            % Alessio's desired behavior, i.e. battery controls spread over the horizon
            highCoef = obj.horizon * obj.minPowerBattery^2; %TODO: if there are several batteries in the zone, is minPowerBattery a scalar or a vector?
            
            overflowObj = highCoef * sum(obj.varSlackPowerFlow, "all");

            modifiableCurtCtrl = obj.varCurtailmentPowerControl(:, obj.curtailmentDelay+1 : end);
            curtCtrlObj = highCoef * sum(modifiableCurtCtrl, "all");

            modifiableBattCtrl = obj.varBatteryPowerControl(:, obj.batteryDelay+1 : end);
            battCtrlObj = sum(modifiableBattCtrl .^2, "all");
            
            modifiableBattState = obj.varPowerBattery(:, obj.batteryDelay+2 : end);
            battStateObj = sum(modifiableBattState .^ 2, "all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setController(obj)
            pastCurtCtrl = obj.varCurtailmentPowerControl(:, 1:obj.curtailmentDelay);
            pastBattCtrl = obj.varBatteryPowerControl(:, 1:obj.batteryDelay);
            inputs = {obj.varPowerFlow(:, 1), obj.varPowerCurtailment(:, 1), obj.varPowerBattery(:, 1), obj.varEnergyBattery(:, 1), obj.varPowerGeneration(:, 1), ...% obj.varPowerAvailable(:, 1), ...
                pastCurtCtrl, pastBattCtrl, obj.varPowerAvailable, obj.varTransitPowerDisturbance_Frontier, ...
                obj.varPtdfFrontierBus, obj.varPtdfGen, obj.varPtdfBatt};

            modifiableCurtCtrl = obj.varCurtailmentPowerControl(:, obj.curtailmentDelay+1 : end);
            modifiableBattCtrl = obj.varBatteryPowerControl(:, obj.batteryDelay+1 : end);
            allStates = [obj.varPowerFlow;
                               obj.varPowerCurtailment;
                               obj.varPowerBattery;
                               obj.varEnergyBattery;
                               obj.varPowerGeneration;
                               obj.varPowerAvailable];
            allControls = [obj.varCurtailmentPowerControl zeros(obj.nGen, 1);
                                  obj.varBatteryPowerControl zeros(obj.nBatt, 1)];
            allStatesAndControls = [allStates;
                                                   allControls];

            outputs = {modifiableCurtCtrl, modifiableBattCtrl, allStatesAndControls, obj.varCurtailmentPowerControl, obj.varBatteryPowerControl, ...
                obj.varPowerFlow, obj.varPowerCurtailment, obj.varPowerBattery, obj.varEnergyBattery, obj.varPowerGeneration, obj.varPowerAvailable};
            options = sdpsettings('solver', obj.solver);
            obj.controller = optimizer(obj.constraints, obj.objective, options, inputs, outputs);
        end

        function initializePastCurtControls(obj)
            obj.pastCurtCtrls = zeros(obj.nGen, obj.curtailmentDelay);
        end

        function initializePastBattControls(obj)
            obj.pastBattCtrls = zeros(obj.nBatt, obj.batteryDelay);
        end

        function setAvailablePowerEstimation(obj)
            obj.estimPowerAvailable(:,1) = obj.state.getPowerAvailable();
            for t = 1:obj.horizon
                obj.estimPowerAvailable(:,t+1) = obj.estimPowerAvailable(:,t) + obj.disturbPowerAvailable;
            end
            obj.estimPowerAvailable = max(0, obj.estimPowerAvailable);
        end

        function solveOptimizationProblem(obj)
            PF = obj.state.getPowerFlow();
            PC = obj.state.getPowerCurtailment();
            PB = obj.state.getPowerBattery();
            % 2023-08-22: Due to the numerical error of the solver,
            % the battery power can exceed than its threshold. 
            if PB < obj.minPowerBattery
                incorrectDiff = PB - obj.minPowerBattery;
                a = ['At countControls=' num2str(obj.countControls) ' , incorrect PB, difference is:' num2str(incorrectDiff) ' , PB now rounded at:' num2str(obj.minPowerBattery)];
                disp(a)
                PB = obj.minPowerBattery;
            end
            EB = obj.state.getEnergyBattery();
            PG = obj.state.getPowerGeneration();
            transitPowerDisturbEstim = repmat(obj.disturbPowerTransit, 1, obj.horizon);

            [obj.result, obj.infeasibility] = obj.controller{PF, PC, PB, EB, PG, obj.pastCurtCtrls, obj.pastBattCtrls, ...
                obj.estimPowerAvailable, transitPowerDisturbEstim, ...
                obj.PTDFFrontierBus, obj.PTDFGen, obj.PTDFBatt};
        end

        function checkSolvingFeasibility(obj)
            if obj.infeasibility ~= 0
                    disp(yalmiperror(obj.infeasibility))
            end
        end

        function interpretResult(obj)
            modifiableCurtCtrl = obj.result{1};
            modifiableBattCtrl = obj.result{2};
            obj.newCurtCtrl = modifiableCurtCtrl(:,1);
            obj.newBattCtrl = modifiableBattCtrl(:,1);
        end

        function checkBatteryCtrlFeasilibility(obj)
            PB = obj.state.getPowerBattery();
            % 2023-08-22: Due to numerical errors of the solver, the
            % battery power can exceed its threshold. Errors were observed to be around 10^(-14)
            futurePB = PB + sum(obj.pastBattCtrls,2) + obj.newBattCtrl;
            for i = 1:obj.nBatt
                if futurePB(i) < obj.minPowerBattery(i)
                    diffError = futurePB(i) - obj.minPowerBattery(i);
                    if diffError < -0.1
                        a = [ 'Error of the battery power control is' num2str(diffError) ' , this is too large, thus strange'];
                        disp(a)
                    end
                    obj.newBattCtrl(i) = obj.newBattCtrl(i) + 10^(-8);
                    correctedFuturePowerBattery = obj.newBattCtrl(i) + PB(i) + sum(obj.pastBattCtrls, 2);
                    if correctedFuturePowerBattery < obj.minPowerBattery
                        a = ['At countControls=' num2str(obj.countControls) ' , incorrect PB, difference is:' num2str(diffError) ' , transformed into:' num2str(obj.newBattCtrl(i)) ];
                        disp(a)
                    end
                end
            end
        end

        function neglectNumericalErrorCurt(obj)
            for i = 1:obj.nGen
                thresold = 0.1; % 2023-08-22: some absurb controls appear like:-0.0357. Thus 0.1 is chosen
                if abs(obj.newCurtCtrl(i)) < thresold
                    obj.newCurtCtrl(i) = 0;
                end
            end
        end

        function neglectNumericalErrorBattery(obj)
            for i = 1:obj.nBatt
                if abs(obj.newBattCtrl(i)) < 0.1
                    obj.newBattCtrl(i) = 0;
                end
            end
        end

        function updatePastCurtCtrl(obj)
            curtCtrlLeft = obj.pastCurtCtrls(:, 2:obj.curtailmentDelay);
            obj.pastCurtCtrls = [curtCtrlLeft obj.newCurtCtrl];
        end

        function updatePastBattCtrl(obj)
            battCtrlLeft = obj.pastBattCtrls(:, 2:obj.batteryDelay);
            obj.pastBattCtrls = [battCtrlLeft obj.newBattCtrl];
        end
    end % protected methods

end