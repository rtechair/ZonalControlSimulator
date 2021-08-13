classdef Limiter < Controller
   
    properties (SetAccess = protected)
       queueDelayedCurtControlPercent
       futureStateCurt
       curtControlPercent
       noBatteryInjectionControl
       
       state
       distTransit
    end
    
    
    properties (SetAccess = immutable)
        branchFlowLimit
        
        increaseCurtPercentEchelon
        decreaseCurtPercentEchelon
        
        lowFlowThreshold
        highFlowThreshold
        
        numberOfGen
        numberOfBatt
        maxGeneration
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                increaseCurtPercentEchelon, decreaseCurtPercentEchelon, lowerThresholdPercent, upperThresholdPercent, ...
                delayCurtailment, maxGeneration)
            
            obj.maxGeneration = maxGeneration;
            obj.branchFlowLimit = branchFlowLimit;
            
            
            obj.increaseCurtPercentEchelon = increaseCurtPercentEchelon;
            obj.decreaseCurtPercentEchelon = - decreaseCurtPercentEchelon;
            
            obj.lowFlowThreshold = lowerThresholdPercent * branchFlowLimit;
            obj.highFlowThreshold = upperThresholdPercent * branchFlowLimit;
            
            obj.doNotUseBatteries()
            
            
            obj.queueDelayedCurtControlPercent = zeros(1, delayCurtailment);
            obj.futureStateCurt = 0;
            
            obj.numberOfGen = numberOfGen;
            obj.numberOfBatt = numberOfBatt;
            
        end
        
        function curtControlForAllGen = getCurtailmentControl(obj)
            curtControlForAllGen = obj.curtControlPercent * obj.maxGeneration;
        end
        
        function battControlForAllBatt = getBatteryInjectionControl(obj)
            battControlForAllBatt = obj.noBatteryInjectionControl * zeros(obj.numberOfBatt,1);
        end
        
        function objectControl = getControl(obj)
            curtControlForAllGen = obj.getCurtailmentControl();
            battControlForAllGen = obj.getBatteryInjectionControl();
            objectControl = ControlOfZone(curtControlForAllGen, battControlForAllGen);
        end
        
        function computeControl(obj)
            branchFlowState = obj.state.powerBranchFlow;
            if obj.isABranchOverHighFlowThreshold(branchFlowState) && obj.canCurtailmentIncrease()
                obj.increaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtControlPercentQueue();
            elseif obj.areAllBranchesUnderLowFlowThreshold(branchFlowState) && obj.canCurtailmentDecrease()
                obj.decreaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtControlPercentQueue();
            else
                obj.doNotAlterCurtailment();
                obj.updateDelayedCurtControlPercentQueue();
            end
        end
        
        function saveControl(obj, memory)
           memory.saveControl(obj.getCurtailmentControl(), obj.getBatteryInjectionControl()) 
        end
        
        function receiveStateAndDistTransit(obj, stateAndDistTransit)
            obj.state = stateAndDistTransit.getStateOfZone();
            obj.distTransit = stateAndDistTransit.getDisturbanceTransit();
        end
        
    end
    
    methods (Access = protected) 
        
        % the curtailment limiter does not use the batteries
        function doNotUseBatteries(obj)
            obj.noBatteryInjectionControl = 0;
        end
        
        function increaseCurtailment(obj)
            obj.curtControlPercent = obj.increaseCurtPercentEchelon;
        end
        
        function decreaseCurtailment(obj)
            obj.curtControlPercent = obj.decreaseCurtPercentEchelon;
        end
        
        function doNotAlterCurtailment(obj)
            obj.curtControlPercent = 0;
        end
                   
        
        function isOverThreshold = isABranchOverHighFlowThreshold(obj, branchFlowState)
           isOverThreshold = any( abs(branchFlowState) > obj.highFlowThreshold );
        end
        
        function areAllUnderThreshold = areAllBranchesUnderLowFlowThreshold(obj, branchFlowState)
            areAllUnderThreshold = all( abs(branchFlowState) < obj.lowFlowThreshold );
        end
        
        function canCurtIncrease = canCurtailmentIncrease(obj)
            canCurtIncrease = (obj.futureStateCurt + obj.increaseCurtPercentEchelon <= 1);
        end
        
        function canCurtDecrease = canCurtailmentDecrease(obj)
            canCurtDecrease = (obj.futureStateCurt + obj.decreaseCurtPercentEchelon >= 0);
        end
        
        function updateFutureCurtailment(obj)
            obj.futureStateCurt = obj.futureStateCurt + obj.curtControlPercent;
        end
        
        function updateDelayedCurtControlPercentQueue(obj)
            OldestControlDropped = obj.queueDelayedCurtControlPercent(2:end);
            newControlAdded = [OldestControlDropped obj.curtControlPercent];
            obj.queueDelayedCurtControlPercent = newControlAdded;
        end

    end
    
end