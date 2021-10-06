classdef ControlQueue < handle
    
    properties (SetAccess = protected)
        curtControlQueue
        battControlQueue
        curtDelay
        battDelay
    end
    
    methods
        function obj = ControlQueue(...
                numberOfGenOn, curtDelay, numberOfBattOn, battDelay)
            obj.curtDelay = curtDelay;
            obj.battDelay = battDelay;
            obj.curtControlQueue = [zeros(numberOfGenOn, curtDelay) NaN(numberOfGenOn, 1)];
            obj.battControlQueue = [zeros(numberOfBattOn, battDelay) NaN(numberOfBattOn, 1)];
        end
        
        function enqueue(obj, controlOfZone)
            obj.curtControlQueue(:,obj.curtDelay+1) = controlOfZone.getControlCurtailment();
            obj.battControlQueue(:,obj.battDelay+1) = controlOfZone.getControlBattery();
        end
        
        function controlToApply = dequeue(obj)
            controlCurtToApply = obj.curtControlQueue(:,1);
            controlBattToApply = obj.battControlQueue(:,1);
            controlToApply = ControlOfZone(controlCurtToApply, controlBattToApply);
            obj.removeFirst();
        end
        
        function removeFirst(obj)
            obj.curtControlQueue = obj.curtControlQueue(:, 2:obj.curtDelay+1);
            obj.battControlQueue = obj.battControlQueue(:, 2:obj.battDelay+1);
        end
    end
end