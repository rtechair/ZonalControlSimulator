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
classdef ControllerMpcSetting < handle
    
   properties (SetAccess = protected)
       
       settings
       
       predictionHorizonInSeconds
       numberOfScenarios
       overloadCost
       maxOverload
   end
   
   methods
       function obj = ControllerMpcSetting(controllerMpcFilename)
           obj.settings = decodeJsonFile(controllerMpcFilename);
           
           obj.setPredictionHorizonInSeconds();
           obj.setNumberOfScenarios();
           obj.setOverLoadCost();
           obj.setMaxOverload();
       end
       
   end
   
   methods(Access = private)
       %% SETTER
       function setPredictionHorizonInSeconds(obj)
           obj.predictionHorizonInSeconds = obj.settings.predictionHorizonInSeconds;
       end
       
       function setNumberOfScenarios(obj)
           obj.numberOfScenarios = obj.settings.numberOfScenarios;
       end
       
       function setOverLoadCost(obj)
           obj.overloadCost = obj.settings.overloadCost;
       end
       
       function setMaxOverload(obj)
           obj.maxOverload = obj.settings.maxOverload;
       end
   end
   
   methods
      %% GETTER
      function value = getPredictionHorizonInSeconds(obj)
           value = obj.predictionHorizonInSeconds;
       end
       
       function value = getNumberOfScenarios(obj)
           value = obj.numberOfScenarios;
       end
       
       function value = getOverLoadCost(obj)
           value = obj.overloadCost;
       end
       
       function value = getMaxOverload(obj)
           value = obj.maxOverload;
       end
   end
end