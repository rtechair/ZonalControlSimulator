classdef MathematicalModel < handle
%   To obtain the operators / matrices for the dynamic mathematical model
%   of a zone.
%   Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k+tau)+Dd(k)
%   x = [Fij Pc Pb Eb Pg Pa]     uc = DeltaPc      ub =DeltaPb     
%   w = DeltaPg      h = DeltaPT
%   The model is described by the equation:
%   x(k+1) = A*x(k) + Bc*DeltaPC(k-delayCurt) + Bb*DeltaPB(k-delayBatt) 
%            + Dg*DeltaPG(k) + Dn*DeltaPT(k) + Da*DeltaPA(k)

    properties (SetAccess = protected)
      
      InternalMatpowercase  
        
      OperatorState             % A
      OperatorControlCurt       % Bc
      OperatorControlBatt       % Bb
      OperatorDisturbAvailable  % Da
      OperatorDisturbGeneration % Dg
      OperatorDisturbTransit    % Dt
      
      InjectionShiftFactor % ISF      
      ISFreduced

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
            
            obj.setNumberOfElements;
            obj.setInjectionShiftFactor;
            
            obj.setOperatorState;
            obj.setOperatorControlCurt;
            obj.setOperatorControlBatt;
            obj.setOperatorDisturbAvailable;
            obj.setOperatorDisturbGeneration;
            obj.setOperatorDisturbTransit;            
        end
        
        function setNumberOfElements(obj)
            obj.NumberOfBuses = size(obj.InternalBusId, 1);
            obj.NumberOfBranches = size(obj.InternalBranchIdx, 1);
            obj.NumberOfGen = size(obj.InternalGenIdx, 1);
            obj.NumberOfBatt = size(obj.InternalBattIdx, 1);
            
            % The state is x = [Fij Pc Pb Eb Pg Pa]', thus
            obj.NumberOfStateVariables = ...
                obj.NumberOfBranches + 3*obj.NumberOfGen + 2*obj.NumberOfBatt;
        end
        
        function setInjectionShiftFactor(obj)
            obj.InjectionShiftFactor = makePTDF(obj.InternalMatpowercase);
        end
        
        function setISFreduced(obj)
            % METHOD NOT WORKING
            bus = obj.InternalMatpowercase.bus;
            gen = obj.InternalMatpowercase.gen;
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
            obj.ISFreduced = makePTDF(obj.InternalMatpowercase, slack, obj.InternalBusId);
            
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
        
        function setOperatorControlCurt(obj)
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
        
        function setOperatorControlBatt(obj)
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
        
        function setOperatorDisturbAvailable(obj)
            obj.OperatorDisturbAvailable = zeros(obj.NumberOfStateVariables, obj.NumberOfGen);
            startRow = obj.NumberOfStateVariables - obj.NumberOfGen + 1;
            rangeRow = startRow : obj.NumberOfStateVariables;
            obj.OperatorDisturbAvailable(rangeRow, :) = eye(obj.NumberOfGen);
        end
        
        function setOperatorDisturbGeneration(obj)
            obj.OperatorDisturbGeneration = zeros(obj.NumberOfStateVariables, obj.NumberOfGen);
            start = obj.NumberOfStateVariables - 2*obj.NumberOfGen + 1;
            rangeRow = start : start + obj.NumberOfGen - 1;
            obj.OperatorDisturbGeneration(rangeRow, :) = eye(obj.NumberOfGen);
            busOfGen = obj.InternalMatpowercase.gen(obj.InternalGenIdx, 1);
            obj.OperatorDisturbGeneration(1:obj.NumberOfBranches, :) = ...
                obj.InjectionShiftFactor(obj.InternalBranchIdx, busOfGen);
        end
        
        function setOperatorDisturbTransit(obj)
            obj.OperatorDisturbTransit = zeros(obj.NumberOfStateVariables, obj.NumberOfBuses);
            obj.OperatorDisturbTransit(1: obj.NumberOfBranches, :) = ...
                obj.InjectionShiftFactor(obj.InternalBranchIdx, obj.InternalBusId);
        end
        
        function saveOperators(obj, filename)
            operatorState = obj.OperatorState;                          % A
            operatorControlCurt = obj.OperatorControlCurt;              % Bc
            operatorControlBatt = obj.OperatorControlBatt;              % Bb
            operatorDisturbAvailable = obj.OperatorDisturbAvailable;    % Da
            operatorDisturbGeneration = obj.OperatorDisturbGeneration;  % Dg
            operatorDisturbTransit = obj.OperatorDisturbGeneration;     % Dt
            save(filename, 'operatorState', ...            % A
                          'operatorControlCurt', ...       % Bc
                          'operatorControlBatt', ...       % Bb
                          'operatorDisturbAvailable', ...  % Da
                          'operatorDisturbGeneration', ... % Dg
                          'operatorDisturbTransit')        % Dt
        end
 
    end
end