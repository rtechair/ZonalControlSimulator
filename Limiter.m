classdef Limiter < handle
    
    properties (SetAccess = protected)
        DelayedCurtControlsQueue % DeltaPC decision taken but not applied yet due to delay
        FutureCurtState % PC after all delayed controls are applied
        
        CurtControl % DeltaPC
        
        NoBatteryInjectionControl % DeltaPB
    end
    
    properties (SetAccess = immutable)
        IncreaseCurtEchelon
        DecreaseCurtEchelon
        
        LowFlowThreshold
        HighFlowThreshold
        
        NumberOfGen
        NumberOfBatt
        
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                coefIncreaseCurt, coefDecreaseCurt, coefLowerThreshold, coefUpperThreshold, ...
                curtailmentDelay)
                
            obj.IncreaseCurtEchelon = coefIncreaseCurt;
            obj.DecreaseCurtEchelon = - coefDecreaseCurt;
            
            obj.LowFlowThreshold = coefLowerThreshold * branchFlowLimit;
            obj.HighFlowThreshold = coefUpperThreshold * branchFlowLimit;
            
            obj.doNotUseBatteries()
            
            
            obj.DelayedCurtControlsQueue = zeros(1, curtailmentDelay);
            obj.FutureCurtState = 0;
            
            obj.NumberOfGen = numberOfGen;
            obj.NumberOfBatt = numberOfBatt;
            
        end
        
        function curtControlForAllGen = getCurtailmentControl(obj)
            curtControlForAllGen = obj.CurtControl * ones(obj.NumberOfGen,1);
        end
        
        function BattControlForAllBatt = getBatteryInjectionControl(obj)
            BattControlForAllBatt = obj.NoBatteryInjectionControl * zeros(obj.NumberOfBatt,1);
        end
        
        function computeControls(obj, branchFlowState)
            if obj.isABranchOverHighFlowThreshold(branchFlowState) && obj.canCurtailmentIncrease()
                obj.increaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtControlsQueue();
            elseif obj.areAllBranchesUnderLowFlowThreshold(branchFlowState) && obj.canCurtailmentDecrease()
                obj.decreaseCurtailment();
                obj.updateFutureCurtailment();
                obj.updateDelayedCurtControlsQueue();
            else
                obj.doNotAlterCurtailment();
                obj.updateDelayedCurtControlsQueue();
            end
        end
        
    end
    
    methods (Access = protected) 
        
        % the curtailment limiter does not use the batteries
        function doNotUseBatteries(obj)
            obj.NoBatteryInjectionControl = 0;
        end
        
        function increaseCurtailment(obj)
            obj.CurtControl = obj.IncreaseCurtEchelon;
        end
        
        function decreaseCurtailment(obj)
            obj.CurtControl = obj.DecreaseCurtEchelon;
        end
        
        function doNotAlterCurtailment(obj)
            obj.CurtControl = 0;
        end
                   
        
        function isOverThreshold = isABranchOverHighFlowThreshold(obj, branchFlowState)
           isOverThreshold = any( abs(branchFlowState) > obj.HighFlowThreshold );
        end
        
        function areAllUnderThreshold = areAllBranchesUnderLowFlowThreshold(obj, branchFlowState)
            areAllUnderThreshold = all( abs(branchFlowState) < obj.LowFlowThreshold );
        end
        
        function canCurtIncrease = canCurtailmentIncrease(obj)
            canCurtIncrease = (obj.FutureCurtState + obj.IncreaseCurtEchelon <= 1);
        end
        
        function canCurtDecrease = canCurtailmentDecrease(obj)
            canCurtDecrease = (obj.FutureCurtState + obj.DecreaseCurtEchelon >= 0);
        end
        
        function updateFutureCurtailment(obj)
            obj.FutureCurtState = obj.FutureCurtState + obj.CurtControl;
        end
        
        function updateDelayedCurtControlsQueue(obj)
            OldestControlDropped = obj.DelayedCurtControlsQueue(2:end);
            newControlAdded = [OldestControlDropped obj.CurtControl];
            obj.DelayedCurtControlsQueue = newControlAdded;
        end

    end
    
end