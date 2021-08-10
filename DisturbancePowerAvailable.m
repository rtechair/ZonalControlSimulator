classdef DisturbancePowerAvailable < handle
   
    properties (SetAccess = protected)
        numberOfGen
        disturbanceValue
    end
    
    methods 
        
        function obj = DisturbancePowerAvailable(numberOfGen)
            obj.numberOfGen = numberOfGen;
            obj.disturbanceValue = zeros(numberOfGen,1);
        end
        
        function setDisturbancePowerAvailable(obj, newDisturbance)
            obj.disturbanceValue = newDisturbance;
        end
        
        function disturbance = getValue(obj)
            disturbance = obj.disturbanceValue;
        end
        
    end
    
end