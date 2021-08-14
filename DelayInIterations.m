classdef DelayInIterations < handle
   
    properties (SetAccess = immutable, GetAccess = protected)
        delayCurt
        delayBatt
        delayZone2Controller
        delayController2Zone
        delayTimeSeries2Zone
    end
    
    methods
        function obj = DelayInIterations(controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayZone2ControllerInSeconds, ...
                delayController2ZoneInSeconds, ...
                delayTimeSeries2ZoneInSeconds)
            obj.delayCurt = ceil(delayCurtInSeconds / controlCycle);
            obj.delayBatt = ceil(delayBattInSeconds / controlCycle);
            obj.delayZone2Controller = ceil(delayZone2ControllerInSeconds / controlCycle);
            obj.delayController2Zone = ceil(delayController2ZoneInSeconds / controlCycle);
            obj.delayTimeSeries2Zone = ceil(delayTimeSeries2ZoneInSeconds / controlCycle);
        end
        
        function value = getDelayCurt(obj)
            value = obj.delayCurt;
        end
        
        function value = getDelayBatt(obj)
            value = obj.delayBatt;
        end
        
        function value = getDelayZone2Controller(obj)
            value = obj.delayZone2Controller;
        end
        
        function value = getDelayController2Zone(obj)
            value = obj.delayController2Zone;
        end
        
        function value = getDelayTimeSeries2Zone(obj)
            value = obj.delayTimeSeries2Zone;
        end
    end
    
end