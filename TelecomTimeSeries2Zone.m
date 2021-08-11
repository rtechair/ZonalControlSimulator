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
        
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getTimeSeries();
        end
        
        function send(obj, receiver)
            receiver.receiveTimeSeries(obj.queueData(1));
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
        
        function transmitData(obj, emitter, receiver)
            obj.receive(emitter);
            obj.send(receiver);
            obj.dropOldestData();
            emitter.prepareForNextStep();
        end    
    end
end
    