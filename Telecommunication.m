classdef (Abstract) Telecommunication < handle

    properties (Abstract)
        queueData % 1st element is to be sent, last element is the last received
        delay
    end

    methods (Abstract)
        transmitData(obj, emitter, receiver);
    end
    
    methods(Abstract, Access = protected)
        receive(obj, emitter);
        send(obj, receiver);
    end

end