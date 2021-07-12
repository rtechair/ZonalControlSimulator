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
            % add a generator to the existing Matpowercase at the bottom of the 'gen' field.
            % It is equivalent to Matpower's function 'addgen2mpc', but with default values.
            
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
                Pg_min (1,1) double
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
        
        function addBranch(obj)
            % TODO
        end
        
        function addZoneVG(obj)
            % TODO
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