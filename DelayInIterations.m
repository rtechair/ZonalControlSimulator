classdef DelayInIterations < handle
   
    properties (SetAccess = immutable)
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
    end
    
end