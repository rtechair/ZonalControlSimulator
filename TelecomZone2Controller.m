classdef TelecomZone2Controller < Telecommunication
    
    properties
        BufferQueueData
        DelayTelecom
    end
    
    methods
        function obj = TelecomZone2Controller(delayTelecom,...
                numberOfGen, numberOfBatt, numberOfBuses, numberOfBranches)
            
            obj.DelayTelecom = delayTelecom;
            blankState = StateOfZone(numberOfGen, numberOfBatt, ...
                numberOfBranches);
            blankDisturbanceTransit = zeros(numberOfBuses, 1);
            
            stateAndDistTransitArray(1:delayTelecom) = StateAndDisturbanceTransit(blankState, ...
                blankDisturbanceTransit);
            
            
            
            % stateAndDistTransitArray(1:delayTelecom) = StateAndDisturbanceTransit(numberOfGen, numberOfBatt); %TODO
            % where DataFromZone corresponds to StateOfZone and
            % disturbanceTransit
            obj.BufferQueueData = stateAndDistTransitArray;

            %TODO
        end
        
        function data = receive(obj, emitter)
            data = emitter.getStateAndDistTransit(); %TODO
        end
        
        function store(obj, newStateAndDistTransit)
            obj.BufferQueueData(end+1) = newStateAndDistTransit;
        end
        
        function send(obj, receiver)
            sentStateAndDisturbTransit = obj.BufferQueueData(end - obj.DelayTelecom);
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