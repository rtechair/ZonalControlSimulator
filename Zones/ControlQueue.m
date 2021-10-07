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

classdef ControlQueue < handle
    
    properties (SetAccess = protected)
        curtControlQueue
        battControlQueue
        delayCurt
        delayBatt
    end
    
    methods
        function obj = ControlQueue(...
                numberOfGenOn, delayCurt, numberOfBattOn, delayBatt)
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            obj.curtControlQueue = [zeros(numberOfGenOn, delayCurt) NaN(numberOfGenOn, 1)];
            obj.battControlQueue = [zeros(numberOfBattOn, delayBatt) NaN(numberOfBattOn, 1)];
        end
        
        function enqueue(obj, controlOfZone)
            obj.curtControlQueue(:,obj.delayCurt+1) = controlOfZone.getControlCurtailment();
            obj.battControlQueue(:,obj.delayBatt+1) = controlOfZone.getControlBattery();
        end
        
        function control = dequeue(obj)
            control = obj.getFirst();
            obj.removeFirst();
        end
        
    end
    
    methods (Access = private)
        function control = getFirst(obj)
            controlCurt = obj.curtControlQueue(:,1);
            controlBatt = obj.battControlQueue(:,1);
            control = ControlOfZone(controlCurt, controlBatt);
        end
        
        function removeFirst(obj)
            obj.curtControlQueue = obj.curtControlQueue(:, 2:obj.delayCurt+1);
            obj.battControlQueue = obj.battControlQueue(:, 2:obj.delayBatt+1);
        end
    end
    
end