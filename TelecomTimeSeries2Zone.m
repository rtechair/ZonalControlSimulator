classdef TelecomTimeSeries2Zone < Telecommunication
    
    methods
        function obj = TelecomTimeSeries2Zone(numberOfGen, delayTelecom)
            obj.delay = delayTelecom;
            blankDisturbance(1: delayTelecom) = DisturbancePowerAvailable(numberOfGen);
            obj.queueData = blankDisturbance;
        end
    end
    
    methods (Access = protected)
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getDisturbancePowerAvailable();
        end
        
        function send(obj, receiver)
            receiver.receiveTimeSeries(obj.queueData(1));
        end
    end
    
end
    