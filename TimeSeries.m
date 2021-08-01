classdef TimeSeries < handle
   
    properties (SetAccess = protected)
        PowerAvailableState
        PowerAvailableVariation
        CurrentStep
        DiscretizedWindChargingRate
    end
    
    properties (SetAccess = immutable)
        StartGenIteration
        NumberOfIterations
        maxPowerGeneration
        NumberOfGen
    end
    
    methods
        
        function obj = TimeSeries(filenameWindChargingRate, ...
                startGenInSeconds, controlCycle, ...
                durationSimulation, maxGenerationPerGen, numberOfGen)
            obj.StartGenIteration = floor(startGenInSeconds / controlCycle);
            obj.NumberOfIterations = floor(durationSimulation / controlCycle);
            obj.maxPowerGeneration = maxGenerationPerGen;
            obj.NumberOfGen = numberOfGen;
            
            obj.CurrentStep = 1;

            obj.setDiscretizedWindChargingRate(filenameWindChargingRate, controlCycle);
            
            obj.checkInitialIterationCorrectness()
            
            obj.setPowerAvailableState();
            obj.setPowerAvailableVariation();
        end
        
        function disturbance = getDisturbancePowerAvailable(obj)
            disturbance = obj.PowerAvailableVariation(:,obj.CurrentStep);
        end
        
        function powerAvailable = getInitialPowerAvailable(obj)
            powerAvailable = obj.PowerAvailableState(:,1);
        end
        
        function objectDisturbance = getTimeSeries(obj)
            objectDisturbance = DisturbancePowerAvailable(obj.NumberOfGen);      
            value = obj.getDisturbancePowerAvailable();
            objectDisturbance.setDisturbancePowerAvailable(value);
        end
        
       function prepareForNextStep(obj)
            obj.CurrentStep = obj.CurrentStep + 1;
       end 
        
    end
    
    methods (Access = protected)
       
       function setDiscretizedWindChargingRate(obj, filenameWindChargingRate, controlCycle)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           rateInRealTime = table2array(readtable(filenameWindChargingRate))';
           numberOfSamples = size(rateInRealTime,2);
           discretTime = 1:  controlCycle : numberOfSamples;
           obj.DiscretizedWindChargingRate = rateInRealTime(discretTime);           
       end
        
       function setPowerAvailableState(obj)
           obj.PowerAvailableState = zeros(obj.NumberOfGen, obj.NumberOfIterations + 1);
           for gen = 1:obj.NumberOfGen
               start = obj.StartGenIteration(gen);
               range = start : start + obj.NumberOfIterations;
               windRate = obj.DiscretizedWindChargingRate(1,range);
               maxGen = obj.maxPowerGeneration(gen,1);
               obj.PowerAvailableState(gen,:) = maxGen * windRate;
           end
       end
       
       function setPowerAvailableVariation(obj)
           obj.PowerAvailableVariation = zeros(obj.NumberOfGen, obj.NumberOfIterations);
           for instant = 1:obj.NumberOfIterations
               obj.PowerAvailableVariation(:,instant) = obj.PowerAvailableState(:, instant+1) ...
                   - obj.PowerAvailableState(:, instant);
           end
       end
       
       function checkInitialIterationCorrectness(obj)
           numberOfSamples = size(obj.DiscretizedWindChargingRate,2);
          maxStartingIterationPossible = numberOfSamples - obj.NumberOfIterations;
          if any(obj.StartGenIteration > maxStartingIterationPossible)
              obj.errorStartingIterationExceedsMax(maxStartingIterationPossible)
          end
       end
       
       function errorStartingIterationExceedsMax(obj, upperBound)
           message = ['the starting iterations chosen for wind time series of the generators exceeds ' ...
            'the max discrete range, check that startingIterationOfWindForGen is < ' ...
            num2str(upperBound) ', in the load data zone script'];
        error(message)
       end        
       
    end
    
end