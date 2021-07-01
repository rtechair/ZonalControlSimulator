classdef Telecommunication < handle
   
    properties (SetAccess = immutable)
        NumberOfGen
        NumberOfBatt
        SamplingTime
        DelayTelecom
    end
    
    properties
        BufferTimeSeriesDisturbance
        BufferCurtailmentControl
        BufferBattControl
        
        DynamicTimeSeries
        Limiter
    end
    
    methods
       
        function obj = Telecommunication(delayCommunication, dynamicTimeSeries, limiter, ...
                numberOfGenerators, numberOfBatteries, samplingTime)
           obj.DelayTelecom = delayCommunication;
           
           obj.DynamicTimeSeries = dynamicTimeSeries;
           obj.Limiter = limiter;
           
           obj.NumberOfGen = numberOfGenerators;
           obj.NumberOfBatt = numberOfBatteries;
           obj.SamplingTime = samplingTime;
           
           obj.initializeBuffers()
        end
            
        function delayedAndModifiedDisturbance = getDisturbance(obj)
            disturbance = obj.getDisturbanceFromTimeSeries();
            modifiedDisturbance = modify(obj, disturbance);
            obj.storeAtEndOfDisturbanceBuffer(modifiedDisturbance);
            delayedAndModifiedDisturbance = obj.getDelayedDisturbance();
            
            obj.updateDisturbanceBuffer();
        end
        
        function delayedAndModifiedCurt = getCurtailmentControl(obj)
            curtControl = obj.getCurtailmentControlFromLimiter();
            modifiedCurtControl = modify(obj, curtControl);
            obj.storeAtEndOfCurtBuffer(modifiedCurtControl);
            delayedAndModifiedCurt =  obj.getDelayedCurtControl();
            obj.updateCurtBuffer();
        end
        
        function delayedAndModifiedBattControl = getBatteryInjectionControl(obj)
           battControl = obj.getBatteryControlFromLimiter();
           modifiedBattControl = modify(obj, battControl);
           obj.storeAtEndOfBattBuffer(modifiedBattControl);
           delayedAndModifiedBattControl = obj.getDelayedBattControl();
           obj.updateBattBuffer();
        end
        
        function orderLimiterToComputeControls(obj, branchFlowState)
            obj.Limiter.computeControls(branchFlowState);
        end
        
        function [disturbance, curtailmentControl, batteryControl] = getControlsAndDisturbance(obj, branchFlowState)
            obj.orderLimiterToComputeControls(branchFlowState);
            curtailmentControl = obj.getCurtailmentControl();
            batteryControl = obj.getBatteryInjectionControl();
            disturbance = obj.getDisturbance();
        end
    end
    
    methods (Access = protected)
        
        function initializeBuffers(obj)
            obj.BufferTimeSeriesDisturbance = zeros(obj.NumberOfGen, obj.DelayTelecom + 1);
            obj.BufferCurtailmentControl = zeros(obj.NumberOfGen,obj.DelayTelecom + 1);
            obj.BufferBattControl = zeros(obj.NumberOfBatt,obj.DelayTelecom + 1);
        end
        
         function newValue = modify(obj, oldValue)
            %TODO currently do nothing (it's intended)
            newValue = oldValue;
         end
        
        %% Time Series Disturbance
        
        function disturbance = getDisturbanceFromTimeSeries(obj)
            disturbance = obj.DynamicTimeSeries.getCurrentPowerAvailableVariation();
            obj.DynamicTimeSeries.prepareForNextStep();
        end
        
        
        function storeAtEndOfDisturbanceBuffer(obj, columnVector)
            obj.BufferTimeSeriesDisturbance(:,end) = columnVector;
        end
        
        function columnVector = getDelayedDisturbance(obj)
            columnVector = obj.BufferTimeSeriesDisturbance(:,end - obj.DelayTelecom);
        end
        
        function updateDisturbanceBuffer(obj)
            oldestDisturbanceDropped = obj.BufferTimeSeriesDisturbance(:,2:end);
            prepareForNextDisturbance = zeros(obj.NumberOfGen, 1);
            obj.BufferTimeSeriesDisturbance = [oldestDisturbanceDropped prepareForNextDisturbance];
        end
        
        %% Curtailment Control
         %% TODO notice the similarities of methods, inheritance could reduce the amount of code  
         function curtControl = getCurtailmentControlFromLimiter(obj)
            curtControl = obj.Limiter.getCurtailmentControl();
         end
         
         function storeAtEndOfCurtBuffer(obj, columnVector)
             obj.BufferCurtailmentControl(:,end) = columnVector;
         end
         
         function columnVector = getDelayedCurtControl(obj)
             columnVector = obj.BufferCurtailmentControl(:,end - obj.DelayTelecom);
         end
         
         function updateCurtBuffer(obj)
             oldestCurtControlDropped = obj.BufferCurtailmentControl(:, 2:end);
             prepareForNextCurtControl = zeros(obj.NumberOfGen,1);
             obj.BufferCurtailmentControl = [oldestCurtControlDropped prepareForNextCurtControl];
         end
                 
        
        %% Battery injection control
        %% TODO similarly, notice how close it is from the curtailment control part
        
        function battControl = getBatteryControlFromLimiter(obj)
            battControl = obj.Limiter.getBatteryInjectionControl();
        end
        
        function storeAtEndOfBattBuffer(obj, columnVector)
            obj.BufferBattControl(:, end) = columnVector;
        end
        
        function columnVector = getDelayedBattControl(obj)
            columnVector = obj.BufferBattControl(:, end - obj.DelayTelecom);
        end
        
        function updateBattBuffer(obj)
            oldestBattControlDropped = obj.BufferBattControl(:, 2:end);
            prepareForNextBattControl = zeros(obj.NumberOfBatt,1);
            obj.BufferBattControl = [ oldestBattControlDropped prepareForNextBattControl];
        end
       
        
        
        
    end
    
    
end