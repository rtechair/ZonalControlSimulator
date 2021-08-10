classdef (Abstract) Telecommunication < handle

    properties (Abstract)
        bufferQueueData
        delayTelecom
    end
    

    methods (Abstract)
        
        data = receive(obj, emitter);
        store(obj, newData);
        send(obj, receiver);
        transmitData;
    end
    
  
    
end