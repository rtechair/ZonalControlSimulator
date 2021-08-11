classdef TelecomController2Zone < Telecommunication
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, delayTelecom)
            obj.delay = delayTelecom;
            controlArray(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.queueData = controlArray;
        end
        
        function transmitData(obj, emitter, receiver)
            obj.receive(emitter);
            obj.send(receiver);
            obj.dropOldestData();
        end
    end
    
    methods (Access = protected)
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getControl();
        end
        
        function send(obj, receiver)
            receiver.receiveControl(obj.queueData(1))
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
    end
    
end