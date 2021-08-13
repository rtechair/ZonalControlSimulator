classdef DisturbancePowerAvailable < handle
% Wrapper class of a value DISTURBANCE POWER AVAILABLE
% such that the telecommunication, from the time series to the zone
% manipulates an object instead of a matrix
    properties (SetAccess = protected)
        disturbanceValue
    end
    
    methods 
        function obj = DisturbancePowerAvailable(value)
            obj.disturbanceValue = value;
        end
        
        function value = getValue(obj)
            value = obj.disturbanceValue;
        end
    end
    
end