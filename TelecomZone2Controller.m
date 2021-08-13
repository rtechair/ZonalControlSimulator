classdef TelecomZone2Controller < Telecommunication
    
    methods
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            
            obj.delay = delayTelecom;
            
            blankState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            blankDisturbanceTransit = zeros(numberOfBuses, 1);            
            blankStateAndDistTransit(1:delayTelecom) = ...
                StateAndDisturbanceTransit(blankState, blankDisturbanceTransit);
            
            obj.queueData = blankStateAndDistTransit;
        end
    end
    
    methods (Access = protected)       
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getStateAndDistTransit();
        end
        
        function send(obj, receiver)
            receiver.receiveStateAndDisturbancePowerTransit(obj.queueData(1));
        end
    end
    
end