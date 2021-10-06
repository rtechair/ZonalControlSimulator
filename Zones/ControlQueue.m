classdef ControlQueue < handle
    
    properties (SetAccess = protected)
        curtControlQueue
        battControlQueue
        delayCurt
        delayBatt
    end
    
    methods
        function obj = ControlQueue(...
                numberOfGenOn, delayCurt, numberOfBattOn, delayBatt)
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            obj.curtControlQueue = [zeros(numberOfGenOn, delayCurt) NaN(numberOfGenOn, 1)];
            obj.battControlQueue = [zeros(numberOfBattOn, delayBatt) NaN(numberOfBattOn, 1)];
        end
        
        function enqueue(obj, controlOfZone)
            obj.curtControlQueue(:,obj.delayCurt+1) = controlOfZone.getControlCurtailment();
            obj.battControlQueue(:,obj.delayBatt+1) = controlOfZone.getControlBattery();
        end
        
        function control = dequeue(obj)
            control = obj.getFirst();
            obj.removeFirst();
        end
        
    end
    
    methods (Access = private)
        function control = getFirst(obj)
            controlCurt = obj.curtControlQueue(:,1);
            controlBatt = obj.battControlQueue(:,1);
            control = ControlOfZone(controlCurt, controlBatt);
        end
        
        function removeFirst(obj)
            obj.curtControlQueue = obj.curtControlQueue(:, 2:obj.delayCurt+1);
            obj.battControlQueue = obj.battControlQueue(:, 2:obj.delayBatt+1);
        end
    end
    
end