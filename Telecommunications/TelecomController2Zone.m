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
classdef TelecomController2Zone < handle
    
    properties (SetAccess = protected)
        controlQueue
        delay
    end
    
    methods
        function obj = TelecomController2Zone(numberOfGen, numberOfBatt, telecomDelay)
            obj.delay = telecomDelay;
            blankControlCurtailment = zeros(numberOfGen,1);
            blankControlBattery = zeros(numberOfBatt,1);
            blankControls(1:telecomDelay) = ControlOfZone(blankControlCurtailment, blankControlBattery);
            obj.controlQueue = blankControls;
        end
        
        function receiveControl(obj, control)
            obj.enqueue(control);
        end
        
        function control = sendControl(obj)
            control = obj.dequeue();
        end
        
    end
    
    methods (Access = protected)
        
        function enqueue(obj, control)
            obj.controlQueue(obj.delay+1) = control;
        end
        
        function control = dequeue(obj)
            control = obj.controlQueue(1);
            obj.controlQueue = obj.controlQueue(2 : obj.delay+1);
        end
        
    end
    
end