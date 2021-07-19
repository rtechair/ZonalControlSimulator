classdef Basecase < handle
   
    properties
        Matpowercase
    end
    
    methods
        
        function obj = Basecase(filenameBasecase)
            obj.Matpowercase = loadcase(filenameBasecase);
        end
        
        function addBus(obj, id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm)
            % Add a bus to the existing Matpowercase at the bottom of the 'bus' field
            %% Input
            % All the needed values describing a branch according to MATPOWER manual: see Table B-1 Bus Data.
            % Alternatively, see section Bus Data Format of CASEFORMAT, type "help caseformat"
            arguments
                obj
                id (1,1) double {mustBeInteger, mustBePositive}
                type (1,1) double {mustBeMember(type, [1 2 3 4])}
                Pd (1,1) double
                Qd (1,1) double
                Gs (1,1) double
                Bs (1,1) double
                area (1,1) double {mustBeInteger, mustBePositive}
                Vm (1,1) double
                Va (1,1) double
                baseKV (1,1) double {mustBeInteger, mustBePositive}
                zone (1,1) double {mustBeInteger, mustBePositive}
                maxVm (1,1) double {mustBePositive}
                minVm (1,1) double {mustBePositive, mustBeLessThanOrEqual(minVm,maxVm)}
            end
            obj.Matpowercase.bus(end+1, :) = ...
                [id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm];
        end
        
        function addGenerator(obj, busId, maxPowerGeneration, minPowerGeneration, num, startup, shutdown, c3, c2, c1, c0)
            % Add a generator or a battery to the existing Matpowercase at the bottom of the 'gen' field.
            % A battery is a generator with minPowerGeneration < 0
            % The method is equivalent to Matpower's function 'addgen2mpc', but with default values for gencost.
            
            % CAUTIOUS! nr = number of rows in mpc.gen. gencost can either have nr rows or
            % 2*nr, see Generator Cost Data Format. This function only treats the case with 'nr' rows
            %% Input
            % All the needed values describing a generator and a generator cost according to
            % MATPOWER manual: see Table B-2 Generator Data and Table B-4 Generator Cost data.
            % Alternatively, see section Generator Data Format and Generator Cost Data of CASEFORMAT, type "help caseformat"
            % or Matpower manual: 
            arguments
                obj
                busId (1,1) double {mustBeInteger, mustBePositive}
                maxPowerGeneration (1,1) double {mustBeNonnegative}
                minPowerGeneration (1,1) double = 0
                num (1,1) double = 2
                startup (1,1) double = 0
                shutdown (1,1) double = 0
                c3 (1,1) double = 0
                c2 (1,1) double = 0
                c1 (1,1) double = 0
                c0 (1,1) double = 0
            end
            obj.Matpowercase.gencost(end+1,:) = [num startup shutdown c3 c2 c1 c0];
            obj.Matpowercase.gen(end+1,:) = [busId 0 0 300 -300 1.025 100 1 maxPowerGeneration minPowerGeneration zeros(1,11)];
        end
        
        function addBattery(obj, busId, maxPowerGeneration, minPowerGeneration)
            % Add a battery to the existing Matpowercase at the bottom of the 'gen' field.
            % A battery is a generator with minPowerGeneration < 0
            obj.addGenerator(busId, maxPowerGeneration, minPowerGeneration);
        end
        
        function addBranch(obj, busFrom, busTo, r, x, b, rateA, rateB, rateC, ratio, angle,...
                status, angmin, angmax)
            % Add a branch to the existing Matpowercase at the bottom of
            % the 'branch' field.
            %% Input
            % All the values describing a branch according to Matpower
            % manual: see Table B-3 Branch Data.
            % Alternatively, see section Branch Data Format of CASEFORMAT, type "help caseformat"
            obj.Matpowercase.branch(end+1,:) = [busFrom, busTo,r,x,b,rateA,rateB,rateC,ratio,angle,status,angmin,angmax];
        end
        
        
        function branchIdx = findFirstBranch(obj, busFrom, busTo)
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
            % Get the information of the branch, providing its index in the
            % 'branch' field. 
            %% Output
            % All the values describing a branch according to Matpower
            % manual: see Table B-3 Branch Data.
            % Alternatively, see section Branch Data Format of CASEFORMAT, type "help caseformat"           
            branchInfo = num2cell(obj.Matpowercase.branch(branchIdx,:));
            [busFrom, busTo, r,x, b, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle] = ...
                branchInfo{:};
        end
        
        function removeBranch(obj, branchIdx)
            obj.Matpowercase.branch(branchIdx,:) = [];
        end
        
        function save(obj, newFilename)
            savecase(newFilename, obj);
        end
            
        function addZoneVG(obj)
            %%Alessio's comment:
            % In order to make the simulations as simple and portable we will use the following framework: 
            % in Matlab the powerflow function (non-linear) within matpower toolbox.
            % In particular, you need to use in matpower, the case 'case6468rte.m'.
            % The zone to be controlled via MPC is the one including the lines between
            % the following buses:  (the letters are indicative, the numbers are important)
            % GR 2076
            % GY 2135
            % MC 2745
            % TR 4720
            % CR 1445
            % Also, you need to add a bus VG in the middle of the line between MC and GR (by dividing by two the impedances)
            % Add the production groups:
            % 78MW at VG
            % 66MW at GR 2076
            % 54MW at MC 2745
            % 10MW at TR 4720
            % A battery of 30Mwh at VG, with power of 10MW both upward and downward.
            % For now, we do not consider the energy of the battery.
            % You need to downsize homogenously the thermal limits up to the point where the line with the highest charge is at 130%.
            % Use a wind production time-line for each production group in the above list.
            % Consider as control lever the fact that we can decrease the production with levels of 25% for each of the busses.
            % The function runpf of matpower should function for the simulation.
            
            % maximum power output for the production groups and the batteries, in MW
            maxGeneration10000 = 78;
            maxGeneration2076 = 66;
            maxGeneration2745 = 54;
            maxGeneration4720 = 10;
            maxBatteryInjection10000 = 10; 
            
            busVG = 10000;
            obj.addBus(busVG, 2, 0, 0, 0, 0, 1, 1.03864259, -11.9454015, 63, 1, 1.07937, 0.952381);
            obj.addGenerator(busVG, maxGeneration10000);
            obj.addGenerator(2076, maxGeneration2076);
            obj.addGenerator(2745, maxGeneration2745);
            obj.addGenerator(4720, maxGeneration4720);
            
            minBatteryInjection10000 = - maxBatteryInjection10000;
            obj.addBattery(busVG, maxBatteryInjection10000, minBatteryInjection10000);
            
            busMC = 2745;
            busGR = 2076;
            
            branchIdx = obj.findFirstBranch(busMC, busGR);
            [~, ~, r,x, b, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle] = ...
                obj.getBranchInfo(branchIdx);
            
            obj.removeBranch(branchIdx);
            
            obj.addBranch(busMC, busVG, r/2,x/2, b/2, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle);
            obj.addBranch(busGR, busVG, r/2,x/2, b/2, rateA, rateB, rateC,ratio,angle,status,minAngle,maxAngle);
        end
        
        function addZoneVTV(obj)
            % nothing is modified on the 3 following buses of the zone with
            % regards to the original basecase 'case6468_rte'
            busLAZ = 2506;
            busSIS = 4169;
            busSPC = 4546;
            
            % There are changes in the following buses:
            busTRE = 4710;
            busVTV = 4875;
            busVEY = 4915;
            
            maxGeneration4710 = 64.7;
            maxGeneration4875 = 53.07;
            maxBatteryInjection4875 = 10;
            minBatteryInjection4875 = - maxBatteryInjection4875;
            maxGeneration4915 = 35.5;
            % max generation of other generators are unchanged compared to
            % the basecase
            
            obj.addGenerator(busTRE, maxGeneration4710);
            obj.addGenerator(busVTV, maxGeneration4875);
            obj.addGenerator(busVEY, maxGeneration4915);
            
            obj.addBattery(busVTV, maxBatteryInjection4875, minBatteryInjection4875);
        end
        
        function boolean = isABusDeleted(obj)
            % TODO currently in ElectricalGrid
        end
        
        function boolean = isABranchDeleted(obj)
           % TODO currently in ElectricalGrid 
        end
        
        function checkNoBusNorBranchDeleted(obj)
            % TODO currently in ElectricalGrid 
        end
        
        function handleBasecase(obj)
            % TODO
           % the considered situation integrates zone VG and zone VTV, thus 
           % they both should be included in the studied basecase
           % If not, then the basecase should integrate it
        end
        
        
        function checkPresenceZoneVG(obj)
           txtBus10000 = obj.isBusAbsentCharArray(10000); 
           txtGenAt10000 = obj.isGenAtBusAbsentCharArray(10000);
           txtGenAt2076 = obj.isGenAtBusAbsentCharArray(2076);
           txtGenAt2745 = obj.isGenAtBusAbsentCharArray(2745);
           txtGenAt4720 = obj.isGenAtBusAbsentCharArray(4720);
           txtBattAt10000 = obj.isBattAtBusPresentCharArray(10000);
           % branch from 2745 to 2076 should be remove, thus should not exist!
           txtBranch2745To2076Absent = obj.isBranchPresentCharArray(2745, 2076);
           txtBranch2745To10000Present = obj.isBranchAbsentCharArray(2745, 10000);
           txtBranch2076To10000Present = obj.isBranchAbsentCharArray(2076, 10000);
           
           txtTotal = [txtBus10000 txtGenAt10000 txtGenAt2076 txtGenAt2745 txtGenAt4720 ...
                        txtBattAt10000 txtBranch2745To2076Absent ...
                        txtBranch2745To10000Present txtBranch2076To10000Present];
           if isempty(txtTotal)
               txtTotal = 'All elements of Zone VG are present in the basecase';
           end
           disp(txtTotal)
        end
        
        
        function boolean = isBusPresent(obj, busId)
            busIdx = find(obj.Matpowercase.bus(:,1) == busId, 1);
            boolean = ~isempty(busIdx);
        end
        
        function char = isBusAbsentCharArray(obj, busId)
            char = '';
            if ~obj.isBusPresent(busId)
                char = ['Bus ' num2str(busId) ' absent' newline];
            end   
        end
        
        function boolean = isBranchPresent(obj, busFrom, busTo)
            branchIdx = obj.findFirstBranch(busFrom, busTo);
            boolean = ~isempty(branchIdx);
        end
        
        function char = isBranchPresentCharArray(obj, busFrom, busTo)
            char = '';
            if obj.isBranchPresent(busFrom, busTo)
                char = ['Branch from ' num2str(busFrom) ' to ' num2str(busTo) ' present' newline];
            end
        end
        
        function char = isBranchAbsentCharArray(obj, busFrom, busTo)
           char = '';
           if ~obj.isBranchPresent(busFrom, busTo)
              char = ['Branch from ' num2str(busFrom) ' to ' num2str(busTo) ' absent' newline];
           end
        end
        
        function boolean = isGenAtBusPresent(obj, busId)
           busesOfGenAndBatt =  obj.Matpowercase.gen(:,1);
           minRealPowerOutput = obj.Matpowercase.gen(:,10);
           isItAGen = minRealPowerOutput >= 0;
           genIdx = find(busesOfGenAndBatt == busId & isItAGen, 1);
           boolean = ~isempty(genIdx);
        end
        
        function char = isGenAtBusAbsentCharArray(obj, busId)
            char = '';
            if ~obj.isGenAtBusPresent(busId)
                char = ['Gen at bus ' num2str(busId) ' absent' newline];
            end
        end
        
        function boolean = isBattAtBusPresent(obj, busId)
            busesOfGenAndBatt =  obj.Matpowercase.gen(:,1);
           minRealPowerOutput = obj.Matpowercase.gen(:,10);
           % a battery has a negative min power output, as opposed to a generator
           isItABatt = minRealPowerOutput < 0;
           battIdx = find(busesOfGenAndBatt == busId & isItABatt, 1);
           boolean = ~isempty(battIdx);
        end
        
         function char = isBattAtBusPresentCharArray(obj, busId)
            char = '';
            if ~obj.isBattAtBusPresent(busId)
                char = ['Batt at bus ' num2str(busId) ' absent' newline];
            end
        end
        
        
        
    end
    
end