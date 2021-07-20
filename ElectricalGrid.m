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
            
            obj.checkNoBusNorBranchDeleted();

            obj.setMapBus_id_e2i();
            obj.setMapBus_id_i2e();
            
            obj.setMapGenOn_idx_e2i();
            obj.setMapGenOn_idx_i2e();
            
            obj.setMatpowerOption();
            
        end
        
        function [branch_zone_idx, branch_border_idx] = getInnerAndBorderBranchIdx(obj, busId)
            % Given a zone with its buses id, return the branch indices
            % from the matpowercase of: the branches within the zone (both end buses in zone)
            % and the branches at the border of zone ( 1 end bus in the zone), respectively
            
            buses_of_branch = obj.Matpowercase.branch(:,[1 2]);
            % determine what end buses are from the zone or outside, as boolean
            is_fbus_tbus_of_branch_in_zone = ismember(buses_of_branch, busId);
            % sum booleans per branch :fbusIn + tBusIn, i.e. over the columns, to get the number of end buses of the branch within the zone  
            nb_of_buses_of_branch_in_zone = sum(is_fbus_tbus_of_branch_in_zone,2); 
            S = sparse(nb_of_buses_of_branch_in_zone);
            % the branch is within the zone as it is connecting 2 inner buses
            branch_zone_idx = find(S==2); 
            % the branch connects a inner bus with an outer bus
            branch_border_idx = find(S==1);
            
        end
        
        function busBorderId = getBusBorderId(obj, busId, branchBorderIdx)
            % Given a zone based on its buses, the branches at the border of the
            % zone and a basecase,
            % return the column vector of the buses at the border of the zone   

            % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row)
            fromBus = obj.Matpowercase.branch(branchBorderIdx,1);
            toBus = obj.Matpowercase.branch(branchBorderIdx,2);
            
            % look for the end buses of each branch at the border, i.e. not in the zone. As boolean column vectors
            is_fromBus_in_border = ~ismember(fromBus, busId);
            is_toBus_in_border = ~ismember(toBus, busId);
            if any(is_fromBus_in_border + is_toBus_in_border ~= 1)
                % error if a branch does not have exactly 1 end bus inside the zone
                error(['A branch does not have exactly 1 end bus inside the zone.'...
                        newline ' Check input branchBorderIdx is correct, i.e. all branches are at the border of the zone'...
                        ' which should be BranchBorderIdx'])
            end
            % Get the buses id of the end buses at the border
            fromBus_border_id = fromBus(is_fromBus_in_border);
            toBus_border_id = toBus(is_toBus_in_border);
            % the buses at the border are the union set, i.e. no repetition, in sorted order, as a column vector
            busBorderId = union(fromBus_border_id, toBus_border_id, 'rows', 'sorted');
        end
        
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
        
        %TODO see 'getPowerBranchFlow' method, it is the same
        function powerTransit = getPowerTransitBusFrom(obj, branchIdx)
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
        
        
        function boolean = isBusDeleted(obj)
        % check if some buses have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBuses = size(obj.InternalMatpowercase.order.bus.status.off, 1);
            boolean = numberOfDeletedBuses ~= 0;
        end

        function boolean = isBranchDeleted(obj)
        % check if some branches have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBranches = size(obj.InternalMatpowercase.order.branch.status.off,1);
            boolean = numberOfDeletedBranches ~= 0;
        end
        
        function checkNoBusNorBranchDeleted(obj)
            if obj.isBusDeleted() || obj.isBranchDeleted()
                error(['A bus or a branch has been deleted in the internal matpowercase.'...
                    'The code can not handle this case. Take a different matpowercase or modify it'])
            end
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