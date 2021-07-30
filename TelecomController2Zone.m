classdef TelecomController2Zone < Telecommunication
    
    properties
        BufferQueueData % 1st element is to be sent, last element is the last received
        DelayTelecom
    end
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, delayTelecom)
            obj.DelayTelecom = delayTelecom;
            controlArray(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.BufferQueueData = controlArray;
        end
        
        function control = receive(obj, emitter)
            control = emitter.getControl();
        end
        
        function store(obj, newControl)
            obj.BufferQueueData(end+1) = newControl;
        end
        
        function send(obj, receiver)
            sentControl = obj.BufferQueueData(1);
            receiver.receiveControl(sentControl)
        end
        
        function dropOldestData(obj)
            obj.BufferQueueData = obj.BufferQueueData(2:end);
        end
           
        function transmitData(obj, emitter, receiver)
            control = obj.receive(emitter);
            obj.store(control);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
    end
end