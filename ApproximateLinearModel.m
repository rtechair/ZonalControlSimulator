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

            operatorState
            operatorControlCurtailment
            operatorControlBattery
            operatorDisturbancePowerGeneration
            operatorDisturbancePowerTransit
        end

        methods
            % look at buildMathemathicalModel
            function obj = ApproximateLinearModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep)
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

                obj.setOperatorState();
                obj.setOperatorControlCurtailment();
                obj.setOperatorControlBattery();
                obj.setOperatorDisturbancePowerGeneration();
                obj.setOperatorDisturbancePowerTransit();
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

                %F(k+1) -= diag(branchPerBusOfGenPTDF)*DeltaPC(k-delayCurt), i.e matrix Mc in the paper
                rowRange = 1:obj.numberOfBranches;
                obj.operatorControlCurtailment(rowRange, :) = - obj.branchPerBusOfGenPTDF;

                % PC(k+1) += DeltaPC(k-delayCurt)
                firstRow = obj.numberOfBranches + 1;
                rowRange = firstRow : firstRow+obj.numberOfGen-1;
                obj.operatorControlCurtailment(rowRange, :) = eye(obj.numberOfGen);

                % PG(k+1) -= DeltaPC(k-delayCurt)
                firstRow = obj.numberOfBranches + obj.numberOfGen + 2*obj.numberOfBatt + 1;
                obj.operatorControlCurtailment( firstRow:end, :) = - eye(obj.numberOfGen);
            end

            function setOperatorControlBattery(obj)
                numberOfRows = obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorControlBattery = zeros(numberOfRows, obj.numberOfBatt);

                % F(k+1) += diag(branchPerBusOfBattPTDF)*DeltaPb(k-delayBatt), i.e. matrix Mb in the paper
                rowRange = 1:obj.numberOfBranches;
                obj.operatorControlBattery(rowRange, :) = obj.branchPerBusOfBattPTDF;
                
                % PB(k+1) += DeltaPB(k-delayBatt)
                firstRow = obj.numberOfBranches + obj.numberOfGen + 1;
                rowRange = firstRow : firstRow + obj.numberOfBatt - 1;
                obj.operatorControlBattery(rowRange, :) = eye(obj.numberOfBatt);
                
                % EB(k+1) -= T*diag(cb)*DeltaPB(k-delayBatt), i.e. matrix -Ab in the paper
                firstRow = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt + 1;
                rowRange = firstRow : firstRow + obj.numberOfBatt - 1;
                obj.operatorControlBattery(rowRange, :) = - obj.timestep * xdiag(obj.batteryCoef);
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

        end
end