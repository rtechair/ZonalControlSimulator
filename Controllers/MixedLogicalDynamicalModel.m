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
classdef MixedLogicalDynamicalModel < handle
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

            operatorState % A_nl
            operatorControlCurtailment % Bc_nl
            operatorControlBattery % Bb_nl
            operatorNextPowerGeneration % Bz_nl
            operatorDisturbancePowerAvailable
            operatorDisturbancePowerTransit

            delayCurt
            delayBatt

            operatorStateExtended
            operatorControlExtended
            operatorNextPowerGenerationExtended
            operatorDisturbanceExtended
    end

    methods
        function obj = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep,...
                    delayCurt, delayBatt)
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
                    delayCurt
                    delayBatt
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
                obj.setOperatorNextPowerGeneration();
                obj.setOperatorDisturbancePowerTransit();
                obj.setOperatorDisturbancePowerAvailable();

                obj.delayCurt = delayCurt;
                obj.delayBatt = delayBatt;
                obj.setOperatorStateExtended();
                obj.setOperatorControlExtended();
                obj.setOperatorNextPowerGenerationExtended();
                obj.setOperatorDisturbanceExtended();
        end

        function setOperatorState(obj)
            obj.operatorState = [ eye(obj.numberOfBranches), zeros(obj.numberOfBranches, obj.numberOfGen + 2*obj.numberOfBatt), - obj.branchPerBusOfGenPTDF, zeros(obj.numberOfBranches, obj.numberOfGen);
                zeros(obj.numberOfGen, obj.numberOfBranches), eye(obj.numberOfGen), zeros(obj.numberOfGen, 2*obj.numberOfGen + 2*obj.numberOfBatt);
                zeros(obj.numberOfBatt, obj.numberOfBranches + obj.numberOfGen), eye(obj.numberOfBatt), zeros(obj.numberOfBatt, 2*obj.numberOfGen + obj.numberOfBatt);
                zeros(obj.numberOfBatt, obj.numberOfBranches + obj.numberOfGen), - obj.timestep * diag(obj.batteryCoef), eye(obj.numberOfBatt), zeros(obj.numberOfBatt, 2*obj.numberOfGen);
                zeros(obj.numberOfGen, obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt);
                zeros(obj.numberOfGen, obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt), eye(obj.numberOfGen)
                ];
        end

        function setOperatorControlCurtailment(obj)
            obj.operatorControlCurtailment = [zeros(obj.numberOfBranches, obj.numberOfGen);
                eye(obj.numberOfGen);
                zeros(2*obj.numberOfBatt + 2*obj.numberOfGen, obj.numberOfGen)
                ];
        end

        function setOperatorControlBattery(obj)
            obj.operatorControlBattery = [ obj.branchPerBusOfBattPTDF;
                zeros(obj.numberOfGen, obj.numberOfBatt);
                eye(obj.numberOfBatt);
                - obj.timestep * diag(obj.batteryCoef);
                zeros(2 *obj.numberOfGen, obj.numberOfBatt)
                ];
        end

        function setOperatorNextPowerGeneration(obj)
            % Bz_nl in Hung's code
            obj.operatorNextPowerGeneration = [ obj.branchPerBusOfGenPTDF;
                zeros(obj.numberOfGen + 2*obj.numberOfBatt, obj.numberOfGen);
                eye(obj.numberOfGen);
                zeros(obj.numberOfGen)
                ];
        end
        
        function setOperatorDisturbancePowerTransit(obj)
                numberOfRows = obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt;
                obj.operatorDisturbancePowerTransit = zeros(numberOfRows, obj.numberOfBuses);
                % F(k+1) += ptdf * DeltaPT(k)
                obj.operatorDisturbancePowerTransit(1: obj.numberOfBranches, :) = obj.branchPerBusPTDF;
        end

            function setOperatorDisturbancePowerAvailable(obj)
                obj.operatorDisturbancePowerAvailable = [zeros(obj.numberOfBranches + 2*obj.numberOfGen + 2*obj.numberOfBatt, obj.numberOfGen);
                    eye(obj.numberOfGen)
                    ];
            end

        function setOperatorStateExtended(obj)
            %{
            numberOfRows = obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt;
            obj.operatorStateExtended = [obj.operatorState, obj.operatorControlCurtailment, zeros(numberOfRows, obj.numberOfGen * (obj.delayCurt -1) );
                zeros(obj.numberOfGen * (obj.delayCurt - 1), numberOfRows + obj.numberOfGen), eye(obj.numberOfGen * (obj.delayCurt - 1)), zeros(obj.numberOfGen * (obj.delayCurt - 1), obj.numberOfBatt), zeros(obj.numberOfGen * (obj.delayCurt - 1), obj.numberOfBatt * (obj.numberOfBatt - 1));
                zeros(obj.numberOfGen, numberOfRows + obj.numberOfGen*obj.delayCurt + obj.numberOfBatt*obj.delayBatt);
                zeros(obj.numberOfBatt*(obj.delayBatt - 1), numberOfRows + obj.numberOfGen*obj.delayCurt + obj.numberOfBatt), eye(obj.numberOfBatt*(obj.delayBatt - 1));
                zeros(obj.numberOfBatt, numberOfRows + obj.numberOfGen * obj.delayCurt + obj.numberOfBatt * obj.delayBatt)
            ];
            %}
            A_nl = obj.operatorState;
            Bc_nl  = obj.operatorControlCurtailment;
            Bb_nl = obj.operatorControlBattery;
            n = obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt;
            c = obj.numberOfGen;
            b = obj.numberOfBatt;
            tau_c = obj.delayCurt;
            tau_b = obj.delayBatt;
            
            obj.operatorStateExtended = [   A_nl , Bc_nl           , zeros(n,c*(tau_c-1))  , Bb_nl , zeros(n,b*(tau_b-1));
            zeros(c*(tau_c-1),n+c)  , eye(c*(tau_c-1))      , zeros(c*(tau_c-1),b), zeros(c*(tau_c-1),b*(tau_b-1))
            zeros(c,n+c*tau_c+b*tau_b);
            zeros(b*(tau_b-1),n+c*tau_c+b)                  , eye(b*(tau_b-1));
            zeros(b,n+c*tau_c+b*tau_b)];
        end

        function setOperatorControlExtended(obj)
            n = obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt;
            c = obj.numberOfGen;
            b = obj.numberOfBatt;
            tau_c = obj.delayCurt;
            tau_b = obj.delayBatt;
            obj.operatorControlExtended = [  zeros(n+c*(tau_c-1), c+b);
                eye(c,c), zeros(c,b);
                zeros(b*(tau_b-1), c+b);
                zeros(b,c),eye(b)];
        end

        function setOperatorNextPowerGenerationExtended(obj)
            c = obj.numberOfGen;
            b = obj.numberOfBatt;
            tau_c = obj.delayCurt;
            tau_b = obj.delayBatt;
            obj.operatorNextPowerGenerationExtended = [  obj.operatorNextPowerGeneration ;
                    zeros(c*tau_c+b*tau_b,c)];
        end

        function setOperatorDisturbanceExtended(obj)
            c = obj.numberOfGen;
            b = obj.numberOfBatt;
            tau_c = obj.delayCurt;
            tau_b = obj.delayBatt;
            h = obj.numberOfBuses;
            obj.operatorDisturbanceExtended = [obj.operatorDisturbancePowerAvailable, obj.operatorDisturbancePowerTransit;
                                                                       zeros(b*tau_b+c*tau_c,c+h)];
        end

        %% GETTER
        function A = getOperatorState(obj)
            A = obj.operatorState;
        end

        function Bc = getOperatorControlCurtailment(obj)
            Bc = obj.operatorControlCurtailment;
        end

        function Bb = getOperatorControlBattery(obj)
            Bb = obj.operatorControlBattery;
        end

        function Bz = getOperatorNextPowerGeneration(obj)
            Bz = obj.operatorNextPowerGeneration;
        end

        function Dt = getOperatorDisturbancePowerTransit(obj)
            Dt = obj.operatorDisturbancePowerTransit;
        end

        function Da = getOperatorDisturbancePowerAvailable(obj)
            Da = obj.operatorDisturbancePowerAvailable;
        end

        function matrix = getOperatorStateExtended(obj)
            matrix = obj.operatorStateExtended;
        end
        function matrix = getOperatorControlExtended(obj)
            matrix = obj.operatorControlExtended;
        end
        function matrix = getOperatorNextPowerGenerationExtended(obj)
            matrix = obj.operatorNextPowerGenerationExtended;
        end
        function matrix = getOperatorDisturbanceExtended(obj)
            matrix = obj.operatorDisturbanceExtended;
        end
    end
end