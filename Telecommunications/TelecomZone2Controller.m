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

classdef TelecomZone2Controller < Telecommunication
    
    methods
        function obj = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, delayTelecom)
            
            obj.delay = delayTelecom;
            
            blankState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            blankDisturbancePowerTransit = zeros(numberOfBuses, 1);
            blankStateAndDisturbancePowerTransit(1:delayTelecom) = ...
                StateAndDisturbancePowerTransit(blankState, blankDisturbancePowerTransit);
            
            obj.queueData = blankStateAndDisturbancePowerTransit;
        end
    end
    
    methods (Access = protected)
        function receive(obj, emitter)
            obj.queueData(end+1) = emitter.getStateAndDisturbancePowerTransit();
        end
        
        function send(obj, receiver)
            receiver.receiveStateAndDisturbancePowerTransit(obj.queueData(1));
        end
    end
    
end