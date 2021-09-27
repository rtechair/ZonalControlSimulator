classdef TimeSeries < handle
   
    properties (SetAccess = protected)
        chargingRate
        offsetChargingRate
        profilePowerAvailable
        profileDisturbancePowerAvailable
        step
    end
    
    properties (SetAccess = immutable)
        genStart
        numberOfIterations
        maxPowerGeneration
    end
    
    methods
        % TODO, adapt the build function too
        function obj = TimeSeries(chargingRateFilename, windowSimulation, ...
                durationSimulation, maxPowerGeneration, genStart)
            arguments
                chargingRateFilename char
                windowSimulation (1,1) int64
                durationSimulation (1,1) int64
                maxPowerGeneration (:,1) double
                genStart (:,1) int64
            end
            if size(maxPowerGeneration,1) ~= size(genStart,1)
                error('sizes of maxPowerGeneration and genStart are different')
            end
            
            obj.genStart = genStart;
            obj.numberOfIterations = floor(durationSimulation / windowSimulation);
            obj.maxPowerGeneration = maxPowerGeneration;
            
            obj.step = 1; % TODO, adapt the code in the other classes as the time series starts now at time 1
            
            obj.setChargingRate(chargingRateFilename);
            
            obj.checkInitialIterationCorrectness(windowSimulation);
            
            obj.setOffsetChargingRate(windowSimulation);
            
            obj.setProfilePowerAvailable();
            obj.setProfileDisturbancePowerAvailable();
        end
        
        function value = getInitialPowerAvailable(obj)
            value = obj.profilePowerAvailable(:,1);
        end
        
        function value = getDisturbancePowerAvailable(obj)
            value = obj.profileDisturbancePowerAvailable(:,obj.step);
        end
        
       function goToNextStep(obj)
            obj.step = obj.step + 1;
       end
    end
    
    methods (Access = protected)
       
        function setChargingRate(obj, filenameChargingRate)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           obj.chargingRate = table2array(readtable(filenameChargingRate))';
        end
        
        function setOffsetChargingRate(obj, windowSimulation)
            numberOfGen = size(obj.maxPowerGeneration,1);
            obj.offsetChargingRate = NaN(numberOfGen, obj.numberOfIterations+1);
            for i = 1:numberOfGen
               start = obj.genStart(i);
               last = start + obj.numberOfIterations*windowSimulation;
               range = start : windowSimulation : last;
               obj.offsetChargingRate(i,:) = obj.chargingRate(1, range);
           end
        end
        
       function setProfilePowerAvailable(obj)
           obj.profilePowerAvailable = obj.maxPowerGeneration .* obj.offsetChargingRate;
       end
       
       function setProfileDisturbancePowerAvailable(obj)
           obj.profileDisturbancePowerAvailable = ...
               obj.profilePowerAvailable(:,2:end) - obj.profilePowerAvailable(:,1:end-1);
       end
       
       function checkInitialIterationCorrectness(obj, windowSimulation)
           sampleDuration = size(obj.chargingRate,2);
           % the following '-1' is due to the initialization step
           maxStartingTimeForGen = sampleDuration - 1 - windowSimulation*obj.numberOfIterations;
           isThereAnyStartOfGenTooLate = any(obj.genStart > maxStartingTimeForGen);
           if isThereAnyStartOfGenTooLate
                obj.errorStartingIterationExceedsMax(maxStartingTimeForGen)
           end
       end
       
       function errorStartingIterationExceedsMax(obj, upperBound)
           message = ['the starting iterations chosen for time series of the generators exceeds ' ...
            'the max discrete range, check in the JSON file, that the selected starts for generators are < ' ...
            num2str(upperBound) ', in the load data zone script'];
        error(message)
       end
       
       
       
    end
    
end