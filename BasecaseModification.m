classdef BasecaseModification < BasecaseOverview
   
    methods
       
        function obj = BasecaseModification(filenameBasecase)
           obj@BasecaseOverview(filenameBasecase); 
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
        
        function removeBranch(obj, branchIdx)
            obj.Matpowercase.branch(branchIdx,:) = [];
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
            maxGenerationAt10000 = 78;
            maxGenerationAt2076 = 66;
            maxGenerationAt2745 = 54;
            maxGenerationAt4720 = 10;
            maxBatteryInjectionAt10000 = 10; 
            
            busVG = 10000;
            obj.addBus(busVG, 2, 0, 0, 0, 0, 1, 1.03864259, -11.9454015, 63, 1, 1.07937, 0.952381);
            obj.addGenerator(busVG, maxGenerationAt10000);
            obj.addGenerator(2076, maxGenerationAt2076);
            obj.addGenerator(2745, maxGenerationAt2745);
            obj.addGenerator(4720, maxGenerationAt4720);
            
            minBatteryInjectionAt10000 = - maxBatteryInjectionAt10000;
            obj.addBattery(busVG, maxBatteryInjectionAt10000, minBatteryInjectionAt10000);
            
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
            % TODO: thus, maybe delete them? as they are unused
            busLAZ = 2506;
            busSIS = 4169;
            busSPC = 4546;
            
            % There are changes in the following buses:
            busTRE = 4710;
            busVTV = 4875;
            busVEY = 4915;
            
            maxGenerationAt4710 = 64.7;
            maxGenerationAt4875 = 53.07;
            maxGenerationAt4915 = 35.5;
            
            maxBatteryInjectionAt4875 = 10;
            minBatteryInjectionAt4875 = - maxBatteryInjectionAt4875;
            
            % max generation of other generators are unchanged compared to
            % the basecase
            
            obj.addGenerator(busTRE, maxGenerationAt4710);
            obj.addGenerator(busVTV, maxGenerationAt4875);
            obj.addGenerator(busVEY, maxGenerationAt4915);
            
            obj.addBattery(busVTV, maxBatteryInjectionAt4875, minBatteryInjectionAt4875);
        end
        
        function handleBasecase(obj)
            % TODO
           % the considered situation integrates zone VG and zone VTV, thus 
           % they both should be included in the studied basecase
           % If not, then the basecase should integrate it
        end
        
        function saveMatpowercase(obj, newFilename)
            savecase(newFilename, obj);
        end
        
    end
end