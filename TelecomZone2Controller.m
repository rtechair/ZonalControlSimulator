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
        
        function transmitData(obj, emitter, receiver)
            obj.receive(emitter);
            obj.send(receiver);
            obj.dropOldestData();
        end
    end
    
    methods (Access = protected)       
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getStateAndDistTransit();
        end
        
        function send(obj, receiver)
            receiver.receiveStateAndDistTransit(obj.queueData(1))
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
    end
    
end