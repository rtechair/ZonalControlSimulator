classdef MathematicalModel < handle
    % To obtain the operators / matrices for the dynamic mathematical model
    % of a zone.
    % Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k+tau)+Dd(k)
%     x = [Fij Pc Pb Eb Pg Pa]     uc = DeltaPc      ub =DeltaPb     
%     w = DeltaPg      h = DeltaPT
%     The model is described by the equation:
%     x(k+1) = A*x(k) + Bc*DeltaPC(k-tau_c) + Bb*DeltaPB(k-tau_b) 
%              + Dg*DeltaPG(k) + Dn*DeltaPT(k) + Da*DeltaPA(k)

    properties
      OperatorState             % A
      OperatorControlCurt       % Bc
      OperatorControlBatt       % Bb
      OperatorDisturbAvailable  % Da
      OperatorDisturbGeneration % Dg
      OperatorDisturbTransit    % Dt
      
      InjectionShiftFactor % ISF

      InternalMatpowercase
      
      % Regarding the studied zone 
      InternalBusId
      InternalBranchIdx
      InternalGenIdx
      InternalBattIdx
      
      NumberOfBuses
      NumberOfBranches
      NumberOfGen
      NumberOfBatt
      
      NumberOfStateVariables
      
      BattConstPowerReduc % must be a vector of length 'NumberOfBatt'
    end
    
    methods 
        
        function obj = MathematicalModel(internalMatpowercase, internalZoneBusId, ...
                internalZoneBranchIdx, internalZoneGenIdx, internalZoneBattIdx, ...
                battConstPowerReduc)
            
            obj.InternalMatpowercase = internalMatpowercase;
            obj.InternalBusId = internalZoneBusId;
            obj.InternalBranchIdx = internalZoneBranchIdx;
            obj.InternalGenIdx = internalZoneGenIdx;
            obj.InternalBattIdx = internalZoneBattIdx;
            
            obj.BattConstPowerReduc = battConstPowerReduc;
            
            
        end
        
        function setNumberOfElements(obj)
            obj.NumberOfBuses = size(obj.InternalBusId, 1);
            obj.NumberOfBranches = size(obj.InternalBranchIdx, 1);
            obj.NumberOfGen = size(obj.InternalGenIdx, 1);
            obj.NumberOfBatt = size(obj.InternalBattIdx, 1);
            
            % The state is x = [Fij Pc Pb Eb Pg Pa], thus
            obj.NumberOfStateVariables = ...
                obj.NumberOfBranches + 3*obj.NumberOfGen + 2*obj.NumberOfBatt;
        end
        
        function computeInjectionShiftFactor(obj)
            obj.InjectionShiftFactor = makePTDF(obj.InternalMatpowercase);
        end
        
        function computeOperatorState(obj)
            %{
            Fij(k+1) += Fij(k)
            Pc(k+1) += Pc(k)
            Pb(k+1) += Pb(k)
            Eb(k+1) += Eb(k)
            Pg(k+1) += Pg(k)
            Pa(k+1) += Pa(k)
            %}
            obj.OperatorState = eye(obj.NumberOfStateVariables);
            
            % Eb(k+1) -= T*diag(cb)*Pb(k), T = 1 sec
            % if there is no battery, then the following lines won't do anything,
            % because the concerned submatrix will be an empty matrix
            startRow = obj.NumberOfBranches + obj.NumberOfGen + obj.NumberOfBatt + 1;
            startCol = obj.NumberOfBranches + obj.NumberOfGen + 1;
            rangeRow = startRow : startRow + obj.NumberOfBatt - 1;
            rangeCol = startCol : startCol + obj.NumberOfBatt - 1;
            obj.OperatorState( rangeRow, rangeCol) = - diag(obj.BattConstPowerReduc);
        end
        
        function computeOperatorControlCurt(obj)
            obj.OperatorControlCurt = zeros(obj.NumberOfStateVariables, obj.NumberOfGen);
            
            %F(k+1) -= diag(ISF)*DeltaPC(k-delayCurt)
            busOfGen = obj.InternalMatpowercase.gen(obj.InternalGenIdx, 1);
            obj.OperatorControlCurt(1:obj.NumberOfBranches, :) = ...
                - obj.InjectionShiftFactor( obj.InternalBranchIdx, busOfGen);
            
            % PC(k+1) += DeltaPC(k-delayCurt)
            startRow = obj.NumberOfBranches + 1;
            rangeRow = startRow : startRow + obj.NumberOfGen - 1;
            obj.OperatorControlCurt( rangeRow, :) = eye(obj.NumberOfGen);
            
            % PG(k+1) -= DeltaPC(k-delayCurt)
            startRow = obj.NumberOfBranches + obj.NumberOfGen + 2*obj.NumberOfBatt + 1;
            rangeRow = startRow : startRow + obj.NumberOfGen - 1;
            obj.OperatorControlCurt( rangeRow, :) = - eye(obj.NumberOfGen);
        end
        
        function computeOperatorControlBatt(obj)
            obj.OperatorControlBatt = zeros(obj.NumberOfStateVariables, obj.NumberOfBatt);
            
            % F(k+1) += diag(ptdf)*DeltaPb(k-delayBatt), i.e. matrix Mb in the paper
            busOfBatt = obj.InternalMatpowercase.gen(obj.InternalBattIdx, 1);
            obj.OperatorControlBatt(1:obj.NumberOfBranches, :) = ...
                obj.InjectionShiftFactor(obj.InternalBranchIdx, busOfBatt);
            
            % PB(k+1) += DeltaPB(k-delayBatt), i.e. identity matrix
            startRow = obj.NumberOfBranches + obj.NumberOfGen + 1;
            rangeRow = startRow : startRow + obj.NumberOfBatt - 1;
            obj.OperatorControlBatt(rangeRow, :) = eye(obj.NumberOfBatt);
            
            % EB(k+1) -= T*diag(cb)*DeltaPB(k-delayBatt), i.e. matrix -Ab in the paper
            startRow = obj.NumberOfBranches + obj.NumberOfGen + obj.NumberOfBatt + 1;
            rangeRow = startRow : startRow + obj.NumberOfBatt - 1;
            obj.OperatorControlBatt( rangeRow, :) = - diag(obj.BattConstPowerReduc);
        end
        
        function computeOperatorDisturbAvailable(obj)
            %TODO
        end
        
        function computeOperatorDisturbGeneration(obj)
            %TODO
        end
        
        function computeOperatorDisturbTransit(obj)
            %TODO
        end
   
        
    end
end