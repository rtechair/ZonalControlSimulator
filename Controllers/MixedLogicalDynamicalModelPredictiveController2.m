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
classdef MixedLogicalDynamicalModelPredictiveController2 < Controller
    properties (SetAccess = private)
        n_bus
        n_branch
        n_gen
        n_batt

        delayCurt
        delayBatt

        horizon

        Flow
        PC
        
        PB
        EB
        PG

        DeltaPB
        DeltaPC
        
        isPALimiting
        overflow

        estimatedPA
        estimatedDeltaPT

        pastDeltaPC
        pastDeltaPB
        
        maxPG
        maxPA
        maxPB
        minPB
        maxEB
        maxFlow

        ptdfBranchPerBus
        ptdfBranchPerBusOfGen
        ptdfBranchPerBusOfBatt

        samplingTime
        coefBatt

        initialFlow
        initialPB
        initialEB
        initialPC
        initialPG

        constraints
        objective
    end

    methods
        function obj = MixedLogicalDynamicalModelPredictiveController2(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                delayCurt, delayBatt, horizonInIterations, ptdf1, ptdf2, ptdf3, ...
                samplingTime, coefBatt, maxPowerGeneration, minPowerBattery, maxPowerBattery)
            obj.n_bus = numberOfBuses;
            obj.n_branch = numberOfBranches;
            obj.n_gen = numberOfGen;
            obj.n_batt = numberOfBatt;

            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            obj.horizon = horizonInIterations;

            obj.ptdfBranchPerBus = ptdf1;
            obj.ptdfBranchPerBusOfGen = ptdf2;
            obj.ptdfBranchPerBusOfBatt = ptdf3;

            obj.samplingTime = samplingTime;
            obj.coefBatt = coefBatt;

            obj.maxPG = maxPowerGeneration;
            obj.minPB = minPowerBattery;
            obj.maxPB = maxPowerBattery;

        end
    
        function buildYalmipVariables(obj)
            % https://yalmip.github.io/example/standardmpc/
            % to integrate the initial state
            obj.Flow = sdpvar(obj.n_branch, obj.horizon + 1, "full");    
            
            obj.PB = sdpvar(obj.n_batt, obj.horizon + 1, "full");
            obj.EB = sdpvar(obj.n_batt, obj.horizon + 1, "full");
            obj.PC = sdpvar(obj.n_gen, obj.horizon + 1, "full");
            obj.PG = sdpvar(obj.n_gen, obj.horizon + 1, "full");
            obj.isPALimiting = binvar(obj.n_gen, obj.horizon, "full");

            obj.DeltaPC = sdpvar(obj.n_gen, obj.horizon, "full");
            obj.DeltaPB = sdpvar(obj.n_batt, obj.horizon, "full");

            obj.overflow = sdpvar(obj.n_branch, obj.delayCurt - obj.delayBatt, "full");
        end

        function setConstraints(obj)
            % https://yalmip.github.io/example/standardmpc/
            % the initial state should also be a variable to ease the
            % setting up of the modelling
            defPC =  obj.PC(:, 2:end) == obj.PC(:, 1: end-1) + obj.DeltaPC(:, 1:end);
            defPB = obj.PB(:, 2:end) == obj.PB(:, 1:end-1) + obj.DeltaPB(:, 1: end);
            defEB = obj.EB(:, 2:end) == obj.EB(:, 1: end-1) + obj.samplingTime * obj.coefBatt * obj.PB(:, 2:end);

            constraintPC = obj.PC <= obj.maxPG;
            constraintPB = obj.minPB <= obj.PB <= obj.maxPB;
            
            constraintDeltaPC = 0 <= obj.DeltaPC;
            constraintOverflow = 0 <= obj.overflow;

            stepRange = obj.delayCurt+2 :  obj.horizon+1;
            constraintNoOverflow = - obj.maxFlow <= obj.Flow(:, stepRange) <= obj.maxFlow;
        end

        function buildYalmipVariables2(obj)
            obj.Flow = sdpvar(obj.n_branch, obj.horizon, "full");            
            
            obj.PB = sdpvar(obj.n_batt, obj.horizon - obj.delayBatt, "full");
            obj.EB = sdpvar(obj.n_batt, obj.horizon - obj.delayBatt, "full");
            obj.PC = sdpvar(obj.n_gen, obj.horizon - obj.delayCurt, "full");
            obj.PG = sdpvar(obj.n_gen, obj.horizon - obj.delayCurt, "full");
            obj.isPALimiting = binvar(obj.n_gen, obj.horizon - obj.delayCurt, "full");

            obj.DeltaPC = sdpvar(obj.n_gen, obj.horizon, "full");
            obj.DeltaPB = sdpvar(obj.n_batt, obj.horizon, "full");

            obj.overflow = sdpvar(obj.n_branch, obj.delayCurt - obj.delayBatt, "full");
        end

        

        function setConstraintDynamicalState2(obj)

            defPC =  obj.PC(:, 2:end) == obj.PC(:, 1: end-1) + obj.DeltaPC(:, 2: end-1);
            defInitialPC = obj.PC(:, 1) == obj.initialPC + obj.DeltaPC(:, 1);

            defPB = obj.PB(:, 2:end) == obj.PB(:, 1:end-1) + obj.DeltaPB(:, 2: end-1);
            defInitialPB = obj.PB(:, 1) == obj.initialPB + obj.DeltaPB(:, 1);

            defEB = obj.EB(:, 2:end) == obj.EB(:, 1: end-1) + obj.samplingTime * obj.coefBatt * obj.PB(:, 2:end);
            defInitialEB = obj.EB(:, 1) == obj.initialEB + obj.PB(:, 1);
            
            constraintPC = obj.PC <= obj.maxPG;
            constraintPB = obj.minPB <= obj.PB <= obj.maxPB;
            
            constraintDeltaPC = 0 <= obj.DeltaPC;
            constraintOverflow = 0 <= obj.overflow;

            stepRange = obj.delayCurt+1 :  obj.horizon;
            constraintNoOverflow = - obj.maxFlow <= obj.Flow(:, stepRange) <= obj.maxFlow;

            stepRange = obj.delayBatt+1 : obj.delayCurt;
            constraintAllowedOverflow = - obj.maxFlow - obj.overflow <= obj.Flow(:, stepRange) <= obj.maxFlow + obj.overflow;

            % def PG
            stepRange = obj.delayCurt+1 : obj.horizon;
            PA = obj.estimatedPA(:, stepRange);
            defIsPALimiting = - obj.maxPG * obj.isPALimiting <= PA - obj.maxPG + obj.PC <= obj.maxPA * (1 - obj.isPALimiting);

            defPGequalsPA = PA - obj.maxPA * (1 - obj.isPALimiting) <= obj.PG <= PA;
            defPGequalsCurtailedGen = obj.maxPG * (1 - obj.isPALimiting) - obj.PC <= obj.PG <= obj.maxPG - obj.PC;

            defFlow = obj.Flow(:, 2:end) == obj.Flow(:, 1: end-1) + ...
                obj.ptdfBranchPerBusOfGen * ( obj.PG(:, 2:end) - obj.PG(:, 1: end-1) ) + ...
                obj.ptdfBranchPerBusOfBatt * obj.DeltaPB(:, 2:end) + ...
                obj.ptdfBranchPerBus * obj.estimatedDeltaPT(:, 2:end);

            defInitialFlow = obj.Flow(:, 1) == obj.initialFlow + ...
                obj.ptdfBranchPerBusOfGen * ( obj.PG(:, 1) - obj.initialPG) + ...
                obj.ptdfBranchPerBusOfBatt * obj.DeltaPB(:, 1) + ...
                obj.ptdfBranchPerBus * obj.estimatedDeltaPT(:, 1);


            obj.constraints = defPC;
            obj.constraints = [obj.constraints, defInitialPC];
            obj.constraints = [obj.constraints, defPB];
            obj.constraints = [obj.constraints, defInitialPB];
            obj.constraints = [obj.constraints, defEB];
            obj.constraints = [obj.constraints, defInitialEB];

            obj.constraints = [obj.constraints, constraintPC];
            obj.constraints = [obj.constraints, constraintPB];
            obj.constraints = [obj.constraints, constraintDeltaPC];
            obj.constraints = [obj.constraints, constraintOverflow];
            obj.constraints = [obj.constraints, constraintNoOverflow];
            obj.constraints = [obj.constraints, constraintAllowedOverflow];
            obj.constraints = [obj.constraints, defIsPALimiting];
            obj.constraints = [obj.constraints, defPGequalsPA];
            obj.constraints = [obj.constraints, defPGequalsCurtailedGen];
            obj.constraints = [obj.constraints, defFlow];
            obj.constraints = [obj.constraints, defInitialFlow];

        end

        function setObjective_overflow_curtCtrl_battState_penalty(obj)
            % overflow + DeltaPC + PB^s
            overflowCoef = obj.horizon * sum(obj.minPB .^ 2);
            overflowCost = overflowCoef * sum(obj.overflow, "all");

            H_to_1 = fliplr( 1: obj.horizon);
            curtCtrlCost = overflowCoef * H_to_1 * sum(obj.DeltaPC, 1)' ;
            
            battStateCost = sum(obj.PB .^ 2j, "all");

            obj.objective = overflowCost + curtCtrlCost + battStateCost;
        end

        function setObjective_overflow_curtCtrl_penalty(obj)
            overflowCoef = obj.horizon * sum(obj.minPB .^ 2);
            overflowCost = overflowCoef * sum(obj.overflow, "all");

            H_to_1 = fliplr( 1: obj.horizon);
            curtCtrlCost = overflowCoef * H_to_1 * sum(obj.DeltaPC, 1)' ;

            obj.objective = overflowCost + curtCtrlCost;
        end

        function setObjective_overflow_curtCtrl_battCtrl_penalty(obj)
            overflowCoef = obj.horizon * sum(obj.minPB .^ 2);
            overflowCost = overflowCoef * sum(obj.overflow, "all");

            H_to_1 = fliplr( 1: obj.horizon);
            curtCtrlCost = overflowCoef * H_to_1 * sum(obj.DeltaPC, 1)' ;
            
            battCtrlCost = overflowCoef / 100 * H_to_1 * sum(obj.DeltaPB .^ 2, 1)';
            
            obj.objective = overflowCost + curtCtrlCost + battCtrlCost;
        end

        function setObjective_inspiration1(obj)
            % 200 * overflow + 10_000 * DeltaPC + DeltaPB^2 + 0.1 * PB^2
            overflowCoef = 200;
            curtCtrlCoef = 10^4;
            battCtrlCoef = 1;
            battStateCoef = 0.1;

            overflowCost = overflowCoef * sum(obj.overflow, "all");
            curtCtrlCost = curtCtrlCoef * sum(obj.DeltaPC, "all");
            battCtrlCost = battCtrlCoef * sum(obj.DeltaPB .^ 2, "all");
            battStateCost = battStateCoef * sum(obj.PB .^ 2, "all");

            obj.objective = overflowCost + curtCtrlCost + battCtrlCost + battStateCost;
        end

        function setObjective_inspiration2(obj)
            % 100 * DeltaPC + PB^2
            % add constraint DeltaPB <= maxPB * 5% ; i.e. PB can
            % increase by 5% max when the use of battery is reduced
            curtCtrlCoef = 100;
            battStateCoef = 1;
            battPercent = 5/100;
            battCtrlThreshold = battPercent * maxPowerBattery;
            curtCtrlCost = curtCtrlCoef * sum(obj.DeltaPC, "all");
            battStateCost = battStateCoef * sum(obj.PB .^ 2, "all");
        end

        function setObjective_Hung(obj)
            overflowCoef = 10^4;
            curtCtrlCoef = 1;
            battCtrlCoef = 1;
            battStateCoef = 10^(-3);

            overflowCost = overflowCoef * sum(obj.overflow .^ 2, "all");
            curtCtrlCost = curtCtrlCoef * sum(obj.DeltaPC .^ 2, "all");
            battCtrlCost = battCtrlCoef * sum(obj.DeltaPB .^ 2, "all");
            battStateCost = battStateCoef * sum(obj.PB .^ 2, "all");

            obj.objective = overflowCost + curtCtrlCost + battCtrlCost + battStateCost;
        end

        function setObjective_Alessio(obj)
            overflowCoef = 10^4;
            curtCtrlCoef = 10^4;
            battCtrlCoef = 1;
            battStateCoef = 10^(-2);

            overflowCost = overflowCoef * sum(obj.overflow, "all");
            curtCtrlCost = curtCtrlCoef * sum(obj.DeltaPC, "all");
            battCtrlCost = battCtrlCoef * sum(obj.DeltaPB .^ 2, "all");
            battStateCost = battStateCoef * sum(obj.PB .^ 2, "all");

            obj.objective = overflowCost + curtCtrlCost + battCtrlCost + battStateCost;
        end

        function setYalmipOptimizer(obj)
            parameters = {obj.Flow(:, 1), obj.PB(:, 1), obj.EB(:, 1), obj.PC(:, 1), obj.PG(:, 1)};
        end

    end
end