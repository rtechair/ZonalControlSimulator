classdef Basecase < handle
   
    properties
        Matpowercase
    end
    
    methods
        
        function obj = Basecase(filenameBasecase)
            obj.Matpowercase = loadcase(filenameBasecase);
        end
        
        function addBus(obj, id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm)
            % add a bus to the existing Matpowercase at the bottom of the list
            % Input
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
        
        function addGenerator(obj)
            % TODO
        end
        
        
        function addBattery(obj)
            % TODO
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