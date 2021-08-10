classdef TelecomZone2Controller < Telecommunication
    
    properties
        bufferQueueData
        delayTelecom
    end
    
    methods
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            
            obj.delayTelecom = delayTelecom;
            
            blankState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            blankDisturbanceTransit = zeros(numberOfBuses, 1);            
            stateAndDistTransitArray(1:delayTelecom) = ...
                StateAndDisturbanceTransit(blankState, blankDisturbanceTransit);
            
            obj.bufferQueueData = stateAndDistTransitArray;
        end
        
        function data = receive(obj, emitter)
            data = emitter.getStateAndDistTransit();
        end
        
        function store(obj, newStateAndDistTransit)
            obj.bufferQueueData(end+1) = newStateAndDistTransit;
        end
        
        function send(obj, receiver)
            sentStateAndDisturbTransit = obj.bufferQueueData(1);
            receiver.receiveStateAndDistTransit(sentStateAndDisturbTransit)
        end
        
        function dropOldestData(obj)
            obj.bufferQueueData = obj.bufferQueueData(2:end);
        end
        
        function transmitData(obj, emitter, receiver)
            stateAndDisturbTransit = obj.receive(emitter);
            obj.store(stateAndDisturbTransit);
            obj.send(receiver);
            obj.dropOldestData();
        end
    end
end