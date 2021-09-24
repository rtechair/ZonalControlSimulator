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

classdef StateAndDisturbancePowerTransit < handle
% Wrapper class of an object STATE + a value DISTURBANCE POWER TRANSIT
% such that the telecommunication, from the zone to the controller,
% manipulates 1 object instead 1 object + 1 value.
   properties (SetAccess = protected, GetAccess = protected)
      stateOfZone
      disturbancePowerTransit
   end
    
   methods
       function obj = StateAndDisturbancePowerTransit(objectStateOfZone, valueDisturbancePowerTransit)
           obj.stateOfZone = objectStateOfZone;
           obj.disturbancePowerTransit = valueDisturbancePowerTransit;
       end
       
       function object = getStateOfZone(obj)
           object = obj.stateOfZone;
       end
       
       function value = getDisturbancePowerTransit(obj)
           value = obj.disturbancePowerTransit;
       end
   end
end