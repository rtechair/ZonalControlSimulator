classdef TelecomTimeSeries2Zone < Telecommunication
    
    properties
        BufferQueueData
        DelayTelecom
    end
    
    methods
        
        function obj = TelecomTimeSeries2Zone(delayTelecom, numberOfGen)
            obj.DelayTelecom = delayTelecom;
            disturbanceArray(1: delayTelecom) = DisturbancePowerAvailable(numberOfGen);
            obj.BufferQueueData = disturbanceArray;
        end
        
        function disturbance = receive(obj, emitter)
            disturbance = emitter.getTimeSeries();
        end
        
        
        function store(obj, newDisturbance)
            obj.BufferQueueData(end+1) = newDisturbance;
        end
        
        
        function send(obj, receiver)
            sentDisturbance = obj.BufferQueueData(end - obj.DelayTelecom);
            receiver.receiveTimeSeries(sentDisturbance);
        end
        
        function dropOldestData(obj)
            obj.BufferQueueData = obj.BufferQueueData(2:end);
        end
        
        function receiveThenSend(obj, emitter, receiver)
            disturbance = obj.receive(emitter);
            obj.store(disturbance);
            obj.send(receiver);
            obj.dropOldestData();
            emitter.prepareForNextStep();
        end
            
            
    end
end
    