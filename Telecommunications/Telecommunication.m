classdef (Abstract) Telecommunication < handle

    properties (SetAccess = protected, GetAccess = protected)
        queueData % 1st element is sent, last element is the last received
        delay
    end


    methods (Abstract, Access = protected)
        receive(obj, emitter);
        send(obj, receiver);
    end
    
    methods
        function transmitData(obj, emitter, receiver)
            obj.receive(emitter);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
    end

end