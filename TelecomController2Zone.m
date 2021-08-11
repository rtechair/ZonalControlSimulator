classdef TelecomController2Zone < Telecommunication
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, delayTelecom)
            obj.delay = delayTelecom;
            blankControl(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.queueData = blankControl;
        end
    end
    
    methods (Access = protected)
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getControl();
        end
        
        function send(obj, receiver)
            receiver.receiveControl(obj.queueData(1))
        end
    end
    
end