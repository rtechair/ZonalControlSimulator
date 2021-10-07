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
        samplingTime
        numberOfIterations
        maxPowerGeneration
    end
    
    methods
        function obj = TimeSeries(chargingRateFilename, samplingTime, ...
                simulationDuration, maxPowerGeneration, genStart)
            arguments
                chargingRateFilename char
                samplingTime (1,1) int64
                simulationDuration (1,1) int64
                maxPowerGeneration (:,1) double
                genStart (:,1) int64
            end
            obj.mustBeEqualSizes(maxPowerGeneration, genStart);
            
            obj.genStart = genStart;
            obj.samplingTime = samplingTime;
            obj.numberOfIterations = floor(simulationDuration / samplingTime);
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.step = 1;
            
            obj.setChargingRate(chargingRateFilename);
            obj.mustGenStartNotExceedMax();
            obj.setOffsetChargingRate();
            obj.setProfilePowerAvailable();
            obj.setProfileDisturbancePowerAvailable();
        end
        
        function value = getInitialPowerAvailable(obj)
            value = obj.profilePowerAvailable(:,1);
        end
        
        function value = getPowerAvailable(obj)
            value = obj.profilePowerAvailable(:, obj.step);
        end
        
        function sendDisturbancePowerAvailable(obj, modelEvolution)
            arguments
                obj
                modelEvolution ModelEvolution
            end
            disturbancePowerAvailable = obj.getDisturbancePowerAvailable();
            modelEvolution.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
            obj.goToNextStep();
        end
        
        function value = getDisturbancePowerAvailable(obj)
            value = obj.profileDisturbancePowerAvailable(:,obj.step);
        end
        
       function goToNextStep(obj)
            obj.step = obj.step + 1;
       end
       
       function figPowerAvailable = plotProfilePowerAvailable(obj)
           % TODO: add optional argument with the index of each generator,
           % s.t. the plot displays what generator is concerned with each
           % plot
           simulationDuration = size(obj.profilePowerAvailable,2);
           time = 1:simulationDuration;

           figName = 'Power Available (PA) of all gens of a zone';
           figPowerAvailable = figure('Name', figName, 'NumberTitle', 'off', ...
               'WindowState', 'maximize');
           xlegend = 'duration of the simulation';
           xlabel(xlegend)
           ylegend = 'Power Available in [MW]';
           ylabel(ylegend);
           hold on;

           numberOfGen = size(obj.profilePowerAvailable,1);
           for k = 1:numberOfGen
               stairs(time, obj.profilePowerAvailable(k,:));
           end
       end
       
       function plotProfileDisturbancePowerAvailable(obj)
           time = 1:obj.numberOfIterations;
           figName = 'Profile of Disturbance Power Available (DeltaPA)';
           figure('Name',figName,'NumberTitle','off','WindowState','maximize');
           xlegend = 'number of iterations of the simulation';
           xlabel(xlegend)
           ylegend = '\DeltaPA';
           ylabel(ylegend);
           hold on;
           
           numberOfGen = size(obj.profileDisturbancePowerAvailable,1);
           for k = 1:numberOfGen
               stairs(time, obj.profileDisturbancePowerAvailable(k,:));
           end
       end
       
    end
    
    methods (Access = protected)
       
        function setChargingRate(obj, chargingRateFilename)
           % the apostrophe is to obtain a row vector, such that columns represent the time
           obj.chargingRate = table2array(readtable(chargingRateFilename))';
        end
        
        function setOffsetChargingRate(obj)
            numberOfGen = size(obj.maxPowerGeneration,1);
            obj.offsetChargingRate = NaN(numberOfGen, obj.numberOfIterations+1);
            for i = 1:numberOfGen
               start = obj.genStart(i);
               last = start + obj.numberOfIterations*obj.samplingTime;
               range = start : obj.samplingTime : last;
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
       
       function mustGenStartNotExceedMax(obj)
           [boolean, latestStart] = obj.isAnyStartOverMaxPossible();
           if boolean
               message = ['the starting time of the generators are too late.'...
                ' Make sure it is <=' num2str(latestStart) ' in the associate JSON file.'];
                error(message)
           end
       end
       
       function [boolean, latestStart] = isAnyStartOverMaxPossible(obj)
           mustBeNonempty(obj.samplingTime)
           mustBeNonempty(obj.chargingRate)
           
           sampleDuration = size(obj.chargingRate,2);
           latestStart = sampleDuration - obj.numberOfIterations*obj.samplingTime;
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