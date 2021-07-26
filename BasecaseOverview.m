classdef BasecaseOverview < handle
   
    properties
        Matpowercase
        InternalMatpowercase
        MapBus_id_e2i % sparse column vector, convert external bus id -> internal bus id
    end
    
    methods
        
        function obj = BasecaseOverview(filenameBasecase)
            obj.Matpowercase = loadcase(filenameBasecase);
            obj.InternalMatpowercase = ext2int(obj.Matpowercase);  
            obj.MapBus_id_e2i = obj.InternalMatpowercase.order.bus.e2i;
        end
              
        function displayCaseInfo(obj)
            % Use Matpower function 'case_info' to display informations about the basecase 
            case_info(obj.Matpowercase)
        end
                
        function busIdx = getBusIdx(obj, busId)
            % the mapping is sparse and returns a sparse matrix, thus make
            % it dense with 'full'
           busIdx = full(obj.MapBus_id_e2i(busId)); 
        end
        
        function branchIdx = getFirstBranchIdx(obj, busFrom, busTo)
            % find the index of the first branch going from busFrom to
            % busTo, does not find a branch if it is from busTo to busFrom,
            % thus the order of the buses is important
            
            % Why only the 1st branch connecting the 2 buses:
            % On the branches we had to remove, there was only 1 branch connecting the 2 buses
            busFromOfBranches = obj.Matpowercase.branch(:, 1);
            busToOfBranches = obj.Matpowercase.branch(:, 2);
            branchIdx = find(busFromOfBranches == busFrom...
                           & busToOfBranches   == busTo  ,1); 
        end
        
        function [busFrom,busTo,r,x,b,rateA,rateB,rateC,ratio,angle,status,minAngle,maxAngle] = ...
                getBranchInfo(obj, branchIdx)
            % Get the information of the branch, providing its index in the 'branch' field. 
            %% Output
            % All the values describing a branch according to Matpower manual: see Table B-3 Branch Data.
            % Alternatively, see section Branch Data Format of CASEFORMAT, type "help caseformat"           
            branchInfo = num2cell(obj.Matpowercase.branch(branchIdx,:));
            [busFrom, busTo, r,x, b, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle] = ...
                branchInfo{:};
        end
        
        function boolean = isABusDeleted(obj)
            % check if some buses have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBuses = size(obj.InternalMatpowercase.order.bus.status.off, 1);
            boolean = numberOfDeletedBuses ~= 0;
        end
        
        function boolean = isABranchDeleted(obj)
            % check if some branches have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBranches = size(obj.InternalMatpowercase.order.branch.status.off,1);
            boolean = numberOfDeletedBranches ~= 0;
        end
        
        function boolean = doExternalAndInternalBusOrdersMatch(obj)
            numberOfExtBuses = size(obj.Matpowercase.bus,1);
            lastExtBusIdx = obj.Matpowercase.bus(numberOfExtBuses,1);
            % e2i is a sparse matrix, thus to obtain a dense 1x1 matrix, 'full' is necessary
            lastIntBusIdx = full(obj.InternalMatpowercase.order.bus.e2i(lastExtBusIdx));
            boolean = lastIntBusIdx == lastExtBusIdx;
        end
        
        function checkNoBusNorBranchDeleted(obj)
            if obj.isABusDeleted() || obj.isABranchDeleted()
                error(['A bus or a branch has been deleted in the internal matpowercase.'...
                    'The code can not handle this case. Take a different matpowercase or modify it'])
            else
                disp('No bus and no branch is deleted during matpower internal conversion. Fine.')
            end
        end
        
        function checkPresenceZoneVG(obj)
            % Check if specific elements of Zone VG are present in the
            % basecase. However, it does not check if all elements of the zone is present,
            % it is assumed 'case6468rte' is the baseline and basic elements of the zone 
            % from the case are already present.
            
           txtBus10000 = obj.isBusAbsentText(10000); 
           txtGenAt10000 = obj.isGenAtBusAbsentText(10000);
           txtGenAt2076 = obj.isGenAtBusAbsentText(2076);
           txtGenAt2745 = obj.isGenAtBusAbsentText(2745);
           txtGenAt4720 = obj.isGenAtBusAbsentText(4720);
           txtBattAt10000 = obj.isBattAtBusAbsentText(10000);
           % branch from 2745 to 2076 should be remove, thus should not exist!
           txtBranch2745To2076Absent = obj.isBranchPresentText(2745, 2076);
           txtBranch2745To10000Present = obj.isBranchAbsentText(2745, 10000);
           txtBranch2076To10000Present = obj.isBranchAbsentText(2076, 10000);
           
           txtTotal = [txtBus10000 txtGenAt10000 txtGenAt2076 txtGenAt2745 txtGenAt4720 ...
                        txtBattAt10000 txtBranch2745To2076Absent ...
                        txtBranch2745To10000Present txtBranch2076To10000Present];
           if isempty(txtTotal)
               txtTotal = 'All elements of Zone VG are present in the basecase';
           end
           disp(txtTotal)
        end
        
        function checkPresenceZoneVTV(obj)
            % Check if specific elements of Zone VTV are present in the
            % basecase. However, it does not check if all elements of the zone is present,
            % it is assumed 'case6468rte' is the baseline and basic elements of the zone 
            % from the case are already present.
            txtGenAt4710 = obj.isGenAtBusAbsentText(4710);
            txtGenAt4875 = obj.isGenAtBusAbsentText(4875);
            txtGenAt4915 = obj.isGenAtBusAbsentText(4915);
            
            txtBattAt4875 = obj.isBattAtBusAbsentText(4875);
            
            txtTotal = [txtGenAt4710 txtGenAt4875 txtGenAt4915 txtBattAt4875];
            if isempty(txtTotal)
                txtTotal = 'All elements of Zone VTV are present in the basecase';
            end
            disp(txtTotal)           
        end
        
        
        function boolean = isBusPresent(obj, busId)
            busIdx = find(obj.Matpowercase.bus(:,1) == busId, 1);
            boolean = ~isempty(busIdx);
        end
        
        function charArray = isBusAbsentText(obj, busId)
            charArray = '';
            if ~obj.isBusPresent(busId)
                charArray = ['Bus ' num2str(busId) ' absent' newline];
            end   
        end
        
        function boolean = isBranchPresent(obj, busFrom, busTo)
            branchIdx = obj.getFirstBranchIdx(busFrom, busTo);
            boolean = ~isempty(branchIdx);
        end
        
        function charArray = isBranchPresentText(obj, busFrom, busTo)
            if obj.isBranchPresent(busFrom, busTo)
                charArray = ['Branch from ' num2str(busFrom) ' to ' num2str(busTo) ' present' newline];
            else
                charArray = '';
            end
        end
        
        function charArray = isBranchAbsentText(obj, busFrom, busTo)
           if ~obj.isBranchPresent(busFrom, busTo)
               charArray = ['Branch from ' num2str(busFrom) ' to ' num2str(busTo) ' absent' newline];
           else
               charArray = '';
           end
        end
        
        function boolean = isGenAtBusPresent(obj, busId)
           busesOfGenAndBatt =  obj.Matpowercase.gen(:,1);
           minRealPowerOutput = obj.Matpowercase.gen(:,10);
           isItAGen = minRealPowerOutput >= 0;
           genIdx = find(busesOfGenAndBatt == busId & isItAGen, 1);
           boolean = ~isempty(genIdx);
        end
        
        function charArray = isGenAtBusAbsentText(obj, busId)
            if ~obj.isGenAtBusPresent(busId)
                charArray = ['Gen at bus ' num2str(busId) ' absent' newline];
            else
                charArray = '';
            end
        end
        
        function boolean = isBattAtBusPresent(obj, busId)
            busesOfGenAndBatt = obj.Matpowercase.gen(:,1);
           minRealPowerOutput = obj.Matpowercase.gen(:,10);
           % a battery has a negative min power output, as opposed to a generator
           isItABatt = minRealPowerOutput < 0;
           battIdx = find(busesOfGenAndBatt == busId & isItABatt, 1);
           boolean = ~isempty(battIdx);
        end
        
         function charArray = isBattAtBusAbsentText(obj, busId)
            if ~obj.isBattAtBusPresent(busId)
                charArray = ['Batt at bus ' num2str(busId) ' absent' newline];
            else
                charArray = '';
            end
        end

    end
    
end