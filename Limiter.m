classdef Limiter < handle
    
    properties
        DelayedCurtailmentControls % DeltaPC decision taken but not applied yet due to delay
        FutureCurtailmentState % PC after all delayed controls are applied
        
        CurtailmentControl % DeltaPC
        
        
    end
    
    properties (SetAccess = immutable)
        IncreaseCurtEchelon
        DecreaseCurtEchelon
        
        LowFlowThreshold
        HighFlowThreshold
        NoBatteryInjectionControl % DeltaPB
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                coefIncreaseCurt, coefDecreaseCurt, coefLowerThreshold, coefUpperThreshold, ...
                curtailmentDelay)
                
            obj.IncreaseCurtEchelon = coefIncreaseCurt * branchFlowLimit * ones(numberOfGen,1);
            obj.DecreaseCurtEchelon = - coefDecreaseCurt * branchFlowLimit * ones(numberOfGen,1);
            
            obj.LowFlowThreshold = coefLowerThreshold * branchFlowLimit;
            obj.HighFlowThreshold = coefUpperThreshold * branchFlowLimit;
            
            % the curtailment limiter does not use the batteries
            obj.NoBatteryInjectionControl = zeros(numberOfBatt,1);
            
            
            obj.DelayedCurtailmentControls = zeros(numberOfGen, curtailmentDelay);
            obj.FutureCurtailmentState = 0;
            
        end
        
        function doNotUseBatteries(obj,numberOfBatt)
            obj.NoBatteryInjectionControl = zeros(numberOfBatt,1);
        end
        
        
        function increaseCurtailement(obj)
            obj.CurtailmentControl = obj.IncreaseCurtEchelon;
        end
        
        function decreaseCurtailement(obj)
            obj.CurtailmentControl = obj.DecreaseCurtEchelon;
        end
        
        function doNotAlterCurtailment(obj)
            obj.CurtailmentControl = 0;
        end
        
        
        function computeControls(obj, branchFlowState)
            if obj.isABranchOverHighFlowThreshold(branchFlowState) && obj.canCurtailmentIncrease()
                obj.increaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtailmentControls();
            elseif obj.areAllBranchesUnderLowFlowThreshold(branchFlowState) && obj.canCurtailmentDecrease()
                obj.decreaseCurtailement();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtailmentControls();
            else
                obj.doNotAlterCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtailmentControls();
            end
        end
            
        
        function isOverThreshold = isABranchOverHighFlowThreshold(obj, branchFlowState)
           isOverThreshold = any( abs(branchFlowState) > obj.HighFlowThreshold );
        end
        
        function areAllUnderThreshold = areAllBranchesUnderLowFlowThreshold(obj, branchFlowState)
            areAllUnderThreshold = all( abs(branchFlowState) < obj.LowFLowThreshold );
        end
        
        function canCurtIncrease = canCurtailmentIncrease(obj)
            canCurtIncrease = obj.FutureCurtailmentState + obj.IncreaseCurtEchelon <= 1;
        end
        
        function canCurtDecrease = canCurtailmentDecrease(obj)
            canCurtDecrease = obj.FutureCurtailmentState + obj.DecreaseCurtEchelon >= 0;
        end
        
        function updateFutureCurtailment(obj)
            obj.FutureCurtailmentState = obj.FutureCurtailmentState + obj.CurtailmentControl;
        end
        
        function updateDelayedCurtailmentControls(obj)
            OldestControlDropped = obj.DelayedCurtailmentControls(:,2:end);
            newControlAdded = [OldestControlDropped obj.CurtailmentControl];
            obj.DelayedCurtailmentControls = newControlAdded;
        end
        
    end
    
    
end