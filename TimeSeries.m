classdef TimeSeries < handle
   
    properties (SetAccess = protected)
        chargingRate
        offsetChargingRate
        ProfilePowerAvailable
        ProfileDisturbancePowerAvailable
        step
    end
    
    properties (SetAccess = immutable)
        genStart
        numberOfIterations
        maxPowerGeneration
        numberOfGen
    end
    
    methods
        % TODO, adapt the build function too
        function obj = TimeSeries(chargingRateFilename, windowSimulation, ...
                durationSimulation, maxPowerGeneration, genStart)
            obj.genStart = genStart;
            obj.numberOfIterations = floor(durationSimulation / windowSimulation);
            obj.maxPowerGeneration = maxPowerGeneration;
            
            if size(maxPowerGeneration,1) ~= size(genStart,1)
                error('sizes of maxPowerGeneration and genStart are different')
            end
            obj.numberOfGen = size(maxPowerGeneration,1);
            
            % step starts at 0 because of initialization, later updated to 1 to start the simulation
            obj.step = 0; % TODO USELESS, it is a design flow in the simulation algorithm. TODO: later remove this part
            
            obj.setChargingRate(chargingRateFilename);
            
            obj.checkInitialIterationCorrectness(windowSimulation)
            
            obj.setProfilePowerAvailable(windowSimulation);
            obj.setProfileDisturbancePowerAvailable();
        end
        
        function value = getInitialPowerAvailable(obj)
            value = obj.ProfilePowerAvailable(:,1);
        end
        
        % TODO: when the telecommunication is removed, this method needs to
        % change
        function object = getDisturbancePowerAvailable(obj)
            % The telecommunication needs an object, not a matrix of the
            % value. Thus, the method returns an object wrapping the value
            % of the disturbance power available
            value = obj.getDisturbancePowerAvailableValue();
            object = DisturbancePowerAvailable(value);
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
        
        function setOffsetChargingRate(obj)
            obj.offsetChargingRate = NaN(obj.numberOfGen, obj.numberOfIterations+1);
            for i = 1:obj.numberOfGen
               start = obj.genStart(i);
               last = start + obj.numberOfIterations*windowSimulation;
               range = start : windowSimulation : last;
               obj.offsetChargingRate(i,:) = obj.chargingRate(1, range);
           end
        end
        
       function setProfilePowerAvailable(obj)
           obj.ProfilePowerAvailable = obj.maxPowerGeneration .* obj.offsetChargingRate;
       end
       
       function setProfileDisturbancePowerAvailable(obj)
           obj.ProfileDisturbancePowerAvailable = NaN(obj.numberOfGen, obj.numberOfIterations);
           for time = 1:obj.numberOfIterations
               obj.ProfileDisturbancePowerAvailable(:,time) = obj.ProfilePowerAvailable(:, time+1) ...
                   - obj.ProfilePowerAvailable(:, time);
           end
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
       
       % TODO: the name should be changed
       function value = getDisturbancePowerAvailableValue(obj)
           value = obj.ProfileDisturbancePowerAvailable(:,obj.step);
       end
       
    end
    
end