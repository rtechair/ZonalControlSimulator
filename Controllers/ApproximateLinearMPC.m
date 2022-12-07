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
        numberOfBuses
        numberOfBranches
        numberOfGen
        numberOfBatt
        tau_c
        tau_b
        N
        c
        b

        operatorStateExtended
        operatorControlExtended
        operatorNextPowerGenerationExtended
        operatorDisturbanceExtended
        
        % Parameters
        
        %% Yalmip
        x
        dk_in
        dk_out
        u
        epsilon
        
        constraints
        objective
        % Parameter
        
        maxPG
        sdp_setting
        controller

        %% Closed-loop simulation
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
        function obj = ApproximateLinearMPC(delayCurtailment, delayBattery, delayTelecom, ...
                horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ... % following: where starts setOtherElements
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit)
            
            obj.operatorStateExtended = operatorStateExtended;
            obj.operatorControlExtended = operatorControlExtended;
            obj.operatorNextPowerGenerationExtended = operatorNextPowerGenerationExtended;
            obj.operatorDisturbanceExtended = operatorDisturbanceExtended;

            
            obj.numberOfBuses = numberOfBuses;
            obj.numberOfBranches = numberOfBranches;
            obj.numberOfGen = numberOfGen;
            obj.numberOfBatt = numberOfBatt;
            
            obj.tau_c = delayCurtailment + delayTelecom;
            obj.tau_b = delayBattery + delayTelecom;
            
            obj.N = horizonInIterations;
            
            % adapt, overcome
            n = numberOfBranches + 3*numberOfGen + 2*numberOfBatt;
            nbranchNEW = numberOfBranches;
            h = numberOfBuses;
            c = numberOfGen;
            b = numberOfBatt;

            obj.c = numberOfGen;
            obj.b = numberOfBatt;

            umin_c = zeros(c,1);
            umin_b = minPowerBattery - maxPowerBattery;
            umin = [umin_c ; umin_b];

            umax_c = maxPowerGeneration;
            umax_b = - umin_b;
            umax = [umax_c ; umax_b];

            xmin = [- flowLimit * ones(nbranchNEW, 1) ; zeros(c,1); minPowerBattery; 0];
            xmax = [flowLimit *ones(nbranchNEW,1) ; maxPowerGeneration ; maxPowerBattery ; maxEnergyBattery];
            
            N = horizonInIterations;

            A_new = obj.operatorStateExtended;
            B_new = obj.operatorControlExtended;
            Bz_new = obj.operatorNextPowerGenerationExtended;
            D_new = obj.operatorDisturbanceExtended;


            % mpc_controller_design
            u_mpc = sdpvar(b+c,N,'full');  % input trajectory: u0,...,u_{N-1} (columns of U)
            x_mpc = sdpvar(n+b*obj.tau_b+c*obj.tau_c,N+1,'full'); % state trajectory: x0,x1,...,xN (columns of X)
            epsilon1 = sdpvar(nbranchNEW,obj.tau_c - obj.tau_b,'full'); % perturbation scale %constraints = [epsilon >=0];
            d_mpc = binvar(c,N,'full');
            dk = sdpvar(h+c,N,'full'); % vector of disturbance

            constraints = [];
            nbr = 1:nbranchNEW;
            constraints = [constraints, (epsilon1 >= 0) : ['epsilon ']];
             
            for k = 1:obj.tau_b
                constraints = [constraints, (x_mpc(:,k+1) == A_new*x_mpc(:,k) + B_new*u_mpc(:,k) + Bz_new*x_mpc(nbranchNEW+c+2*b+(1:c),k+1) + D_new*dk(:,k)) : ['dynamics ' num2str(k)]];
                
                constraints = [constraints, (u_mpc(:,k) <= umax): ['control max ' num2str(k)]];
                constraints = [constraints, (u_mpc(:,k) >= umin): ['control min ' num2str(k)]];
                
            end
            
            for k = obj.tau_b+1:obj.tau_c
                constraints = [constraints, (x_mpc(:,k+1) == A_new*x_mpc(:,k) + B_new*u_mpc(:,k) + Bz_new*x_mpc(nbranchNEW+c+2*b+(1:c),k+1) + D_new*dk(:,k)): ['dynamics ' num2str(k)]];
                
                constraints = [constraints, (u_mpc(:,k) <= umax): ['control max ' num2str(k)]];
                constraints = [constraints, (u_mpc(:,k) >= umin): ['control min ' num2str(k)]];
                
                constraints = [constraints, ( x_mpc(nbr,k+1) <= xmax(nbr)  + epsilon1(nbr,k-obj.tau_b)) : ['branch max ' num2str(k)]];
                constraints = [constraints, ( x_mpc(nbr,k+1) >= xmin(nbr)  - epsilon1(nbr,k-obj.tau_b)) : ['branch min ' num2str(k)]];
                
                constraints = [constraints, ( x_mpc(nbranchNEW+c+(1:2*b),k+1) <= xmax(nbranchNEW+c+(1:2*b)) ) : ['battery max ' num2str(k)]];
                constraints = [constraints, ( x_mpc(nbranchNEW+c+(1:2*b),k+1) >= xmin(nbranchNEW+c+(1:2*b)) ) : ['battery min ' num2str(k)]];
                
            end
            
            for k = obj.tau_c+1:N
                constraints = [constraints, (x_mpc(:,k+1) == A_new*x_mpc(:,k) + B_new*u_mpc(:,k) + Bz_new*x_mpc(nbranchNEW+c+2*b+(1:c),k+1) + D_new*dk(:,k)): ['dynamics ' num2str(k)]];
                
                constraints = [constraints, (u_mpc(:,k) <= umax): ['control max ' num2str(k)]];
                constraints = [constraints, (u_mpc(:,k) >= umin): ['control min ' num2str(k)]];
                
                constraints = [constraints, ( x_mpc(nbr,k+1) <= xmax(nbr) ) : ['branch max ' num2str(k)]];
                constraints = [constraints, ( x_mpc(nbr,k+1) >= xmin(nbr)  ) : ['branch min ' num2str(k)]];
                
                constraints = [constraints, ( x_mpc(nbranchNEW+(1:c),k+1) <= xmax(nbranchNEW+(1:c)) ) : ['curtailment max ' num2str(k)]];
                constraints = [constraints, ( x_mpc(nbranchNEW+(1:c),k+1) >= xmin(nbranchNEW+(1:c)) ) : ['curtailment min ' num2str(k)]];
                
                constraints = [constraints, ( x_mpc(nbranchNEW+c+(1:2*b),k+1) <= xmax(nbranchNEW+c+(1:2*b)) ) : ['battery max ' num2str(k)]];
                constraints = [constraints, ( x_mpc(nbranchNEW+c+(1:2*b),k+1) >= xmin(nbranchNEW+c+(1:2*b)) ) : ['battery min ' num2str(k)]];
                
            end
            
                M = 1000;
            for k = 1 : N
                constraints = [constraints, implies( x_mpc(nbranchNEW+2*c+2*b+ (1:c),k+1) <= maxPowerGeneration - x_mpc(nbranchNEW + (1:c),k+1) , d_mpc(:,k) ) : ['delta implied ' num2str(k)]];
                constraints = [constraints, implies( d_mpc(:,k) , x_mpc(nbranchNEW+2*c+2*b+(1:c),k+1) <= maxPowerGeneration - x_mpc(nbranchNEW + (1:c),k+1) ) : ['delta implied ' num2str(k)]];
                constraints = [constraints, implies( d_mpc(:,k) , x_mpc(nbranchNEW+c+2*b+(1:c),k+1) == x_mpc(nbranchNEW+2*c+2*b+(1:c),k+1) ) : ['generator power ' num2str(k)]];
                constraints = [constraints, implies(~d_mpc(:,k) , x_mpc(nbranchNEW+c+2*b+(1:c),k+1) == maxPowerGeneration - x_mpc(nbranchNEW + (1:c),k+1) ) : ['generator power ' num2str(k)]];
                
                % This part is to avoid too large initial values of M while using 'implies' function 
                constraints = [constraints, (zeros(c,1) <= x_mpc(nbranchNEW+(1:c),k+1) <= M*ones(c,1)) : ['lousy warning PC ' num2str(k)]];
                constraints = [constraints, (zeros(c,1) <= x_mpc(nbranchNEW+c+2*b+ (1:c),k+1) <= M*ones(c,1)) : ['lousy warning PG ' num2str(k)]];
                constraints = [constraints, (zeros(c,1) <= x_mpc(nbranchNEW+2*c+2*b+ (1:c),k+1) <= M*ones(c,1)) : ['lousy warning PA ' num2str(k)]];
            end
            
            
            isObjective_overflow_curtCtrl_battState_Penalty = false;
            isObjective_overflow_curtCtrl_Penalty = false;
            isObjective_overflow_curtCtrl_battCtrl_Penalty = false;
            
            isObjective_inspiration1 = false;
            isObjective_inspiration2 = false;
            isObjective_Hung = false;
            isObjective_Alessio = false;
            isObjective_Alessio2 = false;
            isObjective_Sorin = false;
            isObjective_Sorin_NoBattery = false;

            isObjective_Guillaume1 = true;
            isObjective_Guillaume2 = false;
            isObjective_Guillaume3 = false;
            isObjective_Guillaume1_NoBattery = false;
            

            if isObjective_overflow_curtCtrl_battState_Penalty
                % overflow + DeltaPC + PB^2
               % overflowCost = N * sum(minPowerBattery .^ 2);

                % new, old Sorin's:
                coefOverflow = 10^6;
                coefCurtCtrl = 10^4;
                coefBattState = 10^(-2);

                overflowObj = coefOverflow * sum(epsilon1, "all");
                
                % preference for late curtailment controls
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * N_to_1 * sum(curtCtrl, 1)';

                % battCtrlObj = coefBattCtrl * sum(battCtrl(:,1) .^ 2, 1)';
                constraintNoBatteryCtrlAfter1Step = battCtrl(:, 2:end) == 0;
                constraints = [constraints, constraintNoBatteryCtrlAfter1Step];

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end
            if isObjective_overflow_curtCtrl_Penalty
                % copied from MpcWithUncertainty>setObjective_curtCtrl_overflow_Penalty
                overflowCost = N * sum(minPowerBattery .^ 2);
                overflowObj = overflowCost * sum(epsilon1, "all");
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = overflowCost * N_to_1 * sum(curtCtrl, 1)';
                objective = overflowObj + curtCtrlObj;
            end
            if isObjective_overflow_curtCtrl_battCtrl_Penalty
                % copied from setObjective_overflow_curtCtrl_battCtrl_Penalty
                overflowCost = N * sum(minPowerBattery .^ 2);
                overflowObj = overflowCost * sum(epsilon1, "all");
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = overflowCost * N_to_1 * sum(curtCtrl, 1)';

                battIdxRange = (c + 1) : (c + b);
                battCtrl = u_mpc(battIdxRange, :);
                battCtrlObj = overflowCost / 100 * N_to_1 * sum(battCtrl .^ 2, 1)';
                objective = overflowObj + curtCtrlObj + battCtrlObj;
            end
            if isObjective_inspiration1
                % 200 * overflow + 10_000 * DeltaPC + DeltaPB^2 + 0.1 * PB^2
                coefOverflow = 200;
                coefCurtCtrl = 10^4;
                coefBattCtrl = 1;
                coefBattState = 0.1;

                overflowObj = coefOverflow * sum( epsilon1,"all");

                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * sum(curtCtrl, "all");

                battCtrl = u_mpc (c+1 : c+b, :);
                battCtrlObj = coefBattCtrl * sum(battCtrl .^ 2, "all");

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end
            if isObjective_inspiration2
                % 100 * DeltaPC + PB^2
                % add constraint DeltaPB <= maxPB * 5% ; i.e. PB can
                % increase by 5% max when the use of battery is reduced
                coefCurtCtrl = 100;
                coefBattState = 1;
                battPercent = 5/100;
                battCtrlThreshold = battPercent * maxPowerBattery;
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * sum(curtCtrl, "all");

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = curtCtrlObj + battStateObj;

                battIdxRange = (obj.c + 1) : (obj.c + obj.b);
                battCtrl = u_mpc(battIdxRange, :);
                % constraintMaxPositiveDeltaPB = ( battCtrl <= battCtrlThreshold );
                % constraints = [constraints, constraintMaxPositiveDeltaPB];
            end
            if isObjective_Hung
                coefOverflow = 10^4;
                coefCurtCtrl = 1;
                coefBattCtrl = 1;
                coefCurtState = 1;
                coefBattState = 10^(-3);
                
                overflowObj = coefOverflow * sum(epsilon1 .^ 2, "all");

                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * sum(curtCtrl .^ 2, "all");
                
                battCtrl = u_mpc (c+1 : c+b, :);
                battCtrlObj = coefBattCtrl * sum(battCtrl .^ 2, "all");
                
                idxFirstPC = obj.numberOfBranches + 1;
                idxLastPC = obj.numberOfBranches + c;
                curtState = x_mpc(idxFirstPC : idxLastPC, 2:end);
                curtStateObj = coefCurtState * sum(curtState .^ 2, "all");

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");

                objective = overflowObj + curtCtrlObj + battCtrlObj + curtStateObj + battStateObj;
            end

            
            if isObjective_Alessio
                coefOverflow = 10^4;
                coefCurtCtrl = 10^4;
                coefBattCtrl = 1;
                coefBattState = 10^(-2);

                overflowObj = coefOverflow * sum(epsilon1, "all");
                
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * sum(curtCtrl, "all");

                battCtrl = u_mpc (c+1 : c+b, :);
                battCtrlObj = coefBattCtrl * sum(battCtrl .^ 2, "all");

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end

            if isObjective_Alessio2
                coefOverflow = 10^4;
                coefCurtCtrl = 10^4;
                coefBattCtrl = 1;
                coefBattState = 10^(-2);

                overflowObj = coefOverflow * sum(epsilon1, "all");
                
                % preference for late curtailment controls
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * N_to_1 * sum(curtCtrl, 1)';

                % preference for early battery controls
                one_to_N = 1:N;
                battCtrl = u_mpc (c+1 : c+b, :);
                battCtrlObj = coefBattCtrl * one_to_N * sum(battCtrl .^ 2, 1)';
                
                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end

            if isObjective_Sorin
                coefOverflow = 10^6;
                coefCurtCtrl = 10^4;
                coefBattCtrl = 1;
                coefBattState = 10^(-2);

                overflowObj = coefOverflow * sum(epsilon1, "all");
                
                % preference for late curtailment controls
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * N_to_1 * sum(curtCtrl, 1)';

                % preference for battery controls on the 1st step
                battCtrl = u_mpc (c+1 : c+b, :);
                % battCtrlObj = coefBattCtrl * sum(battCtrl(:,1) .^ 2, 1)';
                battCtrlObj = coefBattCtrl * battCtrl(:,1) .^ 2;
                constraintNoBatteryCtrlAfter1Step = battCtrl(:, 2:end) == 0;
                constraints = [constraints, constraintNoBatteryCtrlAfter1Step];

                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, 2:end);
                battStateObj = coefBattState * sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end
            
             if isObjective_Sorin_NoBattery
                 coefOverflow = 10^6;
                coefCurtCtrl = 10^4;
                
                overflowObj = coefOverflow * sum(epsilon1, "all");
                % preference for late curtailment controls
                N_to_1 = fliplr(1 : N);
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = coefCurtCtrl * N_to_1 * sum(curtCtrl, 1)';
                objective = overflowObj + curtCtrlObj;

                battCtrl = u_mpc (c+1 : c+b, :);
                constraintNoBatteryCtrl = battCtrl ==0;
                constraints = [constraints, constraintNoBatteryCtrl];
             end
            
            if isObjective_Guillaume1
                % Alessio's desired behavior, i.e. battery controls spread
                % over the horizon
                highCoef = N * minPowerBattery^2;

                overflowObj = highCoef * sum(epsilon1, "all");

                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = highCoef * sum(curtCtrl, "all");

                battCtrl = u_mpc (c+1 : c+b, :);
                battCtrlObj = sum(battCtrl .^2, "all");
                
                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, b+1:end);
                battStateObj = sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end

            if isObjective_Guillaume2
                % Sorin's desired behavior, i.e. battery controls at 1st step
                highCoef = N * minPowerBattery^2;

                overflowObj = highCoef * sum(epsilon1, "all");

                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = highCoef * sum(curtCtrl, "all");

                battCtrl = u_mpc (c+1 : c+b, :);
                allButFirstBattCtrl = battCtrl(:, 2:end);
                battCtrlObj = highCoef * sum(allButFirstBattCtrl .^ 2, "all");
                
                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, b+1:end);
                battStateObj = sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battCtrlObj + battStateObj;
            end

            if isObjective_Guillaume3
                % No cost on the battery control.
                highCoef = N * minPowerBattery^2;

                overflowObj = highCoef * sum(epsilon1, "all");

                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = highCoef * sum(curtCtrl, "all");
                
                idxFirstPB = obj.numberOfBranches + c + 1;
                idxLastPB = obj.numberOfBranches + c + b;
                battState = x_mpc(idxFirstPB : idxLastPB, b+1:end);
                battStateObj = sum(battState .^ 2, "all");
                
                objective = overflowObj + curtCtrlObj + battStateObj;
            end

             if isObjective_Guillaume1_NoBattery
                overflowObj = sum(epsilon1, "all");
                curtCtrl = u_mpc(1:c, :);
                curtCtrlObj = sum(curtCtrl, "all");
                objective = overflowObj + curtCtrlObj;

                battCtrl = u_mpc (c+1 : c+b, :);
                constraintNoBatteryCtrl = battCtrl ==0;
                constraints = [constraints, constraintNoBatteryCtrl];
             end

            % in the following, where starts setOtherElements method
            parameters      = {x_mpc(:,1), dk};
            outputs         = {u_mpc ,  x_mpc , epsilon1 , d_mpc};
            solverName = 'cplex'; %'cplex'
            options         = sdpsettings('solver',solverName);
            obj.controller      = optimizer(constraints, objective , options , parameters, outputs);

            obj.ucK_delay = zeros(c, obj.tau_c); % initializePastCurtControls
            obj.ubK_delay = zeros(b, obj.tau_b); % initializePastBattControls
            obj.countControls = 0;
            
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
            disp("you use the method setOtherElements, do not use it")
            obj.setSolver();
            obj.setController();
            
            obj.initializePastCurtControls();
            obj.initializePastBattControls();
            
            obj.countControls = 0;
            
        end
        
        %% OBJECTIVE
        
        function setController(obj)
            if (obj.Ns == 1)
                parameters = {obj.x(:,1), obj.dk_in, obj.dk_out};
            else
                disp("Ns is different from 1, not logical.")
            end
            outputs = {obj.u,obj.epsilon,obj.x};
            obj.controller = optimizer(obj.constraints, obj.objective, obj.sdp_setting, parameters, outputs);
        end
        
        
        %% CLOSED LOOP SIMULATION
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
            PC = state.getPowerCurtailment();
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
        
        function setDelta_PT_over_horizon(obj, realDeltaPT)
            obj.Delta_PT_est = repmat(realDeltaPT, 1, obj.N);
        end
        
        function set_xK_extend(obj, realState)
            stateVector = realState.getStateAsVector();
            pastCurtControlVector = reshape(obj.ucK_delay, [], 1);
            pastBattControlVector = reshape(obj.ubK_delay, [], 1);
            
            obj.xK_extend = [stateVector ; ...
                             pastCurtControlVector ; ...
                             pastBattControlVector];
        end
        
        function doControl(obj)
            dk_extend = [ zeros(obj.numberOfBuses, obj.N);
                obj.Delta_PA_est];
            [obj.result, obj.infeas] = obj.controller{obj.xK_extend, ...
                dk_extend};
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