classdef ElectricalGrid < handle
   
    properties
        Matpowercase
        InternalMatpowercase % used by matpower 'runpf' function
        
        % The internal id of a bus is the external index of this bus.
        MapBus_id_e2i % sparse column vector, convert external bus id -> internal bus id. The internal 
        MapBus_id_i2e % dense column vector, convert internal bus id -> external bus id
        
        MapGenOn_idx_e2i % sparse column vector, converts exterior -> interior online generator or battery index
        MapGenOn_idx_i2e % dense column vector,, converts interior -> exterior online generator or battery index
        
        MatpowerOption % option for matpower 'runpf' function 
        
        ResultPowerFlow
    end
    
    methods
        
        function obj = ElectricalGrid(filenameBasecase)
            
            checkItIsCase6468rte_zoneVGandVTV(filenameBasecase)
            
            obj.Matpowercase = loadcase(filenameBasecase);
            
            obj.InternalMatpowercase = ext2int(obj.Matpowercase);

            obj.setMapBus_id_e2i();
            obj.setMapBus_id_i2e();
            
            obj.setMapGenOn_idx_e2i();
            obj.setMapGenOn_idx_i2e();
            
            obj.setMatpowerOption();
            
        end
        
        function [branchZoneIdx, branchBorderIdx] = getInnerAndBorderBranchIdx(obj, busId)
            % Given a zone with its buses id, return the branch indices
            % from the matpowercase of: the branches within the zone (both end buses in zone)
            % and the branches at the border of zone ( 1 end bus in the zone), respectively
            
            busesOfBranch = obj.Matpowercase.branch(:,[1 2]);
            % determine what end buses are from the zone or outside, as boolean
            areEndBusesOfBranchInZone = ismember(busesOfBranch, busId);
            % sum booleans per branch :fromBus + toBus, i.e. over the columns, to get the number of end buses of the branch within the zone  
            numberOfBusesPerBranchInZone = sum(areEndBusesOfBranchInZone,2); 
            % the branch is within the zone as it is connecting 2 inner buses
            branchZoneIdx = find(numberOfBusesPerBranchInZone == 2); 
            % the branch connects a inner bus with an outer bus
            branchBorderIdx = find(numberOfBusesPerBranchInZone == 1);
        end
        
        function busBorderId = getBusBorderId(obj, busId, branchBorderIdx)
            % Given a zone based on its buses, the branches at the border of the
            % zone and a basecase,
            % return the column vector of the buses at the border of the zone   

            % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row)
            fromBus = obj.Matpowercase.branch(branchBorderIdx,1);
            toBus = obj.Matpowercase.branch(branchBorderIdx,2);
            
            % look for the end buses of each branch at the border, i.e. not in the zone. As boolean column vectors
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
        
        %{
        function [genOnIdx, battOnIdx] = getGenAndBattOnIdx(obj, busId)
            % Given a zone based on its buses id and a basecase, 
            % return the column vectors of the indices, from the basecase, of the generators and
            % batteries online and in the zone
            
            
            % 1st condition: gen and batt are in the zone, i.e. in one of the zone's buses
            busOfGen = obj.Matpowercase.gen(:,1);
            isBusInZone = ismember(busOfGen, busId);
            
            % 2nd condition: gen and batt are online
            isGenAndBattOn = obj.Matpowercase.gen(:,8) > 0;
            
            intersection = isBusInZone .* isGenAndBattOn;
            genAndBattOnInZone = find(intersection);
            
            % separate gen and batt,a battery is a generator with possible negative injection
            Pg_min = obj.Matpowercase.gen(:,10);
            battOnIdx = find(intersection .* Pg_min < 0);
            genOnIdx = setdiff(genAndBattOnInZone, battOnIdx);  
        end
        %}
        
        function genOnIdx = getGenOnIdx(obj, busId)
            % Given a zone based on its buses id, return the
            % indices of the generators ON from the basecase  
            % 3 conditions:
            % It is a generator
            % It is ON
            % bus of gen in zone
            minPowerGeneration = obj.Matpowercase.gen(:,10);
            isItAGen = minPowerGeneration >= 0;
            isItOn = obj.Matpowercase.gen(:,8) > 0;
            
            busesOfAllGen = obj.Matpowercase.gen(:,1);
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
            minPowerGeneration = obj.Matpowercase.gen(:,10);
            isItAGen = minPowerGeneration >= 0;
            isItOff = obj.Matpowercase.gen(:,8) <= 0;
            
            busesOfAllGen = obj.Matpowercase.gen(:,1);
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
            
            minPowerGeneration = obj.Matpowercase.gen(:,10);
            % A battery has negative minimum power generation,
            % corresponding to power injected into the battery
            isItABatt = minPowerGeneration < 0;
            isItOn = obj.Matpowercase.gen(:,8) > 0;
            
            busesOfAllGen = obj.Matpowercase.gen(:,1);
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
            
            minPowerGeneration = obj.Matpowercase.gen(:,10);
            % A battery has negative minimum power generation,
            % corresponding to power injected into the battery
            isItABatt = minPowerGeneration < 0;
            isItOff = obj.Matpowercase.gen(:,8) <= 0;
            
            busesOfAllGen = obj.Matpowercase.gen(:,1);
            isBusOfBattInZone = ismember(busesOfAllGen, busId);
            
            battOffInZone = isItABatt .* isItOff .* isBusOfBattInZone;
            battOffIdx = find(battOffInZone);
        end
              
        
        function branchFlow = getPowerBranchFlow(obj, branchIdx)
            % branchIdx and not internalBranchIdx, due to 
            % 'result' struct is an external matpowercase, not internal
            branchFlow = obj.ResultPowerFlow.branch(branchIdx, 14); 
        end
        
        function runPowerFlow(obj)
            obj.ResultPowerFlow = runpf(obj.InternalMatpowercase, obj.MatpowerOption);
        end
        
        function updateGeneration(obj, externalGenIdx, newGeneration)
            internalGenIdx = obj.MapGenOn_idx_e2i(externalGenIdx);
            obj.InternalMatpowercase.gen(internalGenIdx, 2) = newGeneration;
        end
        
        function updateBattInjection(obj, externalBattIdx, newBattInjection)
           internalBattIdx = obj.MapGenOn_idx_e2i(externalBattIdx);
           obj.InternalMatpowercase.gen(internalBattIdx, 2) = newBattInjection;
        end
        
        function [fromBus, toBus] = getEndBuses(obj, branchIdx)
           fromBus = obj.Matpowercase.branch(branchIdx, 1); 
           toBus = obj.Matpowercase.branch(branchIdx, 2);
        end
        
        function busId = getBuses(obj, genOrBattIdx)
            % unique to remove redundancy as several generators can be on a same bus
            busId = unique(obj.Matpowercase.gen(genOrBattIdx,1));
        end
        
        function maxGen = getMaxPowerGeneration(obj, genIdx)
            maxGen = obj.Matpowercase.gen(genIdx, 9);
        end
        
        function [numberOfBuses, numberOfBranches, ...
                  numberOfGenNotBatt, numberOfBatt] = getMatpowerCaseDimensions(obj)
            numberOfBuses = size(obj.Matpowercase.bus,1);
            numberOfBranches = size(obj.Matpowercase.branch, 1);

            minPowerGeneration = obj.Matpowercase.gen(:,10);
            isGenABatt = minPowerGeneration < 0;
            numberOfBatt = sum(isGenABatt);
            numberOfGenPlusNumberOfBatt = size(obj.Matpowercase.gen,1);
            numberOfGenNotBatt = numberOfGenPlusNumberOfBatt - numberOfBatt;
        end
        
        function sumPowerTransit = getPowerTransit(obj, zoneBuses, branchBorderIdx)
            numberOfBuses = size(zoneBuses, 1);
            sumPowerTransit = zeros(numberOfBuses,1);
            numberOfBranchesAtBorder = size(branchBorderIdx,1);
            for br = 1:numberOfBranchesAtBorder
               branch = branchBorderIdx(br,1);
               fromBus = obj.ResultPowerFlow.branch(branch,1);
               isFromBusInsideZone = ismember(fromBus, zoneBuses);
               if isFromBusInsideZone
                  powerTransiting = obj.getPowerTransitBusFrom(branch);
                  busIdx = find(fromBus == zoneBuses);
                  % PT += powerInjection
                  sumPowerTransit(busIdx) = sumPowerTransit(busIdx) + powerTransiting;
               else
                   powerTransiting = obj.getPowerTransitBusTo(branch);
                   toBus = obj.ResultPowerFlow.branch(branch, 2);
                   busIdx = find(toBus == zoneBuses);
                   % PT += powerInjection
                   sumPowerTransit(busIdx) = sumPowerTransit(busIdx) + powerTransiting;
               end
            end
        end
        
        function powerTransit = getPowerTransitBusFrom(obj, branchIdx)
            % it is the same as 'getPowerBranchFlow' method, simply a
            % change of name to be more understandable
            powerTransit = obj.ResultPowerFlow.branch(branchIdx, 14);
        end
        
        function powerTransit = getPowerTransitBusTo(obj, branchIdx)
            powerTransit = obj.ResultPowerFlow.branch(branchIdx, 16);
        end

    end
    
    methods (Access = protected)
        
        function setMatpowerOption(obj)
            % mpoption is a configuration for Matpower's 'runpf' function
            
            obj.MatpowerOption = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
            'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
            'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
        end    
        
        function setMapBus_id_e2i(obj)
            obj.MapBus_id_e2i = obj.InternalMatpowercase.order.bus.e2i;
        end
        
        function setMapBus_id_i2e(obj)
            obj.MapBus_id_i2e = obj.InternalMatpowercase.order.bus.i2e;
        end
        
        function setMapGenOn_idx_e2i(obj)
            genOn_idx_ext = obj.InternalMatpowercase.order.gen.status.on;
            numberOfGenOn = size(genOn_idx_ext,1);
            columnOfOnes = ones(numberOfGenOn,1);
            obj.MapGenOn_idx_e2i = sparse(genOn_idx_ext, columnOfOnes, 1:numberOfGenOn);
        end
        
        function setMapGenOn_idx_i2e(obj)
            obj.MapGenOn_idx_i2e = obj.InternalMatpowercase.order.gen.status.on;
        end
  
    end
end

function checkItIsCase6468rte_zoneVGandVTV(filenameBasecase)
            if ~strcmp(filenameBasecase, 'case6468rte_zoneVGandVTV')
                error('filenameBasecase is not case6468rte_zoneVGandVTV, abort execution')
            end
        end