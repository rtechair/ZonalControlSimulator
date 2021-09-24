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

classdef (Abstract) Telecommunication < handle

    properties (SetAccess = protected, GetAccess = protected)
        queueData % 1st element is sent, last element is the last received
        delay
    end


    methods (Abstract, Access = protected)
        receive(obj, emitter);
        send(obj, receiver);
    end
    
    methods
        function transmitData(obj, emitter, receiver)
            obj.receive(emitter);
            obj.send(receiver);
            obj.dropOldestData();
        end
        
        function dropOldestData(obj)
            obj.queueData = obj.queueData(2:end);
        end
    end

end