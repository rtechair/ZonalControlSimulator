classdef Limiter < handle
    
    properties (SetAccess = protected)
        DelayedCurtControlPercentQueue % DeltaPC decision taken but not applied yet due to delay
        FutureCurtState % PC after all delayed controls are applied
        
        CurtControlPercent % DeltaPC
        
        NoBatteryInjectionControl % DeltaPB
    end
    
    properties (SetAccess = immutable)
        BranchFlowLimit
        
        IncreaseCurtPercentEchelon
        DecreaseCurtPercentEchelon
        
        LowFlowThreshold
        HighFlowThreshold
        
        NumberOfGen
        NumberOfBatt
        
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                increaseCurtPercentEchelon, decreaseCurtPercentEchelon, coefLowerThreshold, coefUpperThreshold, ...
                curtailmentDelay)
                
            obj.BranchFlowLimit = branchFlowLimit;
            obj.IncreaseCurtPercentEchelon = increaseCurtPercentEchelon;
            obj.DecreaseCurtPercentEchelon = - decreaseCurtPercentEchelon;
            
            obj.LowFlowThreshold = coefLowerThreshold * branchFlowLimit;
            obj.HighFlowThreshold = coefUpperThreshold * branchFlowLimit;
            
            obj.doNotUseBatteries()
            
            
            obj.DelayedCurtControlPercentQueue = zeros(1, curtailmentDelay);
            obj.FutureCurtState = 0;
            
            obj.NumberOfGen = numberOfGen;
            obj.NumberOfBatt = numberOfBatt;
            
        end
        
        function curtControlForAllGen = getCurtailmentControl(obj)
            curtControlForAllGen = obj.CurtControlPercent * obj.BranchFlowLimit * ones(obj.NumberOfGen,1);
        end
        
        function BattControlForAllBatt = getBatteryInjectionControl(obj)
            BattControlForAllBatt = obj.NoBatteryInjectionControl * zeros(obj.NumberOfBatt,1);
        end
        
        function computeControls(obj, branchFlowState)
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
            canCurtIncrease = (obj.FutureCurtState + obj.IncreaseCurtPercentEchelon <= 1);
        end
        
        function canCurtDecrease = canCurtailmentDecrease(obj)
            canCurtDecrease = (obj.FutureCurtState + obj.DecreaseCurtPercentEchelon >= 0);
        end
        
        function updateFutureCurtailment(obj)
            obj.FutureCurtState = obj.FutureCurtState + obj.CurtControlPercent;
        end
        
        function updateDelayedCurtControlPercentQueue(obj)
            OldestControlDropped = obj.DelayedCurtControlPercentQueue(2:end);
            newControlAdded = [OldestControlDropped obj.CurtControlPercent];
            obj.DelayedCurtControlPercentQueue = newControlAdded;
        end

    end
    
end