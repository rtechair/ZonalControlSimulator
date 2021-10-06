classdef TelecomZone2Controller < handle
    
    properties (SetAccess = protected)
        stateQueue
        disturbancePowerTransitQueue
        delay
    end
    
    methods
        
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            obj.delay = delayTelecom;
            blankStateQueue(1:delayTelecom) = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            obj.stateQueue = blankStateQueue;
            obj.disturbancePowerTransitQueue = zeros(numberOfBuses, delayTelecom);
        end
        
        function receiveState(obj, state)
            obj.stateQueue(obj.delay+1) = state;
        end
        
        function receiveDisturbancePowerTransit(obj, value)
            obj.disturbancePowerTransitQueue(obj.delay+1) = value;
        end
        
        function sendState(obj, controller)
            sentState = obj.dequeueState();
            controller.receiveState(sentState);
        end
        
        function object = dequeueState(obj)
            object = obj.stateQueue(1);
            obj.stateQueue = obj.stateQueue(2:end);
        end
        
        function sendDisturbancePowerTransit(obj, controller)
            sentDisturbancePowerTransit = obj.dequeueDisturbancePowerTransit();
            controller.receiveDisturbancePowerTransit(sentDisturbancePowerTransit);
        end
        
        function value = dequeueDisturbancePowerTransit(obj)
             value = obj.disturbancePowerTransitQueue(:,1);
             obj.disturbancePowerTransitQueue = obj.disturbancePowerTransitQueue(:, 2:end);
        end
        
    end
    
end