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
classdef ApproximateLinearMPC_PAunknown_DeltaPCreal < Controller
    
    properties (SetAccess = private)
        A
        Bc
        Bb
        Dg
        Dn
        
        operatorState
        operatorControlCurtailment
        operatorControlBattery
        operatorDisturbancePowerGeneration
        operatorDisturbancePowerTransit
        operatorDisturbancePowerAvailable
        
        % Extended model
        A_new
        B_new
        D_new_in
        D_new_out
        
        % Parameters
        tau_c
        tau_b
        N
        
        c
        numberOfBuses
        b
        numberOfBranches
        numberOfStateOperatorCol
        
        Ns
        
        %% Yalmip
        x
        dk_in
        dk_out
        u
        epsilon
        probs
        
        constraints
        objective
        % Parameter
        epsilon_max
        
        Q
        Q_ep1
        R
        
        minPB
        maxPB
        
        umin_c
        umax_c
        umin_b
        umax_b
        umin
        umax
        
        xmin
        xmax
        
        flowLimit
        maxPG
        maxEB
        sdp_setting
        controller
    end
    
    
    methods
        function obj = ApproximateLinearMPC_PAunknown_DeltaPCreal(zoneName, delayCurtailment, delayBattery, delayTelecom, ...
                controlCycle, predictionHorizonInSeconds, numberOfScenarios)
            zoneOperatorsFilename = ['operatorsZone' zoneName '.mat'];
            obj.loadOperators(zoneOperatorsFilename);
            obj.setNumberOfBuses();
            obj.setNumberOfGen();
            obj.setNumberOfBatt();
            obj.setNumberOfBranches();
            
            obj.changeOperatorStateDueToBattery(controlCycle);
            obj.changeOperatorControlBatteryDueToBattery(controlCycle);
            obj.restrictOperatorSize();
            
            obj.tau_c = delayCurtailment + delayTelecom;
            obj.tau_b = delayBattery + delayTelecom;
            
            horizonInIterations = ceil(predictionHorizonInSeconds / controlCycle);
            obj.N = horizonInIterations;
            obj.Ns = numberOfScenarios;
            
            obj.setNumberOfStateOperatorCol();
        end
        
        function setOtherElements(obj, amplifierQ_ep1, maxPowerGeneration, ...
                minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit, maxEpsilon)
            obj.setCostRefDeviation();
            obj.setCostControlUse();
            obj.setCostRefDeviationEp1(amplifierQ_ep1);
            obj.setMaxPowerGeneration(maxPowerGeneration);
            obj.setMinControlCurt();
            obj.setMaxControlCurt();
            
            obj.setMinPowerBattery(minPowerBattery);
            obj.setMaxPowerBattery(maxPowerBattery);
            
            obj.setMinControlBattery()
            obj.setMaxControlBattery()
            
            obj.setMaxEnergyBattery(maxEnergyBattery);
            obj.setFlowLimit(flowLimit);
            
            obj.setMaxEpsilon(maxEpsilon);
            
            obj.setYalmipVar();
            obj.setOperatorExtendedState();
            obj.setOperatorExtendedControl();
            obj.setOperatorExtendedDisturbance();
            obj.setMinControl();
            obj.setMaxControl();
            obj.setMinState();
            obj.setMaxState();
            
            obj.resetConstraints();
            obj.resetObjective();
            
            obj.setConstraints(); % CAUTIOUS
            % obj.setMpcFormulation();
            
            % obj.setObjective(); % CAUTIOUS
            % obj.setUselessObjectiveSearchingForFeasibility(); % CAUTIOUS
            % obj.setObjective_penalizeControl();
            % obj.setObjective_penalizeControlAndEpsilon();
            %obj.setObjective_penalizeSumSquaredControlAndEpsilon();
            
            % obj.setObjective_overflow_curtCtrl_battState_Penalty();
            % obj.setObjective_overflow_curtCtrl_Penalty();
            % obj.setObjective_overflow_curtCtrl_battCtrl_Penalty();
            %obj.setObjective_inspiration1();
            % obj.setObjective_inspiration2();
            % obj.setObjective_Alessio();
            obj.setObjective_Alessio2();
           %obj.setObjectiveSorin();
           % obj.setObjectiveSorinNoBattery();

           isObjective_Guillaume1 = false;
           isObjective_Guillaume2 = false;
           isObjective_Guillaume3 = false;
           isObjective_Guillaume1_NoBattery = false;
            
           if isObjective_Guillaume1
               obj.setObjective_Guillaume1();
           end
           if isObjective_Guillaume2
               obj.setObjective_Guillaume2();
           end
           if isObjective_Guillaume3
               obj.setObjective_Guillaume3();
           end
           if isObjective_Guillaume1_NoBattery
               obj.setObjective_Guillaume1_NoBattery();
           end

            obj.setSolver();
            obj.setController();
            
            obj.initializePastCurtControls();
            obj.initializePastBattControls();
            
            obj.countControls = 0;
            
        end
        
        function loadOperators(obj, filename)
            operators = load(filename);
            obj.operatorState = operators.operatorState;
            obj.operatorControlCurtailment = operators.operatorControlCurtailment;
            obj.operatorControlBattery = operators.operatorControlBattery;
            obj.operatorDisturbancePowerGeneration = operators.operatorDisturbancePowerGeneration;
            obj.operatorDisturbancePowerTransit = operators.operatorDisturbancePowerTransit;
            obj.operatorDisturbancePowerAvailable = operators.operatorDisturbancePowerAvailable;
        end
        
        function changeOperatorStateDueToBattery(obj, controlCycle)
            rowRange = obj.numberOfBranches + obj.c + obj.b + (1:obj.b);
            columnRange = obj.numberOfBranches + obj.c + (1:obj.b);
            obj.operatorState(rowRange, columnRange) = ...
                controlCycle * obj.operatorState(rowRange, columnRange);
        end
        
        function changeOperatorControlBatteryDueToBattery(obj, controlCycle)
            rowRange = obj.numberOfBranches + obj.c + obj.b + (1:obj.b);
            obj.operatorControlBattery(rowRange, :) = ...
                controlCycle * obj.operatorControlBattery(rowRange, :);
        end
        
        function setNumberOfBuses(obj)
            obj.numberOfBuses = width(obj.operatorDisturbancePowerTransit);
        end
        
        function setNumberOfGen(obj)
            obj.c = width(obj.operatorControlCurtailment);
        end
        
        function setNumberOfBatt(obj)
            obj.b = width(obj.operatorControlBattery);
        end
        
        function setNumberOfBranches(obj)
            obj.numberOfBranches = width(obj.operatorState) - 3 * obj.c - 2 * obj.b;
        end
        
        function restrictOperatorSize(obj)
            %{
            CDC model does not take into account PA and DeltaPA,
            however the original loaded operators include them.
            As a consequence, only a subset of these operators are used for
            the CDC model
            %}
            obj.A = obj.operatorState(1: end-obj.c, 1: end-obj.c);
            obj.Bc = obj.operatorControlCurtailment(1: end-obj.c, :);
            obj.Bb = obj.operatorControlBattery(1: end-obj.c, :);
            obj.Dg = obj.operatorDisturbancePowerGeneration(1: end-obj.c, :);
            obj.Dn = obj.operatorDisturbancePowerTransit(1: end-obj.c, :);
        end
        
        function setNumberOfStateOperatorCol(obj)
            obj.numberOfStateOperatorCol = width(obj.A);
        end
        
        function setYalmipVar(obj)
            numberOfExtendedStateVar = obj.numberOfStateOperatorCol ...
                + obj.c * obj.tau_c ...
                + obj.b * obj.tau_b;
            
            % ease the debugging phase by resetting the indices of the model
            yalmip('clear');
            
            obj.x = sdpvar(numberOfExtendedStateVar, (obj.N+1) * obj.Ns, 'full');
            obj.dk_in = sdpvar( obj.c, obj.Ns*obj.N, 'full');
            obj.dk_out = sdpvar(obj.numberOfBuses, obj.Ns*obj.N, 'full');
            
            obj.u = sdpvar(obj.c + obj.b, obj.N, 'full');
            
            obj.epsilon = sdpvar(obj.numberOfBranches, obj.N, obj.Ns, 'full');
            obj.probs = sdpvar(obj.Ns, obj.N, 'full');
        end
        
        function setCostRefDeviation(obj)
            obj.Q = blkdiag(zeros(obj.numberOfBranches), ...
                eye(obj.c), eye(obj.b), zeros(obj.b),...
                zeros(obj.c), eye(obj.c * obj.tau_c), eye(obj.b) );
        end
        
        function setCostControlUse(obj)
            obj.R = blkdiag(eye(obj.c), eye(obj.b));
        end
        
        function setCostRefDeviationEp1(obj, amplifier)
            obj.Q_ep1 = amplifier * eye(obj.numberOfBranches);
        end
        
        function setMinControlCurt(obj)
            obj.umin_c = - obj.maxPG;
        end
        
        function setMaxControlCurt(obj)
            obj.umax_c = obj.maxPG;
        end
        
        function setMaxPowerGeneration(obj, value)
            obj.maxPG = value;
        end
        
        function setMinPowerBattery(obj, minInjection)
            obj.minPB = minInjection * ones(obj.b, 1);
        end
        
        function setMaxPowerBattery(obj, maxInjection)
            obj.maxPB = maxInjection * ones(obj.b, 1);
        end
        
        function setMinControlBattery(obj)
            obj.umin_b = obj.minPB - obj.maxPB;
        end
        
        function setMaxControlBattery(obj)
            obj.umax_b = obj.maxPB - obj.minPB;
        end
        
        function setMaxEpsilon(obj, maxEpsilon)
            obj.epsilon_max = maxEpsilon;
        end
        
        function setOperatorExtendedState(obj)
            block1 = blkdiag([obj.A obj.Bc], eye(obj.c * (obj.tau_c - 1) ));
            tmpNumberOfCol = obj.numberOfStateOperatorCol ...
                + obj.c * obj.tau_c;
            extendedBlock1 = [block1 ; ...
                              zeros(obj.c, tmpNumberOfCol)];
            newCol = [obj.Bb ; ...
                      zeros(obj.c * obj.tau_c, obj.b)];
            newFirstBlock = [extendedBlock1 newCol];
            combineBlock = blkdiag( newFirstBlock, eye(obj.b * (obj.tau_b - 1) ) );
            tmpNumberOfCol = obj.numberOfStateOperatorCol + obj.c * obj.tau_c + obj.b * obj.tau_b;
            obj.A_new = [combineBlock ; zeros( obj.b, tmpNumberOfCol)];
        end
        
        function setOperatorExtendedControl(obj)
            operExtControlCurt = obj.getOperatorExtendedControlCurt();
            operExtControlBatt = obj.getOperatorExtendedControlBatt();
            obj.B_new = [operExtControlCurt operExtControlBatt];
        end
        
        function value = getOperatorExtendedControlCurt(obj)
            block1 = zeros(obj.numberOfStateOperatorCol, obj.c);
            block2 = zeros(obj.c * (obj.tau_c - 1), obj.c);
            block3 = eye(obj.c);
            block4 = zeros(obj.b * obj.tau_b, obj.c);
            value = [block1; block2; block3; block4];
        end
        
        function value = getOperatorExtendedControlBatt(obj)
            block1 = zeros(obj.numberOfStateOperatorCol, obj.b);
            block2 = zeros(obj.c * obj.tau_c, obj.b);
            block3 = zeros(obj.b * (obj.tau_b - 1), obj.b);
            block4 = eye(obj.b);
            value = [block1; block2; block3; block4];
        end
        
        function setOperatorExtendedDisturbance(obj)
            tmpNumberOfRows = obj.b * obj.tau_b + obj.c * obj.tau_c;
            obj.D_new_in = [obj.Dg ; zeros( tmpNumberOfRows, obj.c)];
            obj.D_new_out = [obj.Dn ; zeros( tmpNumberOfRows, obj.numberOfBuses)];
        end
        
        function resetConstraints(obj)
            obj.constraints = [];
        end
        
        function resetObjective(obj)
            obj.objective = 0;
        end
        
        function setFlowLimit(obj, value)
            obj.flowLimit = value;
        end
        
        function setMaxEnergyBattery(obj, value)
            obj.maxEB = value;
        end
        
        function setMinState(obj)
            minFlow = - obj.flowLimit * ones(obj.numberOfBranches, 1);
            minPC = zeros(obj.c, 1);
            minEB = zeros(obj.b, 1);
            minPG = zeros(obj.c, 1);
            
            xmin_x = [minFlow ; minPC ; obj.minPB ; minEB ; minPG];
            xmin_c = repmat(obj.umin_c, obj.tau_c, 1);
            xmin_b = repmat(obj.umin_b, obj.tau_b, 1);
            
            obj.xmin = [xmin_x ; xmin_c ; xmin_b];
        end
        
        function setMaxState(obj)
            maxFlow = obj.flowLimit * ones(obj.numberOfBranches, 1);
            maxPC = obj.maxPG;
            
            xmax_x = [maxFlow ; maxPC ; obj.maxPB ; obj.maxEB ; obj.maxPG];
            xmax_c = repmat(obj.umax_c, obj.tau_c, 1);
            xmax_b = repmat(obj.umax_b, obj.tau_b, 1);
            obj.xmax = [xmax_x ; xmax_c ; xmax_b];
        end
        
        function setMinControl(obj)
            obj.umin = [obj.umin_c ; obj.umin_b];
        end
        
        function setMaxControl(obj)
            obj.umax = [obj.umax_c ; obj.umax_b];
        end
        
        %% CONSTRAINT
        
        function setConstraints(obj)
            upperBoundEpsilonBeforeDelayCurt = obj.epsilon(:, 1:obj.tau_c) <= obj.epsilon_max;
            upperBoundEpsilonBeforeDelayCurt = upperBoundEpsilonBeforeDelayCurt : 'upper bound epsilon before delay curt';
            
            noEpsilonAfterDelayCurt = obj.epsilon(:, obj.tau_c+1 : end) == 0;
            noEpsilonAfterDelayCurt = noEpsilonAfterDelayCurt : 'epsilon = 0 after delay curt';

            obj.constraints = [obj.constraints, noEpsilonAfterDelayCurt];
            
            obj.setConstraintLowerBoundControl(false);
            obj.setConstraintUpperBoundControl(false);
            obj.setConstraintEpsilonNonNegative(false);
            obj.setConstraintFlowConservation();
            
            obj.setConstraintLowerBoundFlow();
            obj.setConstraintUpperBoundFlow();
            obj.setConstraintMinPC();
            obj.setConstraintMaxPC();
            obj.setConstraintMinPB();
            obj.setConstraintMaxPB();
        end
        
        function setConstraintLowerBoundFlow(obj)
            flowVar = obj.x(1:obj.numberOfBranches, 2: end);
            minFlow = obj.xmin(1:obj.numberOfBranches);
            name = 'lower bound flow';
            constraint = flowVar >= (diag(minFlow) * (ones(obj.numberOfBranches, obj.N) + obj.epsilon));
            obj.constraints = [obj.constraints, constraint:name];
        end
        
        function setConstraintUpperBoundFlow(obj)
            flowVar = obj.x(1:obj.numberOfBranches, 2: end);
            maxFlow = obj.xmax(1:obj.numberOfBranches);
            name = 'upper bound flow';
            constraint = flowVar <= (diag(maxFlow) * (ones(obj.numberOfBranches, obj.N) + obj.epsilon));
            obj.constraints = [obj.constraints, constraint:name];
        end
        
        function setConstraintMinPC(obj)
            start = obj.numberOfBranches + 1;
            finish = start + obj.c - 1;
            powerCurtailmentVar = obj.x(start:finish, 2:end);
            constraint = powerCurtailmentVar >= 0;
            constraint = constraint:'PC >= 0';
            obj.constraints = [ obj.constraints, constraint];
        end
        
        function setConstraintMaxPC(obj)
            start = obj.numberOfBranches + 1;
            finish = start + obj.c - 1;
            powerCurtailmentVar = obj.x(start:finish, 2:end);
            maxPG_overHorizon = repmat(obj.maxPG, 1, obj.N);
            constraint = powerCurtailmentVar <= maxPG_overHorizon;
            constraint = constraint:'PC <= maxPG';
            obj.constraints = [obj.constraints, constraint];
        end
        
        function setConstraintMinPB(obj)
            start = obj.numberOfBranches + obj.c + 1;
            finish = start + obj.b - 1;
            powerBatteryVar = obj.x(start:finish, 2:end);
            minPB_overHorizon = repmat(obj.minPB, 1, obj.N);
            constraint = powerBatteryVar >= minPB_overHorizon;
            constraint = constraint:'PB >= minPB';
            obj.constraints = [obj.constraints, constraint];
        end
        
        function setConstraintMaxPB(obj)
            start = obj.numberOfBranches + obj.c + 1;
            finish = start + obj.b - 1;
            powerBatteryVar = obj.x(start:finish, 2:end);
            maxPB_overHorizon = repmat(obj.maxPB, 1, obj.N);
            constraint = powerBatteryVar <= maxPB_overHorizon;
            constraint = constraint:'PB <= maxPB';
            obj.constraints = [obj.constraints, constraint];
        end
        
        function setConstraintLowerBoundControl(obj, isItForDebug)
            arguments
                obj
                isItForDebug = false
            end
            if isItForDebug
                obj.setConstraintLowerBoundControlForDebug();
            else
                obj.setConstraintLowerBoundControlNoDebug();
            end
        end
        
        function setConstraintLowerBoundControlForDebug(obj)
            for k = 1:obj.N
                for r = 1:obj.c
                    constraintName = ['LB control u, gen ' num2str(r)];
                    constraint = obj.u(r,k) >= obj.umin(r);
                    obj.constraints = [obj.constraints, constraint:constraintName];
                end
                for r = 1:obj.b
                    rowBatt = obj.c + r;
                    constraintName = ['LB control u, batt ' num2str(r)];
                    constraint = obj.u(rowBatt,k) >= obj.umin(rowBatt);
                    obj.constraints = [obj.constraints, constraint:constraintName];
                end
            end
        end
        
        function setConstraintLowerBoundControlNoDebug(obj)
            minControl = repmat(obj.umin, 1, obj.N);
            constraintName = 'lower bound control u';
            constraint = obj.u >= minControl;
            obj.constraints = [obj.constraints, constraint:constraintName];
        end
        
        function setConstraintUpperBoundControl(obj, isItForDebug)
            arguments
                obj
                isItForDebug = false
            end
            if isItForDebug
                obj.setConstraintUpperBoundControlForDebug();
            else
                obj.setConstraintUpperBoundControlNoDebug();
            end
        end
        
        function setConstraintUpperBoundControlForDebug(obj)
            for k = 1:obj.N
                for r = 1:obj.c
                    constraintName = ['UB control u, gen ' num2str(r)];
                    constraint = obj.u(r,k) <= obj.umax(r);
                    obj.constraints = [obj.constraints, constraint:constraintName];
                end
                for r = 1:obj.b
                    rowBatt = obj.c + r;
                    constraintName = ['UB control u, batt ' num2str(r)];
                    constraint = obj.u(rowBatt,k) <= obj.umax(rowBatt);
                    obj.constraints = [obj.constraints, constraint:constraintName];
                end
            end
        end
        
         function setConstraintUpperBoundControlNoDebug(obj)
            maxControl = repmat(obj.umax, 1, obj.N);
            constraintName = 'upper bound control u';
            constraint = obj.u <= maxControl;
            obj.constraints = [obj.constraints, constraint:constraintName];
        end
        
        function setConstraintEpsilonNonNegative(obj, isItForDebug)
            arguments
                obj
                isItForDebug = false
            end
            if isItForDebug
                obj.setConstraintEpsilonNonNegativeForDebug();
            else
                obj.setConstraintEpsilonNonNegativeNoDebug();
            end
        end
        
        function setConstraintEpsilonNonNegativeForDebug(obj)
             for k = 1:obj.N
                 for r = 1:obj.numberOfBranches
                     constraintName = ['epsilon(' num2str(r) ',' num2str(k) ') >= 0'];
                     constraint = obj.epsilon(r,k) >= 0;
                     obj.constraints = [obj.constraints, constraint:constraintName];
                 end
             end
        end
        
        function setConstraintEpsilonNonNegativeNoDebug(obj)
            constraint = (obj.epsilon >= 0):'epsilon >= 0';
            obj.constraints = [obj.constraints, constraint];
        end
        
        function setConstraintFlowConservation(obj)
            constraint = obj.x(:,2:end) == ...
                obj.A_new*obj.x(:,1: end-1) + obj.B_new*obj.u + obj.D_new_in*obj.dk_in + obj.D_new_out*obj.dk_out;
            constraintWithName = constraint : 'flow conservation';
            obj.constraints = [obj.constraints, constraintWithName];
        end
        
        %% OBJECTIVE
        function setObjective(obj)
            % inspired from method setMpcFormulation and Hung's model
            % CAUTIOUS: scenarios are not taken into consideration
            
            % reset the objective defined in 'setMpcFormulation'
            obj.resetObjective();
            
            for k = 1:obj.tau_b
                obj.objective = obj.objective + obj.x(:,k+1)' * obj.Q * obj.x(:,k+1) ...
                                              + obj.u(:,k)'*obj.R*obj.u(:,k);
            end
            
            for k = obj.tau_b+1 : obj.tau_c
                obj.objective = obj.objective + obj.x(:,k+1)' * obj.Q * obj.x(:,k+1) ...
                                              + obj.u(:,k)'*obj.R*obj.u(:,k);
            end
            
            for k = obj.tau_c+1:obj.N
                obj.objective = obj.objective + obj.x(:,k+1)' * obj.Q * obj.x(:,k+1) ...
                                              + obj.u(:,k)'*obj.R*obj.u(:,k);
            end
            
            for k = 1:obj.N
                obj.objective = obj.objective + obj.epsilon(:,k,1)'*obj.Q_ep1*obj.epsilon(:,k,1);
            end
        end
        
        function setObjective_penalizeControl(obj)
            obj.objective = sum(obj.u, 'all');
        end
        
        function setObjective_penalizeControlAndEpsilon(obj)
            obj.objective = sum(obj.u, 'all') + sum(obj.epsilon, 'all');
        end
        
        function setObjective_penalizeSumSquaredControlAndEpsilon(obj)
            % function sumsqr not compatible with sdpvar
            coefEpsilon = 10^6;
            obj.objective = 0;
            [ur, uc] = size(obj.u);
            for k = 1:ur
                for l = 1:uc
                    obj.objective = obj.objective + obj.u(k,l)^2;
                end
            end
            [er, ec] = size(obj.epsilon);
            for k = 1:er
                for l = 1:ec
                    obj.objective = obj.objective + coefEpsilon * obj.epsilon(k,l)^2; % TODO: it seems the indices k and l are not in the correct order
                end
            end
        end

        function setObjective_overflow_curtCtrl_battState_Penalty(obj)
            % Set the cost function to be:
            % overflowEpsilon + DeltaPC + PBˆ2
            overflowCost = obj.N * sum( obj.minPB .^ 2);
            batteryStateCost = 1;
            
            overflowObj = overflowCost * sum(obj.epsilon,"all");

            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = overflowCost * N_to_1 * sum(obj.u(1:obj.c,:), 1)';

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
            
            battStateObj = batteryStateCost * sum( state_battery .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj +  battStateObj;

            % ISSUE: the peanlization of the battery state leads the
            % controller to draw immediately the battery power to 0 when
            % there is no congestion, thus the battery discharge control
            % should be restricted
        end

        function setObjective_overflow_curtCtrl_Penalty(obj)
            % Set the cost function to be:
            % overflowEpsilon + DeltaPC
            overflowCost = obj.N * sum(obj.minPB .^ 2);
            overflowObj = overflowCost * sum(obj.epsilon,"all");
            
            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = overflowCost * N_to_1 * sum(obj.u(1:obj.c,:), 1)';

            obj.objective = overflowObj + curtCtrlObj;
        end

        function setObjective_overflow_curtCtrl_battCtrl_Penalty(obj)
            % Set the cost function to be:
            % overflowEpsilon + DeltaPC + DeltaPB^2
            overflowCost = obj.N * sum( obj.minPB .^ 2);
            overflowObj = overflowCost * sum(obj.epsilon, "all");

            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = overflowCost * N_to_1 * sum(obj.u(1:obj.c,:), 1)';
            
            
            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = overflowCost / 100 * N_to_1 * sum(battCtrl .^ 2, 1)';
            
            obj.objective = overflowObj + curtCtrlObj + battCtrlObj;
        end

        function setObjective_inspiration1(obj)
            % 200 * overflow + 10_000 * DeltaPC + DeltaPB^2 + 0.1 * PB^2
                coefOverflow = 200;
                coefCurtCtrl = 10^4;
                coefBattCtrl = 1;
                coefBattState = 0.1;

                overflowObj = coefOverflow * sum( obj.epsilon,"all");
                
                curtCtrlObj = coefCurtCtrl * sum(obj.u(1:obj.c,:), "all");
            
                battIdxRange = (obj.c + 1) : (obj.c + obj.b);
                battCtrl = obj.u(battIdxRange, :);
                battCtrlObj = coefBattCtrl * sum(battCtrl .^ 2, "all");

                indexFirstPB = obj.numberOfBranches + obj.c + 1;
                indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
                state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
            
                battStateObj = coefBattState * sum( state_battery .^ 2 ,"all");

                obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_inspiration2(obj)
            % 100 * DeltaPC + 1 * PB^2
            % DeltaPB <= 5/100 PBmax
            coefCurtCtrl = 10^5;
            coefBattState = 1;
            
            curtCtrlObj = coefCurtCtrl * sum(obj.u(1:obj.c,:), "all");

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
        
            battStateObj = coefBattState * sum( state_battery .^ 2 ,"all");

            obj.objective = curtCtrlObj + battStateObj;
        end

        function setObjective_inspiration3(obj)
            coefCurtCtrl = 10^4;
            coefBattCtrl = 1;
            coefBattState = 10;

            curtCtrlObj = coefCurtCtrl * sum(obj.u(1:obj.c,:), "all");


            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
        
            battStateObj = coefBattState * sum( state_battery .^ 2 ,"all");

        end

        function setObjective_Alessio(obj)
            coefOverflow = 10^4;
            coefCurtCtrl = 10^4;
            coefBattCtrl = 1;
            coefBattState = 10^(-2);

            overflowObj = coefOverflow * sum( obj.epsilon,"all");

            curtCtrlObj = coefCurtCtrl * sum(obj.u(1:obj.c,:), "all");

            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = coefBattCtrl * sum(battCtrl .^ 2, "all");

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
        
            battStateObj = coefBattState * sum( state_battery .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Alessio2(obj)
            coefOverflow = 10^4;
            coefCurtCtrl = 10^4;
            coefBattCtrl = 1;
            coefBattState = 10^(-2);

            overflowObj = coefOverflow * sum( obj.epsilon,"all");

            % preference for late curtailment controls
            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = coefCurtCtrl * N_to_1 * sum(obj.u(1:obj.c,:), 1)';

            % Preference for early battery controls
            one_to_N = 1:obj.N;
            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = coefBattCtrl * one_to_N * sum(battCtrl .^ 2, 1)';

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            state_battery = obj.x(indexFirstPB:indexLastPB, 2:end);
        
            battStateObj = coefBattState * sum( state_battery .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjectiveSorin(obj)
            coefOverflow = 10^6;
            coefCurtCtrl = 10^4;
            coefBattCtrl = 1;
            coefBattState = 10^(-2);
            
            overflowObj = coefOverflow * sum( obj.epsilon,"all");

            % preference for late curtailment controls
            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = coefCurtCtrl * N_to_1 * sum(obj.u(1:obj.c,:), 1)';

            % preference for battery controls on the 1st step
            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = coefBattCtrl * battCtrl(:, 1) .^ 2; % cautious, it works because there is only 1 battery
            constraintNoBatteryControlAfter1 = battCtrl(:, 2:end) == 0;
            obj.constraints = [obj.constraints, constraintNoBatteryControlAfter1];


            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.numberOfBuses;
            batteryState = obj.x(indexFirstPB:indexLastPB, 2:end);
            battStateObj = coefBattState * sum( batteryState .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjectiveSorinNoBattery(obj)
            coefOverflow = 10^6;
            coefCurtCtrl = 10^4;
            overflowObj = coefOverflow * sum( obj.epsilon,"all");

            % preference for late curtailment controls
            N_to_1 = fliplr(1:obj.N);
            curtCtrlObj = coefCurtCtrl * N_to_1 * sum(obj.u(1:obj.c,:), 1)';

            obj.objective = overflowObj + curtCtrlObj;

            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            obj.constraints = [obj.constraints, battCtrl == 0];
        end

        function setObjective_Guillaume1(obj)
            highCoef = obj.N * obj.minPB^2;
            overflowObj = highCoef * sum( obj.epsilon,"all");
            
            curtCtrl = obj.u(1:obj.c, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            battCtrlObj = sum(battCtrl .^2, "all");

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.b;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.b+1:end);
            battStateObj = sum( batteryState .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Guillaume2(obj)
            highCoef = obj.N * obj.minPB^2;
            overflowObj = highCoef * sum( obj.epsilon,"all");
            
            curtCtrl = obj.u(1:obj.c, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            allButFirstBattCtrl = battCtrl(:, 2:end);
            battCtrlObj = highCoef * sum(allButFirstBattCtrl .^2, "all");

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.b;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.b+1:end);
            battStateObj = sum( batteryState .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
        end

        function setObjective_Guillaume3(obj)
            highCoef = obj.N * obj.minPB^2;
            overflowObj = highCoef * sum( obj.epsilon,"all");
            
            curtCtrl = obj.u(1:obj.c, :);
            curtCtrlObj = highCoef * sum(curtCtrl, "all");

            indexFirstPB = obj.numberOfBranches + obj.c + 1;
            indexLastPB = obj.numberOfBranches + obj.c + obj.b;
            batteryState = obj.x(indexFirstPB:indexLastPB, obj.b+1:end);
            battStateObj = sum( batteryState .^ 2 ,"all");

            obj.objective = overflowObj + curtCtrlObj + battStateObj;
        end

        function setObjective_Guillaume1_NoBattery(obj)
            overflowObj = sum( obj.epsilon,"all");
            curtCtrl = obj.u(1:obj.c, :);
            curtCtrlObj = sum(curtCtrl, "all");
            obj.objective = overflowObj + curtCtrlObj;

            battIdxRange = (obj.c + 1) : (obj.c + obj.b);
            battCtrl = obj.u(battIdxRange, :);
            obj.constraints = [obj.constraints, battCtrl == 0];
        end
        
        function setUselessObjectiveSearchingForFeasibility(obj)
            obj.resetObjective();
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
            if (obj.Ns == 1)
                parameters = {obj.x(:,1), obj.dk_in, obj.dk_out};
            else
                parameters = {obj.x(:,1), obj.dk_in, obj.dk_out , obj.probs};
            end
            outputs = {obj.u,obj.epsilon,obj.x};
            obj.controller = optimizer(obj.constraints, obj.objective, obj.sdp_setting, parameters, outputs);
        end
        
    end
        
        %% CLOSED LOOP SIMULATION
        
    properties
       real_short_state
       Real_state % = real extended state, #( n + c*tau_c + b*tau_b) x #simIterations
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
       PG_est_record  % #gen x #iterations x #scenarios
       delta_PG_disturbances % #gen x (#predictionHorizon * #scenarios) x #simIterations
       flags % #simIterations
       epsilons_all % #branch x #horizonPrediction x #scenarios x simIterations
       u_mpc % #gen+1 x #simIterations
       
       xK_new % the new state received at each iteration of the simulation
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
        
        function buildReal_state(obj)
            numberOfDelayedCurtCtrl = obj.c * obj.tau_c;
            numberOfDelayedBatteryCtrl = obj.b * obj.tau_b;
            totalNumberOfCtrlVar = numberOfDelayedCurtCtrl + numberOfDelayedBatteryCtrl;
            numberOfExtendedStateVar =  obj.numberOfStateOperatorCol + totalNumberOfCtrlVar;
            obj.Real_state = NaN(numberOfExtendedStateVar, numberOfIterations);
        end
        
        function setxK_new(obj, state)
            obj.xK_new = state;
        end
        
        function initialize_xK_extend(obj, state)
            noCurtControlAfter = zeros(obj.c * obj.tau_c, 1);
            noBatteryControlAfter = zeros(obj.b * obj.tau_b, 1);
            
            obj.xK_extend(:,1) = [state ; ...
                               noCurtControlAfter;...
                               noBatteryControlAfter];
        end
        
        function initializeReal_state(obj)
            % dependency: initialize_xK_extend runs first
            obj.Real_state(:,1) = obj.xK_extend;
        end
        
        function initializePastCurtControls(obj)
            obj.ucK_delay = zeros(obj.c, obj.tau_c);
        end
        
        function initializePastBattControls(obj)
            obj.ubK_delay = zeros(obj.b, obj.tau_b);
        end
        
        function recallWhatIsDone(obj)
            %{
            at each step:
            DeltaPC: delayed controls known, the extra remaining controls
            not computed yet are = 0 for the rest of the prediction horizon
            
            thus, all PC of the prediction horizon are computable
            
            DeltaPA considered constant for the moment on the whole
            prediction horizon
            
            thus, all PA of the prediction horizon are computable
            
            the initial PG is known from the current state.
            thus all the DeltaPG and PG are computable for the prediction horizon
            
            DeltaPT: for now they are considered null for the whole
            prediction horizon
            later it will be changed
            %}
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
            realState = obj.state;
            realDeltaPA = obj.disturbancePowerAvailable;
            realDeltaPT = obj.disturbancePowerTransit;
            obj.operateOneOperation(realState, realDeltaPA, realDeltaPT);
        end
        
        function object = getControl(obj)
            curtControl = obj.ucK_new;
            battControl = obj.ubK_new;
            object = ControlOfZone(curtControl, battControl);
        end
        
        function operateOneOperation(obj, realState, realDeltaPA, realDeltaPT)
            arguments
                obj
                realState StateOfZone
                realDeltaPA (:,1)
                realDeltaPT (:,1)
            end
            
            obj.decomposeState(realState);
            
            obj.setDelta_PA_est_constant_over_horizon(realDeltaPA);
            obj.setPA_over_horizon();
            
            obj.setDelta_PC_est_over_horizon();
            obj.setPC_est_over_horizon();
            
            obj.setDelta_PG_and_PG_est_over_horizon();
            obj.setDelta_PT_over_horizon(realDeltaPT);
            
            obj.set_xK_extend(realState);
            
            obj.doControl();
            
            obj.checkSolvingFeasibility();
            obj.interpretResult();
            
            obj.saveInfeas();
            obj.saveEpsilon();
            
            obj.updatePastCurtControls();
            obj.updatePastBattControls();
        end
        
        function decomposeState(obj, state)
            arguments
                obj
                state StateOfZone
            end
            Fij = state.getPowerFlow();
            PC = state.getPowerCurtailment();
            PB = state.getPowerBattery();
            EB = state.getEnergyBattery();
            PG = state.getPowerGeneration();
            PA = state.getPowerAvailable();
            obj.PA_est(:,1) = PA;
            obj.PC_est(:,1) = PC;
            obj.PG_est(:,1) = PG;
        end
        
        function setDelta_PA_est_constant_over_horizon(obj, realDeltaPA)
            % Pre-requisite: PA set up, i.e. correct PA_est(:,1)
            areAllDeltaPANonNegative = all(realDeltaPA >= 0);
            if areAllDeltaPANonNegative
                obj.Delta_PA_est = repmat(realDeltaPA, 1, obj.N);
            else
                for g = 1:obj.c
                    deltaPAOfGen = realDeltaPA(g,1);
                    if deltaPAOfGen >= 0
                        obj.Delta_PA_est(g,1:obj.N) = deltaPAOfGen;
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
            if n >= obj.N
                obj.Delta_PA_est(genIndex, 1:obj.N) = deltaPAOfGen;
            else
                obj.Delta_PA_est(genIndex, 1:n) = deltaPAOfGen;
                
                DeltaPAToReachZero = - realPAOfGen - deltaPAOfGen * n;
                obj.Delta_PA_est(genIndex, n + 1) = DeltaPAToReachZero;
                
                obj.Delta_PA_est(genIndex, n+2 : obj.N) = 0;
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
            for k = 1:obj.N
                obj.PA_est(:,k+1) = obj.PA_est(:,1) + sum(obj.Delta_PA_est(:,1:k),2);
            end
        end
        
        function setDelta_PC_est_over_horizon(obj)
            numberOfStepsAfterDelay = obj.N - obj.tau_c;
            noCurtControlAfter = zeros(obj.c, numberOfStepsAfterDelay);
            obj.Delta_PC_est = [obj.ucK_delay noCurtControlAfter];
        end
        
        function setPC_est_over_horizon(obj)
            for k = 1: obj.N
                obj.PC_est(:,k+1) = obj.PC_est(:,k) + obj.Delta_PC_est(:,k);
            end
        end
        
        function setDelta_PG_and_PG_est_over_horizon(obj)
            for k = 1: obj.N
                f = obj.PA_est(:,k+1) - obj.PG_est(:,k) + obj.Delta_PC_est(:,k);
                % f = obj.PA_est(:,k) - obj.PG_est(:,k) + obj.Delta_PA_est(:,k) + obj.Delta_PC_est(:,k);
                g = obj.maxPG - obj.PC_est(:,k) - obj.PG_est(:,k);
                obj.Delta_PG_est(:,k) = min(f, g);
                obj.PG_est(:,k+1) = obj.PG_est(:,k) + obj.Delta_PG_est(:,k) - obj.Delta_PC_est(:,k);
                %{
                This is an attempt at improving the numerical computation
                of the disturbance Delta_PG_est in order to solve the
                numerical approximation responsible for PG < 0 in the MPC
                if f <= g
                    obj.PG_est(:,k+1) = obj.PA_est(:,k+1);
                    obj.Delta_PG_est(:,k) = f;
                else
                    obj.Delta_PG_est(:,k) = min(f, g);
                    obj.PG_est(:,k+1) = obj.PG_est(:,k) + obj.Delta_PG_est(:,k) - obj.Delta_PC_est(:,k);
                end
                %}
            end
        end
        
        function setDelta_PT_over_horizon(obj, realDeltaPT)
            obj.Delta_PT_est = repmat(realDeltaPT, 1, obj.N);
        end
        
        function set_xK_extend(obj, realState)
            stateVector = realState.getStateAsVector();
            stateVectorMinusPA = stateVector(1: end-obj.c);
            pastCurtControlVector = reshape(obj.ucK_delay, [], 1);
            pastBattControlVector = reshape(obj.ubK_delay, [], 1);
            
            obj.xK_extend = [stateVectorMinusPA ; ...
                             pastCurtControlVector ; ...
                             pastBattControlVector];
        end
        
        function doControl(obj)
            [obj.result, obj.infeas] = obj.controller{obj.xK_extend, ...
                obj.Delta_PG_est, obj.Delta_PT_est};
        end
        
        function checkSolvingFeasibility(obj)
            if obj.infeas ~= 0
                disp(yalmiperror(obj.infeas))
            end
        end
        
        function saveInfeas(obj)
            obj.flags(end+1) = obj.infeas;
        end
        
        function interpretResult(obj)
            optimalControlOverHorizon = obj.result{1};
            optimalNextControl = optimalControlOverHorizon(:,1);
            rangeGen = 1:obj.c;
            optimalCurtControl = optimalNextControl(rangeGen,1);
            obj.ucK_new = optimalCurtControl;
            rangeBatt = obj.c+1 : obj.c+obj.b;
            optimalBattControl = optimalNextControl(rangeBatt,1);
            obj.ubK_new = optimalBattControl;
        end
        
        function saveEpsilon(obj)
            obj.epsilons_all(end+1,:,:) = obj.result{2};
        end
        
        function updatePastCurtControls(obj)
            leftCurtControls = obj.ucK_delay(:,2 :obj.tau_c);
            obj.ucK_delay = [leftCurtControls obj.ucK_new];
        end
        
        function updatePastBattControls(obj)
            leftBattControls = obj.ubK_delay(:, 2: obj.tau_b);
            obj.ubK_delay = [leftBattControls obj.ubK_new];
        end

        function saveControl(obj, memory)
            curtControl = obj.ucK_new;
            battControl = obj.ubK_new;
            memory.saveControl(curtControl, battControl);
        end
        
    end
    
end