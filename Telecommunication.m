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
            obj.storAtEndOfCurtBuffer(modifiedCurtControl);
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
            obj.BufferTimeSeriesDisturbance = [obj.BufferTimeSeriesDisturbance(:,2:end) 0];
        end
        
        %% Curtailment Control
         %% TODO notice the similarities of methods, inheritance could reduce the amount of code  
         function curtControl = getCurtailmentControlFromLimiter(obj)
            curtControl = obj.Limiter.getCurtailmentControl();
         end
         
         function storAtEndOfCurtBuffer(obj, columnVector)
             obj.BufferCurtailmentControl(:,end) = columnVector;
         end
         
         function columnVector = getDelayedCurtControl(obj)
             columnVector = obj.BufferCurtailmentControl(:,end - obj.DelayTelecom);
         end
         
         function updateCurtBuffer(obj)
             obj.BufferCurtailmentControl = [obj.BufferCurtailmentControl(:, 2:end) 0];
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
            obj.BufferBattControl = [ obj.BufferBattControl(:, 2:end) 0];
        end
       
        
        
        
    end
    
    
end