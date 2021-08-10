classdef TelecomZone2Controller < Telecommunication
    
    properties
        queueData
        delay
    end
    
    methods
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            
            obj.delay = delayTelecom;
            
            blankState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            blankDisturbanceTransit = zeros(numberOfBuses, 1);            
            stateAndDistTransitArray(1:delayTelecom) = ...
                StateAndDisturbanceTransit(blankState, blankDisturbanceTransit);
            
            obj.queueData = stateAndDistTransitArray;
        end
        
        function data = receive(obj, emitter)
            data = emitter.getStateAndDistTransit();
        end
        
        function store(obj, newStateAndDistTransit)
            obj.queueData(end+1) = newStateAndDistTransit;
        end
        
        function send(obj, receiver)
            sentStateAndDisturbTransit = obj.queueData(1);
            receiver.receiveStateAndDistTransit(sentStateAndDisturbTransit)
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
        
        function transmitData(obj, emitter, receiver)
            stateAndDisturbTransit = obj.receive(emitter);
            obj.store(stateAndDisturbTransit);
            obj.send(receiver);
            obj.dropOldestData();
        end
    end
end