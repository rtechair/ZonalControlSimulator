classdef TimeSeriesRenewableEnergy < handle
   
    properties (SetAccess = protected)
        powerAvailableState
        powerAvailableVariation
        step
        discretizedWindChargingRate
    end
    
    properties (SetAccess = immutable)
        startGenIteration
        numberOfIterations
        maxPowerGeneration
        numberOfGen
    end
    
    methods
        
        function obj = TimeSeriesRenewableEnergy(filenameWindChargingRate, ...
                startGenInSeconds, controlCycle, ...
                durationSimulation, maxGenerationPerGen, numberOfGen)
            obj.startGenIteration = floor(startGenInSeconds / controlCycle);
            obj.numberOfIterations = floor(durationSimulation / controlCycle);
            obj.maxPowerGeneration = maxGenerationPerGen;
            obj.numberOfGen = numberOfGen;
            
            % step starts at 0 because of initialization, later updated to 1 to start the simulation
            obj.step = 0;

            obj.setDiscretizedWindChargingRate(filenameWindChargingRate, controlCycle);
            
            obj.checkInitialIterationCorrectness()
            
            obj.setPowerAvailableState();
            obj.setPowerAvailableVariation();
        end
        
        function disturbance = getDisturbancePowerAvailable(obj)
            disturbance = obj.powerAvailableVariation(:,obj.step);
        end
        
        function powerAvailable = getInitialPowerAvailable(obj)
            powerAvailable = obj.powerAvailableState(:,1);
        end
        
        % TODO: unclear name, plus a difficult behavior to grasp: get the value, then create an object encapsulating the value
        function objectDisturbance = getTimeSeries(obj)
            objectDisturbance = DisturbancePowerAvailable(obj.numberOfGen);      
            value = obj.getDisturbancePowerAvailable();
            objectDisturbance.setDisturbancePowerAvailable(value);
        end
        
       function prepareForNextStep(obj)
            obj.step = obj.step + 1;
       end 
        
    end
    
    methods (Access = protected)
       
       function setDiscretizedWindChargingRate(obj, filenameWindChargingRate, controlCycle)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           rateInRealTime = table2array(readtable(filenameWindChargingRate))';
           numberOfSamples = size(rateInRealTime,2);
           discretTime = 1:  controlCycle : numberOfSamples;
           obj.discretizedWindChargingRate = rateInRealTime(discretTime);           
       end
        
       function setPowerAvailableState(obj)
           obj.powerAvailableState = zeros(obj.numberOfGen, obj.numberOfIterations + 1);
           for gen = 1:obj.numberOfGen
               start = obj.startGenIteration(gen);
               range = start : start + obj.numberOfIterations;
               windRate = obj.discretizedWindChargingRate(1,range);
               maxGen = obj.maxPowerGeneration(gen,1);
               obj.powerAvailableState(gen,:) = maxGen * windRate;
           end
       end
       
       function setPowerAvailableVariation(obj)
           obj.powerAvailableVariation = zeros(obj.numberOfGen, obj.numberOfIterations);
           for instant = 1:obj.numberOfIterations
               obj.powerAvailableVariation(:,instant) = obj.powerAvailableState(:, instant+1) ...
                   - obj.powerAvailableState(:, instant);
           end
       end
       
       function checkInitialIterationCorrectness(obj)
           numberOfSamples = size(obj.discretizedWindChargingRate,2);
          maxStartingIterationPossible = numberOfSamples - obj.numberOfIterations;
          if any(obj.startGenIteration > maxStartingIterationPossible)
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