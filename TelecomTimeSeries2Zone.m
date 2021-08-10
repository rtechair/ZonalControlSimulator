classdef TelecomTimeSeries2Zone < Telecommunication
    
    properties
        bufferQueueData
        delayTelecom
    end
    
    methods
        
        function obj = TelecomTimeSeries2Zone(numberOfGen, delayTelecom)
            obj.delayTelecom = delayTelecom;
            disturbanceArray(1: delayTelecom) = DisturbancePowerAvailable(numberOfGen);
            obj.bufferQueueData = disturbanceArray;
        end
        
        function disturbance = receive(obj, emitter)
            disturbance = emitter.getTimeSeries();
        end
        
        
        function store(obj, newDisturbance)
            obj.bufferQueueData(end+1) = newDisturbance;
        end
        
        
        function send(obj, receiver)
            sentDisturbance = obj.bufferQueueData(1);
            receiver.receiveTimeSeries(sentDisturbance);
        end
        
        function dropOldestData(obj)
            obj.bufferQueueData = obj.bufferQueueData(2:end);
        end
        
        function transmitData(obj, emitter, receiver)
            disturbance = obj.receive(emitter);
            obj.store(disturbance);
            obj.send(receiver);
            obj.dropOldestData();
            emitter.prepareForNextStep();
        end    
    end
end
    