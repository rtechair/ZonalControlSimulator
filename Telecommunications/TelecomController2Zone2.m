classdef TelecomController2Zone2 < handle
    
    properties (SetAccess = protected)
        controlQueue
        delay
    end
    
    methods
        function obj = TelecomController2Zone2(numberOfGen, numberOfBatt, telecomDelay)
            obj.delay = telecomDelay;
            blankControlCurtailment = zeros(numberOfGen,1);
            blankControlBattery = zeros(numberOfBatt,1);
            blankControls(1:delayTelecom) = ControlOfZone(blankControlCurtailment, blankControlBattery);
            obj.controlQueue = blankControls;
        end
        
        function receiveControl(obj, control)
            obj.enqueue(control);
        end
        
        function control = sendControl(obj)
            control = obj.dequeue();
        end
        
    end
    
    methods (Access = protected)
        
        function enqueue(obj, control)
            obj.controlQueue(obj.delay+1) = control;
        end
        
        function control = dequeue(obj)
            control = obj.controlQueue(1);
            obj.controlQueue = obj.controlQueue(2 : obj.delay+1);
        end
        
    end
    
end