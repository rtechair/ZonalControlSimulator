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
      
      internalMatpowercase  
        
      operatorState             % A
      operatorControlCurt       % Bc
      operatorControlBatt       % Bb
      operatorDisturbAvailable  % Da
      operatorDisturbGeneration % Dg
      operatorDisturbTransit    % Dt
      
      injectionShiftFactor % ISF      
      ISFreduced

      % Regarding the studied zone 
      internalBusId
      internalBranchIdx
      internalGenIdx
      internalBattIdx
      
      numberOfBuses
      numberOfBuses
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
            obj.numberOfBuses = size(obj.internalBusId, 1);
            obj.numberOfBuses = size(obj.internalBranchIdx, 1);
            obj.numberOfGen = size(obj.internalGenIdx, 1);
            obj.numberOfBatt = size(obj.internalBattIdx, 1);
            
            % The state is x = [Fij Pc Pb Eb Pg Pa]', thus
            obj.numberOfStateVariables = ...
                obj.numberOfBuses + 3*obj.numberOfGen + 2*obj.numberOfBatt;
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
            startRow = obj.numberOfBuses + obj.numberOfGen + obj.numberOfBatt + 1;
            startCol = obj.numberOfBuses + obj.numberOfGen + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            rangeCol = startCol : startCol + obj.numberOfBatt - 1;
            obj.operatorState( rangeRow, rangeCol) = - diag(obj.battConstPowerReduc);
        end
        
        function setOperatorControlCurt(obj)
            obj.operatorControlCurt = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            
            %F(k+1) -= diag(ISF)*DeltaPC(k-delayCurt)
            busOfGen = obj.internalMatpowercase.gen(obj.internalGenIdx, 1);
            obj.operatorControlCurt(1:obj.numberOfBuses, :) = ...
                - obj.injectionShiftFactor( obj.internalBranchIdx, busOfGen);
            
            % PC(k+1) += DeltaPC(k-delayCurt)
            startRow = obj.numberOfBuses + 1;
            rangeRow = startRow : startRow + obj.numberOfGen - 1;
            obj.operatorControlCurt( rangeRow, :) = eye(obj.numberOfGen);
            
            % PG(k+1) -= DeltaPC(k-delayCurt)
            startRow = obj.numberOfBuses + obj.numberOfGen + 2*obj.numberOfBatt + 1;
            rangeRow = startRow : startRow + obj.numberOfGen - 1;
            obj.operatorControlCurt( rangeRow, :) = - eye(obj.numberOfGen);
        end
        
        function setOperatorControlBatt(obj)
            obj.operatorControlBatt = zeros(obj.numberOfStateVariables, obj.numberOfBatt);
            
            % F(k+1) += diag(ptdf)*DeltaPb(k-delayBatt), i.e. matrix Mb in the paper
            busOfBatt = obj.internalMatpowercase.gen(obj.internalBattIdx, 1);
            obj.operatorControlBatt(1:obj.numberOfBuses, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, busOfBatt);
            
            % PB(k+1) += DeltaPB(k-delayBatt), i.e. identity matrix
            startRow = obj.numberOfBuses + obj.numberOfGen + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            obj.operatorControlBatt(rangeRow, :) = eye(obj.numberOfBatt);
            
            % EB(k+1) -= T*diag(cb)*DeltaPB(k-delayBatt), i.e. matrix -Ab in the paper
            startRow = obj.numberOfBuses + obj.numberOfGen + obj.numberOfBatt + 1;
            rangeRow = startRow : startRow + obj.numberOfBatt - 1;
            obj.operatorControlBatt( rangeRow, :) = - diag(obj.battConstPowerReduc);
        end
        
        function setOperatorDisturbAvailable(obj)
            obj.operatorDisturbAvailable = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            startRow = obj.numberOfStateVariables - obj.numberOfGen + 1;
            rangeRow = startRow : obj.numberOfStateVariables;
            obj.operatorDisturbAvailable(rangeRow, :) = eye(obj.numberOfGen);
        end
        
        function setOperatorDisturbGeneration(obj)
            obj.operatorDisturbGeneration = zeros(obj.numberOfStateVariables, obj.numberOfGen);
            start = obj.numberOfStateVariables - 2*obj.numberOfGen + 1;
            rangeRow = start : start + obj.numberOfGen - 1;
            obj.operatorDisturbGeneration(rangeRow, :) = eye(obj.numberOfGen);
            busOfGen = obj.internalMatpowercase.gen(obj.internalGenIdx, 1);
            obj.operatorDisturbGeneration(1:obj.numberOfBuses, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, busOfGen);
        end
        
        function setOperatorDisturbTransit(obj)
            obj.operatorDisturbTransit = zeros(obj.numberOfStateVariables, obj.numberOfBuses);
            obj.operatorDisturbTransit(1: obj.numberOfBuses, :) = ...
                obj.injectionShiftFactor(obj.internalBranchIdx, obj.internalBusId);
        end
        
        function saveOperators(obj, filename)
            operatorState = obj.operatorState;                          % A
            operatorControlCurt = obj.operatorControlCurt;              % Bc
            operatorControlBatt = obj.operatorControlBatt;              % Bb
            operatorDisturbAvailable = obj.operatorDisturbAvailable;    % Da
            operatorDisturbGeneration = obj.operatorDisturbGeneration;  % Dg
            operatorDisturbTransit = obj.operatorDisturbGeneration;     % Dt
            save(filename, 'operatorState', ...            % A
                          'operatorControlCurt', ...       % Bc
                          'operatorControlBatt', ...       % Bb
                          'operatorDisturbAvailable', ...  % Da
                          'operatorDisturbGeneration', ... % Dg
                          'operatorDisturbTransit')        % Dt
        end
 
    end
end