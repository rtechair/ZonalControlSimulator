classdef simulationEvolution < handle
    
    properties (SetAccess = protected)
        powerAvailable
        powerGeneration
        powerCurtailment
        powerFlow
        
        step
    end
    
    properties (SetAccess = immutable)
        maxPowerGeneration
    end
    
    methods
            
        function obj = simulationEvolution(maxPowerGeneration)
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.step = 1;
        end
        
        function value = getPowerGeneration(obj)
            value = obj.powerGeneration;
        end
        
        function setPowerCurtailment(obj, value)
            obj.powerCurtailment = value;
        end
        
        function receivePowerAvailable(obj, timeSeries)
            obj.powerAvailable = timeSeries.getPowerAvailable();
        end
        
        function updatePowerGeneration(obj)
            obj.powerGeneration = min(obj.powerAvailable, ...
                obj.maxPowerGeneration - obj.powerCurtailment);
        end
        
        function setPowerFlow(obj, value)
            obj.powerFlow = value;
        end
        
    end
end