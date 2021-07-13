classdef Basecase < handle
   
    properties
        Matpowercase
    end
    
    methods
        
        function obj = Basecase(filenameBasecase)
            obj.Matpowercase = loadcase(filenameBasecase);
        end
        
        function addBus(obj, id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm)
            % add a bus to the existing Matpowercase at the bottom of the 'bus' field
            %% Input
            % All the needed values describing a branch according to MATPOWER
            % manual, see section Bus Data Format of CASEFORMAT, type "help
            % caseformat", or see arguments block in the source code
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
        
        function addGenerator(obj, bus_id, Pg_max, Pg_min, num, startup, shutdown, c3, c2, c1, c0)
            % add a generator or a battery to the existing Matpowercase at the bottom of the 'gen' field.
            % A battery is a generator with Pg_min < 0
            % The method is equivalent to Matpower's function 'addgen2mpc', but with default values.
            
            % CAUTIOUS! nr = number of rows in mpc.gen. gencost can either have nr rows or
            % 2*nr, see Generator Cost Data Format. This function only treats the case with 'nr' rows
            %% Input
            % All the needed values describing a branch according to MATPOWER manual:
            % or a subset not including the data for gencost
            % see section Generator Data Format and Generator Cost Data of CASEFORMAT, type "help caseformat"
            % or Matpower manual: Table B-2 Generator Data and Table B-4 Generator Cost data.
            arguments
                obj
                bus_id (1,1) double {mustBeInteger, mustBePositive}
                Pg_max (1,1) double {mustBeNonnegative}
                Pg_min (1,1) double = 0
                num (1,1) double = 2
                startup (1,1) double = 0
                shutdown (1,1) double = 0
                c3 (1,1) double = 0
                c2 (1,1) double = 0
                c1 (1,1) double = 0
                c0 (1,1) double = 0
            end
            obj.Matpowercase.gencost(end+1,:) = [num startup shutdown c3 c2 c1 c0];
            obj.Matpowercase.gen(end+1,:) = [bus_id 0 0 300 -300 1.025 100 1 Pg_max Pg_min zeros(1,11)];
        end
        
        function addBattery(obj, bus_id, Pg_max, Pg_min)
            % add a battery to the existing Matpowercase at the bottom of the 'gen' field.
            % A battery is a generator with Pg_min < 0
            obj.addGenerator(bus_id, Pg_max, Pg_min);
        end
        
        function addBranch(obj, busFrom, busTo, r, x, b, rateA, rateB, rateC, ratio, angle,...
                status, angmin, angmax)
            obj.Matpowercase.branch(end+1,:) = [busFrom, busTo,r,x,b,rateA,rateB,rateC,ratio,angle,status,angmin,angmax];
        end
        
        
        function branchIdx = findFirstBranch(obj, busFrom, busTo)
            % find the index of the first branch going from busFrom to
            % busTo, does not find a branch if it is from busTo to busFrom,
            % thus the order of the buses is important
            branches = obj.Matpowercase.branch;
            % Why only the 1st branch connecting the 2 buses:
            % On the branches we had to remove, there was only 1 branch connecting the 2 buses
            isBranchWithCorrectBuses = branches(:,1) == busFrom & branches(:,2) == busTo;
            branchIdx = find(isBranchWithCorrectBuses, 1);
        end
        
        function [busFrom, busTo, r,x, b, rateA, rateB, rateC,ratio,angle,status,angmin,angmax] = ...
                getBranchInfo(obj, branchIdx)
            branchInfo = num2cell(obj.Matpowercase.branch(branchIdx,:));
            [busFrom, busTo, r,x, b, rateA, rateB, rateC,ratio,angle,status,angmin,angmax] = ...
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
            
            minBatteryInjection10000 = - maxBatteryInjection10000;
            obj.addBattery(busVG, maxBatteryInjection10000, minBatteryInjection10000);
            obj.addGenerator(2076, maxGeneration2076);
            obj.addGenerator(2745, maxGeneration2745);
            obj.addGenerator(4720, maxGeneration4720);
            
            busMC = 2745;
            busGR = 2076;
            
            branchIdx = obj.findFirstBranch(busMC, busGR);
            [~, ~, r,x, b, rateA, rateB, rateC,ratio,angle,status,angmin,angmax] = ...
                obj.getBranchInfo(branchIdx);
            
            obj.removeBranch(branchIdx);
            
            obj.addBranch(busMC, busVG, r/2,x/2, b/2, rateA, rateB, rateC,ratio,angle,status,angmin,angmax);
            obj.addBranch(busGR, busVG, r/2,x/2, b/2, rateA, rateB, rateC,ratio,angle,status,angmin,angmax);
        end
        
        function addZoneVTV(obj)
            % TODO
        end
        
        function boolean = isBusDeleted(obj)
            % TODO currently in ElectricalGrid
        end
        
        function boolean = isBranchDeleted(obj)
           % TODO currently in ElectricalGrid 
        end
        
        function checkNoBusNorBranchDeleted(obj)
            % TODO currently in ElectricalGrid 
        end
        
    end
    
end