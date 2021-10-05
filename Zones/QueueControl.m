classdef QueueControl < handle
    
    properties (SetAccess = protected)
        queueControlCurt
        queueControlBatt
        
        delayCurt
        delayBatt
    end
    
    methods
        function obj = QueueControl(...
                numberOfGenOn, delayCurt, numberOfBattOn, delayBatt)
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            obj.queueControlCurt = [zeros(numberOfGenOn, delayCurt) NaN(numberOfGenOn, 1)];
            obj.queueControlBatt = [zeros(numberOfBattOn, delayBatt) NaN(numberOfBattOn, 1)];
        end
        
        function controlToApply = dequeue(obj)
            controlCurtToApply = obj.queueControlCurt(:,1);
            controlBattToApply = obj.queueControlBatt(:,1);
            controlToApply = ControlOfZone(controlCurtToApply, controlBattToApply);
            obj.removeFirst();
        end
        
        function enqueue(obj, controlOfZone)
            obj.queueControlCurt(:,obj.delayCurt+1) = controlOfZone.getControlCurtailment();
            obj.queueControlBatt(:,obj.delayBatt+1) = controlOfZone.getControlBattery();
        end
        
        function removeFirst(obj)
            obj.queueControlCurt = obj.queueControlCurt(:, 2:obj.delayCurt+1);
            obj.queueControlBatt = obj.queueControlBatt(:, 2:obj.delayBatt+1);
        end
    end
end