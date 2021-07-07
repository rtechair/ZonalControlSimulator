classdef Limiter < Controller
   
    properties (SetAccess = protected)
       QueueDelayedCurtControlPercent
       FutureStateCurt
       CurtControlPercent
       NoBatteryInjectionControl
       
       State
       DistTransit
    end
    
    
    properties (SetAccess = immutable)
        BranchFlowLimit
        
        IncreaseCurtPercentEchelon
        DecreaseCurtPercentEchelon
        
        LowFlowThreshold
        HighFlowThreshold
        
        NumberOfGen
        NumberOfBatt
        MaxGeneration
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                increaseCurtPercentEchelon, decreaseCurtPercentEchelon, lowerThresholdPercent, upperThresholdPercent, ...
                delayCurtailment, maxGeneration)
            
            obj.MaxGeneration = maxGeneration;
            obj.BranchFlowLimit = branchFlowLimit;
            
            
            obj.IncreaseCurtPercentEchelon = increaseCurtPercentEchelon;
            obj.DecreaseCurtPercentEchelon = - decreaseCurtPercentEchelon;
            
            obj.LowFlowThreshold = lowerThresholdPercent * branchFlowLimit;
            obj.HighFlowThreshold = upperThresholdPercent * branchFlowLimit;
            
            obj.doNotUseBatteries()
            
            
            obj.QueueDelayedCurtControlPercent = zeros(1, delayCurtailment);
            obj.FutureStateCurt = 0;
            
            obj.NumberOfGen = numberOfGen;
            obj.NumberOfBatt = numberOfBatt;
            
        end
        
        function curtControlForAllGen = getCurtailmentControl(obj)
            curtControlForAllGen = obj.CurtControlPercent * obj.MaxGeneration;
        end
        
        function battControlForAllBatt = getBatteryInjectionControl(obj)
            battControlForAllBatt = obj.NoBatteryInjectionControl * zeros(obj.NumberOfBatt,1);
        end
        
        function objectControl = getControl(obj)
            curtControlForAllGen = obj.getCurtailmentControl();
            battControlForAllGen = obj.getBatteryInjectionControl();
            objectControl = ControlOfZone(obj.NumberOfGen, obj.NumberOfBatt);
            objectControl.setControlCurtailment(curtControlForAllGen);
            objectControl.setControlBattery(battControlForAllGen);
        end
        
        function computeControl(obj)
            branchFlowState = obj.State.PowerBranchFlow;
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
        
        function receiveStateAndDistTransit(obj, stateAndDistTransit)
            obj.State = stateAndDistTransit.getStateOfZone();
            obj.DistTransit = stateAndDistTransit.getDisturbanceTransit();
        end
        
    end
    
    methods (Access = protected) 
        
        % the curtailment limiter does not use the batteries
        function doNotUseBatteries(obj)
            obj.NoBatteryInjectionControl = 0;
        end
        
        function increaseCurtailment(obj)
            obj.CurtControlPercent = obj.IncreaseCurtPercentEchelon;
        end
        
        function decreaseCurtailment(obj)
            obj.CurtControlPercent = obj.DecreaseCurtPercentEchelon;
        end
        
        function doNotAlterCurtailment(obj)
            obj.CurtControlPercent = 0;
        end
                   
        
        function isOverThreshold = isABranchOverHighFlowThreshold(obj, branchFlowState)
           isOverThreshold = any( abs(branchFlowState) > obj.HighFlowThreshold );
        end
        
        function areAllUnderThreshold = areAllBranchesUnderLowFlowThreshold(obj, branchFlowState)
            areAllUnderThreshold = all( abs(branchFlowState) < obj.LowFlowThreshold );
        end
        
        function canCurtIncrease = canCurtailmentIncrease(obj)
            canCurtIncrease = (obj.FutureStateCurt + obj.IncreaseCurtPercentEchelon <= 1);
        end
        
        function canCurtDecrease = canCurtailmentDecrease(obj)
            canCurtDecrease = (obj.FutureStateCurt + obj.DecreaseCurtPercentEchelon >= 0);
        end
        
        function updateFutureCurtailment(obj)
            obj.FutureStateCurt = obj.FutureStateCurt + obj.CurtControlPercent;
        end
        
        function updateDelayedCurtControlPercentQueue(obj)
            OldestControlDropped = obj.QueueDelayedCurtControlPercent(2:end);
            newControlAdded = [OldestControlDropped obj.CurtControlPercent];
            obj.QueueDelayedCurtControlPercent = newControlAdded;
        end

    end
    
end