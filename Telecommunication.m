classdef (Abstract) Telecommunication < handle

    properties (Abstract)
        BufferQueueData
        DelayTelecom
    end
    

    methods (Abstract)
        
        data = receive(obj, Emitter);
        store(obj, newData);
        send(obj, Receiver);
        receiveThenSend;
    end
    
  
    
end