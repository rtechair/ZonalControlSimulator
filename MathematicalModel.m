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

classdef MathematicalModel < handle
%   To obtain the operators / matrices for the dynamic mathematical model
%   of a zone.
%
%   Beware the arguments of the constructor are internal
%   elements from the internal matpowercase! This is due to makePTDF
%   executes on the internal matpowercase.
%
%  The mathematical model is based on the paper:
% 'Modeling the Partial Renewable Power Curtailment for Transmission Network Management'[1].
%  Beware, x includes the power available PA! It is not displayed as such in the paper.
%   x = [Fij PC PB EB PG PA]
%   The model is described by the equation:
%   x(k+1) = A*x(k) + Bc*DeltaPC(k-delayCurt) + Bb*DeltaPB(k-delayBatt) 
%            + Dg*DeltaPG(k) + Dn*DeltaPT(k) + Da*DeltaPA(k)
% [1] https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v2/document

    properties (SetAccess = protected)
      
      internalMatpowercase  
        
      operatorState                 % A
      operatorControlCurtailment    % Bc
      operatorControlBattery        % Bb
      operatorDisturbancePowerAvailable  % Da
      operatorDisturbancePowerGeneration % Dg
      operatorDisturbancePowerTransit    % Dt
      
      injectionShiftFactor % ISF      
      ISFreduced % currently not working, cf. method 'setISFreduced'

      % Regarding the studied zone 
      internalBusId
      internalBranchIdx
      internalGenIdx
      internalBattIdx
      
      numberOfBuses
      numberOfBranches
      numberOfGen
      numberOfBatt
      
      numberOfStateVariables
      
      battConstPowerReduc % must be a vector of length 'numberOfBatt'
    end
    
    methods 
        
        function obj = MathematicalModel(internalMatpowercase, internalZoneBusId, ...
                internalZoneBranchIdx, internalZoneGenIdx, internalZoneBattIdx, ...
                battConstPowerReduc)
            
            obj.internalMatpowercase = internalMatpowercase;
            obj.internalBusId = internalZoneBusId;
            obj.internalBranchIdx = internalZoneBranchIdx;
            obj.internalGenIdx = internalZoneGenIdx;
            obj.internalBattIdx = internalZoneBattIdx;
            
            obj.battConstPowerReduc = battConstPowerReduc;
            
            obj.setNumberOfElements();
            obj.setInjectionShiftFactor();
            
            obj.setOperatorState();
            obj.setoperatorControlCurtailment();
            obj.setoperatorControlBattery();
            obj.setoperatorDisturbancePowerAvailable();
            obj.setOperatorDisturbancePowerGeneration();
            obj.setOperatorDisturbancePowerTransit();
        end
        
        function setNumberOfElements(obj)
            obj.numberOfBuses = size(obj.internalBusId, 1);
            obj.numberOfBranches = size(obj.internalBranchIdx, 1);
            obj.numberOfGen = size(obj.internalGenIdx, 1);
            obj.numberOfBatt = size(obj.internalBattIdx, 1);
            
            % The state is x = [Fij Pc Pb Eb Pg Pa]', thus
            obj.numberOfStateVariables = ...
                obj.numberOfBranches + 3*obj.numberOfGen + 2*obj.numberOfBatt;
        end
        
        function setInjectionShiftFactor(obj)
            obj.injectionShiftFactor = makePTDF(obj.internalMatpowercase);
        end
        
        function setISFreduced(obj)
            % METHOD NOT WORKING
            bus = obj.internalMatpowercase.bus;
            gen = obj.internalMatpowercase.gen;
            [slack,~,~] = bustypes(bus, gen);
            % Warning, regarding the dimensions of 'slack', if it is a
            % scalar, then it is fine
            
            %{
                Error, makePTDF not working:
                Error using accumarray
                First input SUBS must be a real, full, numeric matrix or a cell vector.
                Error in makePTDF (line 151)
                dP = accumarray([bidx (1:nbi)'], 1, [nb, nbi]);
            %}
            obj.ISFreduced = makePTDF(obj.internalMatpowercase, slack, obj.internalBusId);
            
        end
        
        function setOperatorState(obj)
            %{
            Fij(k+1) += Fij(k)
            Pc(k+1) += Pc(k)
            Pb(k+1) += Pb(k)
            Eb(k+1) += Eb(k)
            Pg(k+1) += Pg(k)
            Pa(k+1) += Pa(k)
            %}
            obj.operatorState = eye(obj.numberOfStateVariables);
            
            % Eb(k+1) -= T*diag(cb)*Pb(k), T = 1 sec
            % if there is no battery, then the following lines won't do anything,
            % because the concerned submatrix will be an empty matrix
            startRow = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt + 1;
            startCol = obj.numberOfBranches + obj.numberOfGen + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            rangeCol = startCol : startCol + obj.numberOfBatt - 1;
            obj.operatorState(rangeRow, rangeCol) = - diag(obj.battConstPowerReduc);
        end
        
        function setoperatorControlCurtailment(obj)
            obj.operatorControlCurtailment = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            
            %F(k+1) -= diag(ISF)*DeltaPC(k-delayCurt)
            busOfGen = obj.internalMatpowercase.gen(obj.internalGenIdx, 1);
            rangeRow = 1:obj.numberOfBranches;
            obj.operatorControlCurtailment(rangeRow, :) = ...
                - obj.injectionShiftFactor(obj.internalBranchIdx, busOfGen);
            
            % PC(k+1) += DeltaPC(k-delayCurt)
            startRow = obj.numberOfBranches + 1;
            rangeRow = startRow : startRow + obj.numberOfGen - 1;
            obj.operatorControlCurtailment(rangeRow, :) = eye(obj.numberOfGen);
            
            % PG(k+1) -= DeltaPC(k-delayCurt)
            startRow = obj.numberOfBranches + obj.numberOfGen + 2*obj.numberOfBatt + 1;
            rangeRow = startRow : startRow + obj.numberOfGen - 1;
            obj.operatorControlCurtailment( rangeRow, :) = - eye(obj.numberOfGen);
        end
        
        function setoperatorControlBattery(obj)
            obj.operatorControlBattery = zeros(obj.numberOfStateVariables, obj.numberOfBatt);
            
            % F(k+1) += diag(ptdf)*DeltaPb(k-delayBatt), i.e. matrix Mb in the paper
            busOfBatt = obj.internalMatpowercase.gen(obj.internalBattIdx, 1);
            rangeRow = 1:obj.numberOfBranches;
            obj.operatorControlBattery(rangeRow, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, busOfBatt);
            
            % PB(k+1) += DeltaPB(k-delayBatt), i.e. identity matrix
            startRow = obj.numberOfBranches + obj.numberOfGen + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            obj.operatorControlBattery(rangeRow, :) = eye(obj.numberOfBatt);
            
            % EB(k+1) -= T*diag(cb)*DeltaPB(k-delayBatt), i.e. matrix -Ab in the paper
            startRow = obj.numberOfBranches + obj.numberOfGen + obj.numberOfBatt + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            obj.operatorControlBattery(rangeRow, :) = - diag(obj.battConstPowerReduc);
        end
        
        function setoperatorDisturbancePowerAvailable(obj)
            obj.operatorDisturbancePowerAvailable = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            startRow = obj.numberOfStateVariables - obj.numberOfGen + 1;
            rangeRow = startRow : obj.numberOfStateVariables;
            obj.operatorDisturbancePowerAvailable(rangeRow, :) = eye(obj.numberOfGen);
        end
        
        function setOperatorDisturbancePowerGeneration(obj)
            obj.operatorDisturbancePowerGeneration = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            start = obj.numberOfStateVariables - 2*obj.numberOfGen + 1;
            rangeRow = start : start + obj.numberOfGen - 1;
            obj.operatorDisturbancePowerGeneration(rangeRow, :) = eye(obj.numberOfGen);
            busOfGen = obj.internalMatpowercase.gen(obj.internalGenIdx, 1);
            obj.operatorDisturbancePowerGeneration(1:obj.numberOfBranches, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, busOfGen);
        end
        
        function setOperatorDisturbancePowerTransit(obj)
            obj.operatorDisturbancePowerTransit = zeros(obj.numberOfStateVariables, obj.numberOfBuses);
            obj.operatorDisturbancePowerTransit(1: obj.numberOfBranches, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, obj.internalBusId);
        end
        
        function saveOperators(obj, filename)
            arguments
                obj
                filename char
            end
            operatorState = obj.operatorState;                                            % A
            operatorControlCurtailment = obj.operatorControlCurtailment;                  % Bc
            operatorControlBattery = obj.operatorControlBattery;                          % Bb
            operatorDisturbancePowerGeneration = obj.operatorDisturbancePowerGeneration;  % Dg
            operatorDisturbancePowerTransit = obj.operatorDisturbancePowerTransit;        % Dt
            operatorDisturbancePowerAvailable = obj.operatorDisturbancePowerAvailable;    % Da
            save(filename,'operatorState', ...                       % A
                          'operatorControlCurtailment', ...          % Bc
                          'operatorControlBattery', ...              % Bb
                          'operatorDisturbancePowerGeneration', ...  % Dg
                          'operatorDisturbancePowerTransit', ...     % Dt
                          'operatorDisturbancePowerAvailable')       % Da
            message = ['The operators of the mathematical model are saved in file: ' filename '.mat'];
            disp(message)
        end
 
    end
end