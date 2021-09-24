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

classdef Limiter < Controller
% Controller with simple mechanism, used to test the simulator, it will be later substracted with more complex controllers.
% The mechanism is applied in the method 'computeControl' and fondamentally is:
% - if a power flow is too high, increase the generator curtailment to reduce the generation.
% - if all power flows are too low, reduce the curtailment
% - else, do nothing.
%
% Limiter's parameters are defined in the associate json file of the limiter, with respect to a zone,
% e.g. for zone 'VG', the limiter's parameters are in 'limiterVG.json'.
    properties (SetAccess = protected, GetAccess = protected)
       queueControlCurtPercent
       futureStateCurtPercent
       controlCurtPercent
       controlBatt
       
       state
       disturbancePowerTransit % unused by the Limiter
    end    
    
    properties (SetAccess = immutable)
        echelonIncreaseCurtPercent
        echelonDecreaseCurtPercent
        
        lowFlowThreshold
        highFlowThreshold
        
        maxPowerGeneration
    end
        
    
    methods
        function obj = Limiter(powerFlowLimit, numberOfBatt,...
                echelonIncreaseCurtPercent, absoluteEchelonDecreaseCurtPercent, ...
                lowerThresholdPercent, upperThresholdPercent, ...
                delayCurtailment, maxPowerGeneration)
            
            obj.maxPowerGeneration = maxPowerGeneration;
            
            obj.echelonIncreaseCurtPercent = echelonIncreaseCurtPercent;
            obj.echelonDecreaseCurtPercent = - absoluteEchelonDecreaseCurtPercent;
            
            obj.lowFlowThreshold = lowerThresholdPercent * powerFlowLimit;
            obj.highFlowThreshold = upperThresholdPercent * powerFlowLimit;
            
            obj.doNotUseBatteries(numberOfBatt);
            
            obj.queueControlCurtPercent = zeros(1, delayCurtailment);
            obj.futureStateCurtPercent = 0;
        end
        
        function value = getControlCurtailment(obj)
            value = obj.controlCurtPercent * obj.maxPowerGeneration;
        end
        
        function value = getControlBattery(obj)
            value = obj.controlBatt;
        end
        
        function objectControl = getControl(obj)
            controlCurt = obj.getControlCurtailment();
            objectControl = ControlOfZone(controlCurt, obj.controlBatt);
        end
        
        function computeControl(obj)
            powerFlow = obj.state.getPowerFlow;
            doesCurtailmentIncrease = obj.isABranchOverHighFlowThreshold(powerFlow) ...
                && obj.canCurtailmentIncrease();
            doesCurtailmentDecrease = obj.areAllBranchesUnderLowFlowThreshold(powerFlow) ...
                && obj.canCurtailmentDecrease();
            
            if doesCurtailmentIncrease
                obj.increaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateQueueControlCurtPercent();
            elseif doesCurtailmentDecrease
                obj.decreaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateQueueControlCurtPercent();
            else
                obj.doNotAlterCurtailment();
                obj.updateQueueControlCurtPercent();
            end
        end
        
        function saveControl(obj, memory)
            controlCurt = obj.getControlCurtailment();
            memory.saveControl(controlCurt, obj.controlBatt);
        end
        
        function receiveStateAndDisturbancePowerTransit(obj, stateAndDisturbancePowerTransit)
            obj.state = stateAndDisturbancePowerTransit.getStateOfZone();
            obj.disturbancePowerTransit = stateAndDisturbancePowerTransit.getDisturbancePowerTransit();
        end
        
    end
    
    methods (Access = protected) 
        
        function doNotUseBatteries(obj, numberOfBatt)
            % the curtailment limiter does not use the batteries
            obj.controlBatt = zeros(numberOfBatt,1);
        end
        
        function increaseCurtailment(obj)
            obj.controlCurtPercent = obj.echelonIncreaseCurtPercent;
        end
        
        function decreaseCurtailment(obj)
            obj.controlCurtPercent = obj.echelonDecreaseCurtPercent;
        end
        
        function doNotAlterCurtailment(obj)
            obj.controlCurtPercent = 0;
        end
                   
        
        function boolean = isABranchOverHighFlowThreshold(obj, branchFlowState)
           boolean = any( abs(branchFlowState) > obj.highFlowThreshold );
        end
        
        function boolean = areAllBranchesUnderLowFlowThreshold(obj, branchFlowState)
            boolean = all( abs(branchFlowState) < obj.lowFlowThreshold );
        end
        
        function boolean = canCurtailmentIncrease(obj)
            boolean = (obj.futureStateCurtPercent + obj.echelonIncreaseCurtPercent) <= 1;
        end
        
        function boolean = canCurtailmentDecrease(obj)
            boolean = (obj.futureStateCurtPercent + obj.echelonDecreaseCurtPercent) >= 0;
        end
        
        function updateFutureCurtailment(obj)
            obj.futureStateCurtPercent = obj.futureStateCurtPercent + obj.controlCurtPercent;
        end
        
        function updateQueueControlCurtPercent(obj)
            obj.dropOldestControlCurt();
            obj.addNewControlCurt();
        end
        
        function dropOldestControlCurt(obj)
            obj.queueControlCurtPercent = obj.queueControlCurtPercent(2:end);
        end
        
        function addNewControlCurt(obj)
            obj.queueControlCurtPercent = [obj.queueControlCurtPercent obj.controlCurtPercent];
        end

    end
    
end