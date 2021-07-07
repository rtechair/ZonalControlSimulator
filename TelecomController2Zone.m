classdef TelecomController2Zone < Telecommunication
    
    properties
        BufferQueueData
        DelayTelecom
    end
    
    methods
        function obj = TelecomController2Zone(delayTelecom, ...
                numberOfGen, numberOfBatt)
            obj.DelayTelecom = delayTelecom;
            controlArray(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.BufferQueueData = controlArray;

        end
        
        function control = receive(obj, emitter)
            control = emitter.getControl(); %TODO check it works
        end
        
        function store(obj, newControl)
            obj.BufferQueueData(end+1) = newControl;
        end
        
        function send(obj, receiver)
            sentControl = obj.BufferQueueData(end - obj.DelayTelecom);
            receiver.receiveControl(sentControl) %TODO check it works
        end
        
        function dropOldestData(obj)
            obj.BufferQueueData = obj.BufferQueueData(2:end);
        end
           
        function receiveThenSend(obj, emitter, receiver)
            control = obj.receive(emitter);
            obj.store(control);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
    end
end