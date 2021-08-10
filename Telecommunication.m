classdef (Abstract) Telecommunication < handle

    properties (Abstract)
        queueData % 1st element is to be sent, last element is the last received
        delay
    end

    methods (Abstract)
        
        receive(obj, emitter);
        send(obj, receiver);
        transmitData(obj, emitter, receiver);
    end

end