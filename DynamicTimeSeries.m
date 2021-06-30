classdef DynamicTimeSeries < handle
   
    properties (SetAccess = protected)
        PowerAvailableState
        PowerAvailableVariation
        CurrentStep
        DiscretizedWindChargingRate
    end
    
    properties (SetAccess = immutable)
        StartingIterationOfWindForGen
        Zone
        NumberOfIterations
        GenerationCapacity
        NumberOfGen
    end
    
    methods
        
        function obj = DynamicTimeSeries(filenameWindChargingRate, ...
                zone_startingIterationOfWindForGen, zone_samplingTime, ...
                zone_numberOfIterations, maxGenerationPerGen, zone_numberOfGen)
            obj.StartingIterationOfWindForGen = zone_startingIterationOfWindForGen;
            obj.NumberOfIterations = zone_numberOfIterations;
            obj.GenerationCapacity = maxGenerationPerGen;
            obj.NumberOfGen = zone_numberOfGen;
            
            obj.CurrentStep = 1;

            obj.setWindChargingRate(filenameWindChargingRate, zone_samplingTime);
            
            obj.checkInitialIterationCorrectness()
            
            obj.setPowerAvailableState();
            obj.setPowerAvailableVariation();
        end
        
        function currentVariation = getCurrentPowerAvailableVariation(obj)
            currentVariation = obj.PowerAvailableVariation(:,obj.CurrentStep);
        end
        
       function prepareForNextStep(obj)
            obj.CurrentStep = obj.CurrentStep + 1;
       end 
        
    end
    
    methods (Access = protected)
        

       
       function setWindChargingRate(obj, filenameWindChargingRate, zone_samplingTime)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           rateInRealTime = table2array(readtable(filenameWindChargingRate))';
           numberOfSamples = size(rateInRealTime,2);
           discretTime = 1:  zone_samplingTime : numberOfSamples;
           obj.DiscretizedWindChargingRate = rateInRealTime(discretTime);           
       end
        
       function setPowerAvailableState(obj)
           obj.PowerAvailableState = zeros(obj.NumberOfGen, obj.NumberOfIterations + 1);
           for gen = 1:obj.NumberOfGen
               start = obj.StartingIterationOfWindForGen(gen);
               range = start : start + obj.NumberOfIterations;
               windRate = obj.DiscretizedWindChargingRate(1,range);
               maxGen = obj.GenerationCapacity(gen,1);
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
          if any(obj.StartingIterationOfWindForGen > maxStartingIterationPossible)
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