classdef Limiter < Controller
   
    properties (SetAccess = protected)
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
            branchFlowState = obj.state.powerBranchFlow;
            if obj.isABranchOverHighFlowThreshold(branchFlowState) && obj.canCurtailmentIncrease()
                obj.increaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateQueueControlCurtPercent();
            elseif obj.areAllBranchesUnderLowFlowThreshold(branchFlowState) && obj.canCurtailmentDecrease()
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
        
        function receiveStateAndDistTransit(obj, stateAndDistTransit)
            obj.state = stateAndDistTransit.getStateOfZone();
            obj.disturbancePowerTransit = stateAndDistTransit.getDisturbanceTransit();
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
            obj.dropOldestControl();
            obj.addNewControl();
        end
        
        function dropOldestControl(obj)
            obj.queueControlCurtPercent = obj.queueControlCurtPercent(2:end);
        end
        
        function addNewControl(obj)
            obj.queueControlCurtPercent = [obj.queueControlCurtPercent obj.controlCurtPercent];
        end

    end
    
end