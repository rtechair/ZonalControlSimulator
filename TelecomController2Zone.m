classdef TelecomController2Zone < Telecommunication
    
    properties
        queueData
        delay
    end
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, delayTelecom)
            obj.delay = delayTelecom;
            controlArray(1:delayTelecom) = ControlOfZone(numberOfGen, numberOfBatt);
            obj.queueData = controlArray;
        end
        
        function control = receive(obj, emitter)
            control = emitter.getControl();
        end
        
        function store(obj, newControl)
            obj.queueData(end+1) = newControl;
        end
        
        function send(obj, receiver)
            sentControl = obj.queueData(1);
            receiver.receiveControl(sentControl)
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
           
        function transmitData(obj, emitter, receiver)
            control = obj.receive(emitter);
            obj.store(control);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
    end
end