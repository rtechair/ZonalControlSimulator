classdef TelecomZone2Controller < Telecommunication
    
    properties
        BufferQueueData
        DelayTelecom
    end
    
    methods
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            
            obj.DelayTelecom = delayTelecom;
            
            blankState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            blankDisturbanceTransit = zeros(numberOfBuses, 1);            
            stateAndDistTransitArray(1:delayTelecom) = ...
                StateAndDisturbanceTransit(blankState, blankDisturbanceTransit);
            
            obj.BufferQueueData = stateAndDistTransitArray;
        end
        
        function data = receive(obj, emitter)
            data = emitter.getStateAndDistTransit();
        end
        
        function store(obj, newStateAndDistTransit)
            obj.BufferQueueData(end+1) = newStateAndDistTransit;
        end
        
        function send(obj, receiver)
            sentStateAndDisturbTransit = obj.BufferQueueData(1);
            receiver.receiveStateAndDistTransit(sentStateAndDisturbTransit)
        end
        
        function dropOldestData(obj)
            obj.BufferQueueData = obj.BufferQueueData(2:end);
        end
        
        function receiveThenSend(obj, emitter, receiver)
            stateAndDisturbTransit = obj.receive(emitter);
            obj.store(stateAndDisturbTransit);
            obj.send(receiver);
            obj.dropOldestData();
        end
    end
end