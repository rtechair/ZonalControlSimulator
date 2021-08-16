classdef Limiter < Controller
   
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