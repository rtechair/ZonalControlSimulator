classdef TelecomTimeSeries2Zone < Telecommunication
    
    properties
        queueData
        delay
    end
    
    methods
        
        function obj = TelecomTimeSeries2Zone(numberOfGen, delayTelecom)
            obj.delay = delayTelecom;
            disturbanceArray(1: delayTelecom) = DisturbancePowerAvailable(numberOfGen);
            obj.queueData = disturbanceArray;
        end
        
        function disturbance = receive(obj, emitter)
            disturbance = emitter.getTimeSeries();
        end
        
        
        function store(obj, newDisturbance)
            obj.queueData(end+1) = newDisturbance;
        end
        
        
        function send(obj, receiver)
            sentDisturbance = obj.queueData(1);
            receiver.receiveTimeSeries(sentDisturbance);
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
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
    