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
        branchFlowLimit
        
        increaseCurtPercentEchelon
        decreaseCurtPercentEchelon
        
        lowFlowThreshold
        highFlowThreshold
        
        numberOfGen
        numberOfBatt
        maxPowerGeneration
    end
        
    
    methods
        function obj = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                increaseCurtPercentEchelon, decreaseCurtPercentEchelon, lowerThresholdPercent, upperThresholdPercent, ...
                delayCurtailment, maxPowerGeneration)
            
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.branchFlowLimit = branchFlowLimit;
            
            
            obj.increaseCurtPercentEchelon = increaseCurtPercentEchelon;
            obj.decreaseCurtPercentEchelon = - decreaseCurtPercentEchelon;
            
            obj.lowFlowThreshold = lowerThresholdPercent * branchFlowLimit;
            obj.highFlowThreshold = upperThresholdPercent * branchFlowLimit;
            
            obj.doNotUseBatteries();
            
            
            obj.queueControlCurtPercent = zeros(1, delayCurtailment);
            obj.futureStateCurtPercent = 0;
            
            obj.numberOfGen = numberOfGen;
            obj.numberOfBatt = numberOfBatt;
            
        end
        
        function curtControlForAllGen = getCurtailmentControl(obj)
            curtControlForAllGen = obj.controlCurtPercent * obj.maxPowerGeneration;
        end
        
        function battControlForAllBatt = getBatteryInjectionControl(obj)
            battControlForAllBatt = obj.controlBatt * zeros(obj.numberOfBatt,1);
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
           memory.saveControl(obj.getCurtailmentControl(), obj.getBatteryInjectionControl()) 
        end
        
        function receiveStateAndDistTransit(obj, stateAndDistTransit)
            obj.state = stateAndDistTransit.getStateOfZone();
            obj.disturbancePowerTransit = stateAndDistTransit.getDisturbanceTransit();
        end
        
    end
    
    methods (Access = protected) 
        
        function doNotUseBatteries(obj)
            % the curtailment limiter does not use the batteries
            obj.controlBatt = 0;
        end
        
        function increaseCurtailment(obj)
            obj.controlCurtPercent = obj.increaseCurtPercentEchelon;
        end
        
        function decreaseCurtailment(obj)
            obj.controlCurtPercent = obj.decreaseCurtPercentEchelon;
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
            boolean = (obj.futureStateCurtPercent + obj.increaseCurtPercentEchelon) <= 1;
        end
        
        function boolean = canCurtailmentDecrease(obj)
            boolean = (obj.futureStateCurtPercent + obj.decreaseCurtPercentEchelon) >= 0;
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