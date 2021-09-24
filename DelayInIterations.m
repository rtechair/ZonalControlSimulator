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

classdef DelayInIterations < handle
% Compute the delays which are supplied in seconds,
% to their associate values in number of iterations
    properties (SetAccess = immutable, GetAccess = protected)
        delayCurt
        delayBatt
        delayZone2Controller
        delayController2Zone
        delayTimeSeries2Zone
    end
    
    methods
        function obj = DelayInIterations(controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayZone2ControllerInSeconds, ...
                delayController2ZoneInSeconds, ...
                delayTimeSeries2ZoneInSeconds)
            obj.delayCurt = ceil(delayCurtInSeconds / controlCycle);
            obj.delayBatt = ceil(delayBattInSeconds / controlCycle);
            obj.delayZone2Controller = ceil(delayZone2ControllerInSeconds / controlCycle);
            obj.delayController2Zone = ceil(delayController2ZoneInSeconds / controlCycle);
            obj.delayTimeSeries2Zone = ceil(delayTimeSeries2ZoneInSeconds / controlCycle);
        end
        
        function value = getDelayCurt(obj)
            value = obj.delayCurt;
        end
        
        function value = getDelayBatt(obj)
            value = obj.delayBatt;
        end
        
        function value = getDelayZone2Controller(obj)
            value = obj.delayZone2Controller;
        end
        
        function value = getDelayController2Zone(obj)
            value = obj.delayController2Zone;
        end
        
        function value = getDelayTimeSeries2Zone(obj)
            value = obj.delayTimeSeries2Zone;
        end
    end
    
end