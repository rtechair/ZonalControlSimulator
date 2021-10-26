%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

classdef TelecomZone2Controller < handle
    
    properties (SetAccess = protected)
        stateQueue
        disturbancePowerTransitQueue
        disturbancePowerAvailableQueue
        delay
    end
    
    methods
        
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            obj.delay = delayTelecom;
            blankStateQueue(1:delayTelecom) = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            obj.stateQueue = blankStateQueue;
            obj.disturbancePowerTransitQueue = zeros(numberOfBuses, delayTelecom);
            obj.disturbancePowerAvailableQueue = zeros(numberOfGen, delayTelecom);
        end
        
        function receiveState(obj, state)
            obj.stateQueue(obj.delay+1) = state;
        end
        
        function receiveDisturbancePowerTransit(obj, value)
            obj.disturbancePowerTransitQueue(:, obj.delay+1) = value;
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
        
        function receiveDisturbancePowerAvailable(obj, disturbance)
            obj.disturbancePowerAvailableQueue(:, obj.delay+1) = disturbance;
        end
        
        function sendDisturbancePowerAvailable(obj, controller)
            sentDisturbance = obj.dequeueDisturbancePowerAvailable();
            controller.receiveDisturbancePowerAvailable(sentDisturbance);
        end
        
        function value = dequeueDisturbancePowerAvailable(obj)
            value = obj.disturbancePowerAvailableQueue(:,1);
            obj.disturbancePowerAvailableQueue = obj.disturbancePowerAvailableQueue(:, 2:end);
        end
        
    end
    
end