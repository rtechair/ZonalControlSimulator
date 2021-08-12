classdef DelayInIterations < handle
   
    properties (SetAccess = immutable)
        curt
        batt
        zone2Controller
        controller2Zone
        timeSeries2Zone
    end
    
    methods
        function obj = DelayInIterations(controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayZone2ControllerInSeconds, ...
                delayController2ZoneInSeconds, ...
                delayTimeSeries2ZoneInSeconds)
            obj.curt = ceil(delayCurtInSeconds / controlCycle);
            obj.batt = ceil(delayBattInSeconds / controlCycle);
            obj.zone2Controller = ceil(delayZone2ControllerInSeconds / controlCycle);
            obj.controller2Zone = ceil(delayController2ZoneInSeconds / controlCycle);
            obj.timeSeries2Zone = ceil(delayTimeSeries2ZoneInSeconds / controlCycle);
        end
    end
    
end