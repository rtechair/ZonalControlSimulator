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

classdef BasecaseOverview < handle
% Allows to get information easily with the dedicated methods regarding the matpowercase
% and its associate internal matpowercase obtained from the Matpower's function 'ext2int'.
%
% A basecase is a representation of an electrical network.
% A matpowercase is a data designed for Matlab/Matpower, representing a basecase,
% with information about: the buses, the branches, the generators and the batteries.
% Batteries in a matpowercase are treated as generators with a negative minimal power load.
%
% Alone, this class is only able to view information.
% It is meant to be combined with its child class 'BaseCaseModifcation' to modify the matpowercase.

    properties
        matpowercase
        internalMatpowercase
        mapBus_id_e2i % sparse column vector, convert external bus id -> internal bus id
    end
    
    methods
        
        function obj = BasecaseOverview(filenameBasecase)
            obj.matpowercase = loadcase(filenameBasecase);
            obj.internalMatpowercase = ext2int(obj.matpowercase);  
            obj.mapBus_id_e2i = obj.internalMatpowercase.order.bus.e2i;
        end
              
        function displayCaseInfo(obj)
            % Use Matpower function 'case_info' to display informations about the basecase 
            case_info(obj.matpowercase)
        end
                
        function busIdx = getBusIdx(obj, busId)
            % the mapping is sparse and returns a sparse matrix, thus make
            % it dense with 'full'
           busIdx = full(obj.mapBus_id_e2i(busId)); 
        end
        
        function branchIdx = getFirstBranchIdx(obj, busFrom, busTo)
            % find the index of the first branch going from busFrom to
            % busTo, does not find a branch if it is from busTo to busFrom,
            % thus the order of the buses is important
            
            % Why only the 1st branch connecting the 2 buses:
            % On the branches we had to remove, there was only 1 branch connecting the 2 buses
            busFromOfBranches = obj.matpowercase.branch(:, 1);
            busToOfBranches = obj.matpowercase.branch(:, 2);
            branchIdx = find(busFromOfBranches == busFrom...
                           & busToOfBranches   == busTo  ,1); 
        end
        
        function genIdx = getGenAtBus(obj, busId)
           allBusesOfGen = obj.matpowercase.gen(:,1);
           genIdx = find(allBusesOfGen == busId);
        end
        
        function genOnIdx = getGenOnAtBus(obj, busId)
           allBusesOfGen = obj.matpowercase.gen(:,1);
           isGenOn = obj.matpowercase.gen(:,8) > 0;
           genOnIdx = find(allBusesOfGen == busId & isGenOn == 1);
        end
        
        function [busFrom,busTo,r,x,b,rateA,rateB,rateC,ratio,angle,status,minAngle,maxAngle] = ...
                getBranchInfo(obj, branchIdx)
            % Get the information of the branch, providing its index in the 'branch' field. 
            %% Output
            % All the values describing a branch according to Matpower manual: see Table B-3 Branch Data.
            % Alternatively, see section Branch Data Format of CASEFORMAT, type "help caseformat"           
            branchInfo = num2cell(obj.matpowercase.branch(branchIdx,:));
            [busFrom, busTo, r,x, b, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle] = ...
                branchInfo{:};
        end
        
        function boolean = isABusDeleted(obj)
            % check if some buses have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBuses = size(obj.internalMatpowercase.order.bus.status.off, 1);
            boolean = numberOfDeletedBuses ~= 0;
        end
        
        function boolean = isABranchDeleted(obj)
            % check if some branches have been deleted during the internal conversion by Matpower function 'ext2int'
            numberOfDeletedBranches = size(obj.internalMatpowercase.order.branch.status.off,1);
            boolean = numberOfDeletedBranches ~= 0;
        end
        
        function boolean = doExternalAndInternalBusOrdersMatch(obj)
            numberOfExtBuses = size(obj.matpowercase.bus,1);
            lastExtBusIdx = obj.matpowercase.bus(numberOfExtBuses,1);
            % e2i is a sparse matrix, thus to obtain a dense 1x1 matrix, 'full' is necessary
            lastIntBusIdx = full(obj.internalMatpowercase.order.bus.e2i(lastExtBusIdx));
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
            busIdx = find(obj.matpowercase.bus(:,1) == busId, 1);
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
           busesOfGenAndBatt =  obj.matpowercase.gen(:,1);
           minRealPowerOutput = obj.matpowercase.gen(:,10);
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
            busesOfGenAndBatt = obj.matpowercase.gen(:,1);
           minRealPowerOutput = obj.matpowercase.gen(:,10);
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