classdef TelecomController2Zone < Telecommunication
    
    properties
        bufferQueueData % 1st element is to be sent, last element is the last received
        delayTelecom
    end
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, delayTelecom)
            obj.delayTelecom = delayTelecom;
            controlArray(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.bufferQueueData = controlArray;
        end
        
        function control = receive(obj, emitter)
            control = emitter.getControl();
        end
        
        function store(obj, newControl)
            obj.bufferQueueData(end+1) = newControl;
        end
        
        function send(obj, receiver)
            sentControl = obj.bufferQueueData(1);
            receiver.receiveControl(sentControl)
        end
        
        function dropOldestData(obj)
            obj.bufferQueueData = obj.bufferQueueData(2:end);
        end
           
        function transmitData(obj, emitter, receiver)
            control = obj.receive(emitter);
            obj.store(control);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
    end
end