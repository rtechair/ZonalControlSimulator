classdef Matpowercase < handle
   
    properties
        MpcStruct
    end
    
    methods
        
        function obj = Matpowercase(filenameBasecase)
            obj.MpcStruct = loadcase(filenameBasecase);
        end
        
        function addBus(obj)
            % TODO
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