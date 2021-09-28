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
        function obj = TimeSeries(chargingRateFilename, simulationWindow, ...
                simulationDuration, maxPowerGeneration, genStart)
            arguments
                chargingRateFilename char
                simulationWindow (1,1) int64
                simulationDuration (1,1) int64
                maxPowerGeneration (:,1) double
                genStart (:,1) int64
            end
            obj.mustBeEqualSizes(maxPowerGeneration, genStart);
            
            obj.genStart = genStart;
            obj.numberOfIterations = floor(simulationDuration / simulationWindow);
            obj.maxPowerGeneration = maxPowerGeneration;            
            obj.step = 1;
            
            obj.setChargingRate(chargingRateFilename);
            obj.mustGenStartNotExceedMax(simulationWindow);            
            obj.setOffsetChargingRate(simulationWindow);
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
       
        function setChargingRate(obj, chargingRateFilename)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           obj.chargingRate = table2array(readtable(chargingRateFilename))';
        end
        
        function setOffsetChargingRate(obj, simulationWindow)
            numberOfGen = size(obj.maxPowerGeneration,1);
            obj.offsetChargingRate = NaN(numberOfGen, obj.numberOfIterations+1);
            for i = 1:numberOfGen
               start = obj.genStart(i);
               last = start + obj.numberOfIterations*simulationWindow;
               range = start : simulationWindow : last;
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
       
       function mustGenStartNotExceedMax(obj, simulationWindow)
           [boolean, latestStart] = obj.isAnyStartOverMaxPossible(simulationWindow);
           if boolean
               message = ['the starting time of the generators are too late.'...
                ' Make sure it is <=' num2str(latestStart) ' in the associate JSON file.'];
                error(message)
           end
       end
       
       function [boolean, latestStart] = isAnyStartOverMaxPossible(obj, simulationWindow)
           % chargingRate and numberOfIterations need to be set prior to this method
           arguments
               obj
               simulationWindow {mustBePositive, mustBeInteger}
           end
           mustBeNonempty(obj.chargingRate)
           
           sampleDuration = size(obj.chargingRate,2);
           latestStart = sampleDuration - obj.numberOfIterations*simulationWindow;
           boolean = any(obj.genStart > latestStart);
       end
       
       function mustBeEqualSizes(obj, maxPowerGeneration, genStart)
           isSizeDifferent = size(maxPowerGeneration,1) ~= size(genStart,1);
           if isSizeDifferent
               error('sizes of maxPowerGeneration and genStart are different')
           end
       end
       
    end
    
end