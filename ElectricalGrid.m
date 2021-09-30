classdef ElectricalGrid < handle
% Encapsulate both external and internal matpowercases. See 'BasecaseOverview' first. The external matpowercase is called simply 'matpowercase'
% The internal matpowercase is the external matpowercase but with:
%   - generators off removed
%   - isolated islands removed
%   - bus id modified such that the order of bus id is strictly increasing and consecutive.
% Matpower's function 'runpf' operates on the internal matpowercase but returns an updated external matpowercase.
% As a consequence it is important to have mappings to know where each information is from the external to the internal matpowercase, or vice-versa.
    properties (SetAccess = protected)
        matpowercase
        internalMatpowercase % used by matpower 'runpf' function
        
        % The internal id of a bus is the external index of this bus.
        mapBus_id_e2i % sparse column vector, convert external bus id -> internal bus id
        mapBus_id_i2e % dense column vector, convert internal bus id -> external bus id
        
        mapGenOn_idx_e2i % sparse column vector, converts exterior -> interior online generator or battery index
        mapGenOn_idx_i2e % dense column vector,, converts interior -> exterior online generator or battery index
        
        matpowerOption % option for matpower 'runpf' function 
        
        resultPowerFlow
    end
    
    methods
        
        function obj = ElectricalGrid(basecaseFilename)
            obj.matpowercase = loadcase(basecaseFilename);
            
            obj.internalMatpowercase = ext2int(obj.matpowercase);

            obj.setMapBus_id_e2i();
            obj.setMapBus_id_i2e();
            
            obj.setMapGenOn_idx_e2i();
            obj.setMapGenOn_idx_i2e();
            
            obj.setMatpowerOption();
        end
        
        %% GETTER
        function struct = getMatpowercase(obj)
            struct = obj.matpowercase;
        end
        
        function struct = getInternalMatpowercase(obj)
            struct = obj.internalMatpowercase;
        end
        
        function value = getMapBus_id_e2i(obj)
            value = obj.mapBus_id_e2i;
        end
        
        function value = getMapGenOn_idx_e2i(obj)
            value = obj.mapGenOn_idx_e2i;
        end
        
        %% OTHER
        function [branchZoneIdx, branchBorderIdx] = getInnerAndBorderBranchIdx(obj, busId)
            % Given a zone with its buses id, return the branch indices
            % from the matpowercase of: the branches within the zone (both end buses in zone)
            % and the branches at the border of zone ( 1 end bus in the zone), respectively
            
            busesOfBranch = obj.matpowercase.branch(:,[1 2]);
            areEndBusesOfBranchInZone = ismember(busesOfBranch, busId);
            
            % sum booleans per branch :fromBus + toBus, i.e. over the columns, to get the number of end buses of the branch within the zone  
            numberOfBusesPerBranchInZone = sum(areEndBusesOfBranchInZone,2);
            
            branchZoneIdx = find(numberOfBusesPerBranchInZone == 2); 
            branchBorderIdx = find(numberOfBusesPerBranchInZone == 1);
        end
        
        function busBorderId = getBusBorderId(obj, busId, branchBorderIdx)
            % Given a zone based on its buses, the branches at the border of the
            % zone and a basecase,
            % return the column vector of the buses at the border of the zone   

            % a branch has a 'from' bus and 'to' bus
            fromBus = obj.matpowercase.branch(branchBorderIdx,1);
            toBus = obj.matpowercase.branch(branchBorderIdx,2);
            
            isfromBusInBorder = ~ismember(fromBus, busId);
            istoBusInBorder = ~ismember(toBus, busId);
            
            if any(isfromBusInBorder + istoBusInBorder ~= 1)
                % error if a branch does not have exactly 1 end bus inside the zone
                error(['A branch does not have exactly 1 end bus inside the zone.'...
                        newline ' Check input branchBorderIdx is correct, i.e. all branches are at the border of the zone'...
                        ' which should be BranchBorderIdx'])
            end
            
            % Get the buses id of the end buses at the border
            fromBusBorderId = fromBus(isfromBusInBorder);
            toBusBorderId = toBus(istoBusInBorder);
            
            % the buses at the border are the union set, i.e. no repetition, in sorted order, as a column vector
            busBorderId = union(fromBusBorderId, toBusBorderId, 'rows', 'sorted');
        end
        
        function genOnIdx = getGenOnIdx(obj, busId)
            % Given a zone based on its buses id, return the
            % indices of the generators ON from the basecase  
            % 3 conditions:
            % It is a generator
            % It is ON
            % bus of gen in zone
            
            minPowerGeneration = obj.matpowercase.gen(:,10);
            isItAGen = minPowerGeneration >= 0;
            isItOn = obj.matpowercase.gen(:,8) > 0;
            
            busesOfAllGen = obj.matpowercase.gen(:,1);
            isBusOfGenInZone = ismember(busesOfAllGen, busId);
            
            genOnInZone = isItAGen .* isItOn .* isBusOfGenInZone;
            genOnIdx = find(genOnInZone);
        end
        
        function genOffIdx = getGenOffIdx(obj, busId)
            % Given a zone based on its buses id, return the
            % indices of the generators OFF from the basecase  
            % 3 conditions:
            % It is a generator
            % It is OFF
            % bus of gen in zone
            
            minPowerGeneration = obj.matpowercase.gen(:,10);
            isItAGen = minPowerGeneration >= 0;
            isItOff = obj.matpowercase.gen(:,8) <= 0;

            busesOfAllGen = obj.matpowercase.gen(:,1);
            isBusOfGenInZone = ismember(busesOfAllGen, busId);
            
            genOffInZone = isItAGen .* isItOff .* isBusOfGenInZone;
            genOffIdx = find(genOffInZone);
        end
        
        function battOnIdx = getBattOnIdx(obj, busId)
            % Given a zone based on its buses id, return the
            % indices of the batteries ON from the basecase            
            % 3 conditions:
            % It is a battery
            % It is ON
            % bus of batt in zone
            
            minPowerGeneration = obj.matpowercase.gen(:,10);
            % A battery has negative minimum power generation,
            % corresponding to power injected into the battery
            isItABatt = minPowerGeneration < 0;
            isItOn = obj.matpowercase.gen(:,8) > 0;
            
            busesOfAllGen = obj.matpowercase.gen(:,1);
            isBusOfBattInZone = ismember(busesOfAllGen, busId);
            
            battOnInZone = isItABatt .* isItOn .* isBusOfBattInZone;
            battOnIdx = find(battOnInZone);
        end
        
        function battOffIdx = getBattOffIdx(obj, busId)
            % Given a zone based on its buses id, return the
            % indices of the batteries OFF from the basecase            
            % 3 conditions:
            % It is a battery
            % It is OFF
            % bus of batt in zone
            
            minPowerGeneration = obj.matpowercase.gen(:,10);
            % A battery has negative minimum power generation,
            % corresponding to power injected into the battery
            isItABatt = minPowerGeneration < 0;
            isItOff = obj.matpowercase.gen(:,8) <= 0;
            
            busesOfAllGen = obj.matpowercase.gen(:,1);
            isBusOfBattInZone = ismember(busesOfAllGen, busId);
            
            battOffInZone = isItABatt .* isItOff .* isBusOfBattInZone;
            battOffIdx = find(battOffInZone);
        end
              
        
        function branchFlow = getPowerFlow(obj, branchIdx)
            % branchIdx and not internalBranchIdx, due to 
            % 'result' struct is an external matpowercase, not internal
            branchFlow = obj.resultPowerFlow.branch(branchIdx, 14); 
        end
        
        function runPowerFlow(obj)
            obj.resultPowerFlow = runpf(obj.internalMatpowercase, obj.matpowerOption);
        end
        
        function updateGeneration(obj, externalGenIdx, newGeneration)
            internalGenIdx = obj.mapGenOn_idx_e2i(externalGenIdx);
            obj.internalMatpowercase.gen(internalGenIdx, 2) = newGeneration;
        end
        
        function updateBattInjection(obj, externalBattIdx, newBattInjection)
           internalBattIdx = obj.mapGenOn_idx_e2i(externalBattIdx);
           obj.internalMatpowercase.gen(internalBattIdx, 2) = newBattInjection;
        end
        
        function [fromBus, toBus] = getEndBuses(obj, branchIdx)
           fromBus = obj.matpowercase.branch(branchIdx, 1); 
           toBus = obj.matpowercase.branch(branchIdx, 2);
        end
        
        function busId = getBuses(obj, genOrBattIdx)
            % unique to remove redundancy as several generators can be on a same bus
            busId = unique(obj.matpowercase.gen(genOrBattIdx,1));
        end
        
        function maxGen = getMaxPowerGeneration(obj, genIdx)
            maxGen = obj.matpowercase.gen(genIdx, 9);
        end
        
        function value = getMaxPowerBattery(obj,battIdx)
            % the matpowercase format considers a battery is a generator
            value = obj.getMaxPowerGeneration(battIdx);
        end
        
        function value = getMinPowerBattery(obj, battIdx)
            value = obj.matpowercase.gen(battIdx, 10);
        end
        
        function [numberOfBuses, numberOfBranches, ...
                  numberOfGenNotBatt, numberOfBatt] = getMatpowerCaseDimensions(obj)
            numberOfBuses = size(obj.matpowercase.bus,1);
            numberOfBranches = size(obj.matpowercase.branch, 1);

            minPowerGeneration = obj.matpowercase.gen(:,10);
            isGenABatt = minPowerGeneration < 0;
            numberOfBatt = sum(isGenABatt);
            numberOfGenPlusNumberOfBatt = size(obj.matpowercase.gen,1);
            numberOfGenNotBatt = numberOfGenPlusNumberOfBatt - numberOfBatt;
        end
        
        function sumPowerTransit = getPowerTransit(obj, zoneBuses, branchBorderIdx)
            numberOfBuses = size(zoneBuses, 1);
            sumPowerTransit = zeros(numberOfBuses,1);
            numberOfBranchesAtBorder = size(branchBorderIdx,1);
            for br = 1:numberOfBranchesAtBorder
               branch = branchBorderIdx(br,1);
               fromBus = obj.resultPowerFlow.branch(branch,1);
               isFromBusInsideZone = ismember(fromBus, zoneBuses);
               if isFromBusInsideZone
                  powerTransiting = obj.getPowerTransitBusFrom(branch);
                  busIdx = find(fromBus == zoneBuses);
                  % PT += powerInjection
                  sumPowerTransit(busIdx) = sumPowerTransit(busIdx) + powerTransiting;
               else
                   powerTransiting = obj.getPowerTransitBusTo(branch);
                   toBus = obj.resultPowerFlow.branch(branch, 2);
                   busIdx = find(toBus == zoneBuses);
                   % PT += powerInjection
                   sumPowerTransit(busIdx) = sumPowerTransit(busIdx) + powerTransiting;
               end
            end
        end
        
        function powerTransit = getPowerTransitBusFrom(obj, branchIdx)
            % it is the same as 'getPowerFlow' method, simply a
            % change of name to be more understandable
            powerTransit = obj.resultPowerFlow.branch(branchIdx, 14);
        end
        
        function powerTransit = getPowerTransitBusTo(obj, branchIdx)
            powerTransit = obj.resultPowerFlow.branch(branchIdx, 16);
        end
        
        function replaceExternalByInternalMatpowercase(obj)
            obj.matpowercase = obj.internalMatpowercase;
        end

    end
    
    methods (Access = protected)
        
        function setMatpowerOption(obj)
            % mpoption is a configuration for Matpower's 'runpf' function
            
            obj.matpowerOption = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
            'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
            'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
        end    
        
        function setMapBus_id_e2i(obj)
            obj.mapBus_id_e2i = obj.internalMatpowercase.order.bus.e2i;
        end
        
        function setMapBus_id_i2e(obj)
            obj.mapBus_id_i2e = obj.internalMatpowercase.order.bus.i2e;
        end
        
        function setMapGenOn_idx_e2i(obj)
            genOn_idx_ext = obj.internalMatpowercase.order.gen.status.on;
            numberOfGenOn = size(genOn_idx_ext,1);
            columnOfOnes = ones(numberOfGenOn,1);
            obj.mapGenOn_idx_e2i = sparse(genOn_idx_ext, columnOfOnes, 1:numberOfGenOn);
        end
        
        function setMapGenOn_idx_i2e(obj)
            obj.mapGenOn_idx_i2e = obj.internalMatpowercase.order.gen.status.on;
        end
  
    end
end