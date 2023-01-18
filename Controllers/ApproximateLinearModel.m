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
classdef ApproximateLinearModel < handle
        properties (SetAccess = protected)
            numberOfBuses
            numberOfBranches
            numberOfGen
            numberOfBatt
            
            branchPerBusPTDF    % Mt
            branchPerBusOfGenPTDF %Mc
            branchPerBusOfBattPTDF %Mb

            batteryCoef
            timestep
            latencyCurt
            latencyBatt

            operatorState
            operatorControlCurtailment
            operatorControlBattery
            operatorDisturbancePowerGeneration
            operatorDisturbancePowerTransit

            operatorStateExtended
            operatorControlExtended
            operatorDisturbancePowerGenerationExtended
            operatorDisturbancePowerTransitExtended
        end

        methods
            % look at buildMathemathicalModel
            function obj = ApproximateLinearModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep,...
                    latencyCurt, latencyBatt)
                arguments
                    numberOfBuses (1,1) {mustBeInteger, mustBePositive}
                    numberOfBranches (1,1) {mustBeInteger, mustBePositive}
                    numberOfGen (1,1) {mustBeInteger, mustBePositive}
                    numberOfBatt (1,1) {mustBeInteger}
                    branchPerBusPTDF
                    branchPerBusOfGenPTDF
                    branchPerBusOfBattPTDF
                    batteryCoef
                    timestep    (1,1) {mustBeInteger, mustBePositive}
                    latencyCurt
                    latencyBatt
                end
                obj.numberOfBuses = numberOfBuses;
                obj.numberOfBranches = numberOfBranches;
                obj.numberOfGen = numberOfGen;
                obj.numberOfBatt = numberOfBatt;
                
                obj.branchPerBusPTDF = branchPerBusPTDF;
                obj.branchPerBusOfGenPTDF = branchPerBusOfGenPTDF;
                obj.branchPerBusOfBattPTDF = branchPerBusOfBattPTDF;

                obj.batteryCoef = batteryCoef;
                obj.timestep = timestep;
                obj.latencyCurt = latencyCurt;
                obj.latencyBatt = latencyBatt;

                obj.setOperatorState();
                obj.setOperatorControlCurtailment();
                obj.setOperatorControlBattery();
                obj.setOperatorDisturbancePowerGeneration();
                obj.setOperatorDisturbancePowerTransit();

                obj.setOperatorExtendedState();
                obj.setOperatorExtendedControl();
                obj.setOperatorExtendedDisturbance();
            end

            function setOperatorState(obj)
                %{
                    Fij(k+1) += Fij(k)
                    Pc(k+1) += Pc(k)
                    Pb(k+1) += Pb(k)
                    Eb(k+1) += Eb(k)
                    Pg(k+1) += Pg(k)
                %}
                numberOfCol = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorState = eye(numberOfCol);

                % Eb(k+1) -= timestep*diag(batteryCoef)*Pb(k)
                % if there is no battery, then the following lines won't do anything,
                % because the concerned submatrix will be an empty matrix
                firstRow = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt + 1;
                firstCol = obj.numberOfBranches + obj.numberOfGen + 1;
                rowRange = firstRow : firstRow+obj.numberOfBatt-1;
                colRange = firstCol : firstCol+obj.numberOfBatt-1;
                obj.operatorState(rowRange, colRange) = - obj.timestep * diag(obj.batteryCoef);
            end

            function setOperatorControlCurtailment(obj)
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorControlCurtailment = zeros(numberOfRows, obj.numberOfGen);

                %F(k+1) -= diag(branchPerBusOfGenPTDF)*DeltaPC(k-latencyCurt), i.e matrix Mc in the paper
                rowRange = 1:obj.numberOfBranches;
                obj.operatorControlCurtailment(rowRange, :) = - obj.branchPerBusOfGenPTDF;

                % PC(k+1) += DeltaPC(k-latencyCurt)
                firstRow = obj.numberOfBranches + 1;
                rowRange = firstRow : firstRow+obj.numberOfGen-1;
                obj.operatorControlCurtailment(rowRange, :) = eye(obj.numberOfGen);

                % PG(k+1) -= DeltaPC(k-latencyCurt)
                firstRow = obj.numberOfBranches + obj.numberOfGen + 2*obj.numberOfBatt + 1;
                obj.operatorControlCurtailment( firstRow:end, :) = - eye(obj.numberOfGen);
            end

            function setOperatorControlBattery(obj)
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorControlBattery = zeros(numberOfRows, obj.numberOfBatt);

                % F(k+1) += diag(branchPerBusOfBattPTDF)*DeltaPb(k-latencyBatt), i.e. matrix Mb in the paper
                rowRange = 1:obj.numberOfBranches;
                obj.operatorControlBattery(rowRange, :) = obj.branchPerBusOfBattPTDF;
                
                % PB(k+1) += DeltaPB(k-latencyBatt)
                firstRow = obj.numberOfBranches + obj.numberOfGen + 1;
                rowRange = firstRow : firstRow + obj.numberOfBatt - 1;
                obj.operatorControlBattery(rowRange, :) = eye(obj.numberOfBatt);
                
                % EB(k+1) -= T*diag(cb)*DeltaPB(k-latencyBatt), i.e. matrix -Ab in the paper
                firstRow = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt + 1;
                rowRange = firstRow : firstRow + obj.numberOfBatt - 1;
                obj.operatorControlBattery(rowRange, :) = - obj.timestep * diag(obj.batteryCoef);
            end

            function setOperatorDisturbancePowerGeneration(obj)
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorDisturbancePowerGeneration = zeros(numberOfRows, obj.numberOfGen);
                firstRow = numberOfRows - obj.numberOfGen + 1;
                % PG(k+1) += DeltaPG(k)
                obj.operatorDisturbancePowerGeneration(firstRow:end, :) = eye(obj.numberOfGen);

                % F(k+1) = ptdf * DeltaPG(k)
                obj.operatorDisturbancePowerGeneration(1:obj.numberOfBranches, :) = obj.branchPerBusOfGenPTDF;
            end
        
            function setOperatorDisturbancePowerTransit(obj)
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorDisturbancePowerTransit = zeros(numberOfRows, obj.numberOfBuses);
                % F(k+1) += ptdf * DeltaPT(k)
                obj.operatorDisturbancePowerTransit(1: obj.numberOfBranches, :) = obj.branchPerBusPTDF;
            end

            function setOperatorExtendedState(obj)
                block1 = blkdiag([obj.operatorState, obj.operatorControlCurtailment], eye(obj.numberOfGen * (obj.latencyCurt - 1) ) );
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                extendedBlock1 = [block1 ;
                                               zeros(obj.numberOfGen, numberOfRows + obj.numberOfGen * obj.latencyCurt)];
                newCol = [ obj.operatorControlBattery;
                                 zeros(obj.numberOfGen * obj.latencyCurt, obj.numberOfBatt)];
                newFirstBlock = [extendedBlock1 newCol];
                combineBlock = blkdiag(newFirstBlock, eye(obj.numberOfBatt * (obj.latencyBatt - 1)) );
                obj.operatorStateExtended = [combineBlock;
                                                                zeros(obj.numberOfBatt, numberOfRows + obj.numberOfGen * obj.latencyCurt + obj.numberOfBatt * obj.latencyBatt)];
            end

            function setOperatorExtendedControl(obj)
                operatorExtendedCtrlCurt = obj.getOperatorExtendedCtrlCurt();
                operatorExtendedCtrlBatt = obj.getOperatorExtendedCtrlBatt();
                obj.operatorControlExtended = [operatorExtendedCtrlCurt operatorExtendedCtrlBatt];
            end

            function value = getOperatorExtendedCtrlCurt(obj)
                numberOfCol = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                block1 = zeros(numberOfCol, obj.numberOfGen);
                block2 = zeros(obj.numberOfGen * (obj.latencyCurt - 1), obj.numberOfGen);
                block3 = eye(obj.numberOfGen);
                block4 = zeros(obj.numberOfBatt * obj.latencyBatt, obj.numberOfGen);
                value = [block1; block2; block3; block4];
            end

            function value = getOperatorExtendedCtrlBatt(obj)
                numberOfCol = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                block1 = zeros(numberOfCol, obj.numberOfBatt);
                block2 = zeros(obj.numberOfGen * obj.latencyCurt, obj.numberOfBatt);
                block3 = zeros(obj.numberOfBatt * (obj.latencyBatt - 1), obj.numberOfBatt);
                block4 = eye(obj.numberOfBatt);
                value = [block1; block2; block3; block4];
            end

            function setOperatorExtendedDisturbance(obj)
                tmpNumberOfRows = obj.numberOfBatt * obj.latencyBatt + obj.numberOfGen * obj.latencyCurt;
                obj.operatorDisturbancePowerGenerationExtended = [obj.operatorDisturbancePowerGeneration;
                                                                                                       zeros(tmpNumberOfRows, obj.numberOfGen)];
                obj.operatorDisturbancePowerTransitExtended = [obj.operatorDisturbancePowerTransit;
                                                                                                zeros(tmpNumberOfRows, obj.numberOfBuses)];
            end

            function A = getOperatorState(obj)
                A = obj.operatorState;
            end

            function Bc = getOperatorControlCurtailment(obj)
                Bc = obj.operatorControlCurtailment;
            end

            function Bb = getOperatorControlBattery(obj)
                Bb = obj.operatorControlBattery;
            end

            function Dg = getOperatorDisturbancePowerGeneration(obj)
                Dg = obj.operatorDisturbancePowerGeneration;
            end

            function Dn = getOperatorDisturbancePowerTransit(obj)
                Dn = obj.operatorDisturbancePowerTransit;
            end

            function value = getOperatorStateExtended(obj)
                value = obj.operatorStateExtended;
            end

            function value = getOperatorControlExtended(obj)
                value = obj.operatorControlExtended;
            end

            function value = getOperatorDisturbancePowerGenerationExtended(obj)
                value = obj.operatorDisturbancePowerGenerationExtended;
            end

            function value = getOperatorDisturbancePowerTransitExtended(obj)
                value = obj.operatorDisturbancePowerTransitExtended;
            end

        end
end