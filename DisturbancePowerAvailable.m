classdef DisturbancePowerAvailable < handle
   
    properties (SetAccess = protected)
        NumberOfGen
        DisturbanceValue
    end
    
    methods 
        
        function obj = DisturbancePowerAvailable(numberOfGen)
            obj.NumberOfGen = numberOfGen;
            obj.DisturbanceValue = zeros(numberOfGen,1);
        end
        
        function setDisturbancePowerAvailable(obj, newDisturbance)
            obj.DisturbanceValue = newDisturbance;
        end
        
        function disturbance = getValue(obj)
            disturbance = obj.DisturbanceValue;
        end
        
    end
    
end