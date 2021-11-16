%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}
classdef ProbabilityDistribution < handle
    
    properties
        profilePowerAvailable
        numberOfScenarios
        numberOfGen
        predictionHorizon
        disturbanceAlternatives
        monotony
        numberOfAlternatives
        numberOfSimulationIterations
        
        pastPowerAvailable
        futurePowerAvailable
        normalizedPastGradient
        
        normalizedFutureGradient
        normFutureGradientPerGen
        offsetFutureGradientPerGen
        
        typeGradient
        
        gradientProba
        permutations
    end
    
    methods
        
        function obj = ProbabilityDistribution(...
                numberOfScenarios, numberOfGen, predictionHorizon, ...
                disturbanceAlternatives, monotony, numberOfSimulationIterations)
            obj.setProfilePowerAvailable();
            obj.numberOfScenarios = numberOfScenarios;
            obj.numberOfGen = numberOfGen;
            obj.predictionHorizon = predictionHorizon;
            obj.disturbanceAlternatives = disturbanceAlternatives;
            obj.monotony = monotony;
            obj.numberOfAlternatives = length(disturbanceAlternatives);
            obj.numberOfSimulationIterations = numberOfSimulationIterations;
        end
        
        function setProfilePowerAvailable(obj)
            % FIXME: currently, the data selected is hard-written
            data = readtable('Windenergie_Prognose_2020.csv','VariableNamingRule','preserve');
            data = str2double(data.bis);
            data(1:3) = [];
            obj.profilePowerAvailable = data;
        end
        
        function separateData(obj, ratio)
            threshold = floor(length(obj.profilePowerAvailable)*ratio);
            obj.pastPowerAvailable = obj.profilePowerAvailable(1:threshold);
            obj.futurePowerAvailable = obj.profilePowerAvailable(threshold+1 : end);
        end
        
        function setNormalizedPastGradient(obj)
            gradient = obj.pastPowerAvailable(2:end) - obj.pastPowerAvailable(1:end-1);
            obj.normalizedPastGradient = gradient / max(gradient);
        end
        
        function setNormalizedFutureGradient(obj)
            gradient = obj.futurePowerAvailable(2:end) - obj.futurePowerAvailable(1:end-1);
            obj.normalizedFutureGradient = gradient / max(gradient);
        end
        
        function setFutureGradientPerGen(obj)
            numberOfElements = length(obj.normalizedFutureGradient);
            remainder = rem(numberOfElements, obj.numberOfGen);
            lastColumnToKeep = numberOfElements - remainder;
            truncatedNormFutureGradient = obj.normalizedFutureGradient(1:lastColumnToKeep);
            obj.normFutureGradientPerGen = reshape(truncatedNormFutureGradient, obj.numberOfGen, []);
        end
        
        function setOffsetFutureGradientPerGen(obj, startPerGen)
            endPerGen = startPerGen + obj.numberOfSimulationIterations;
            for k = 1:obj.numberOfGen
                startOfGen = startPerGen(k);
                endOfGen = endPerGen(k);
                rangeOfGen = startOfGen : endOfGen;
                obj.offsetFutureGradientPerGen = obj.normFutureGradientPerGen(k, rangeOfGen);
            end
        end
        
        function countOccurencesByIntervalOfGradients(obj)
            % CAUTIOUS: here typeGradient is a square matrix, Nouha made a
            % vector instead
           obj.typeGradient = zeros(obj.numberOfAlternatives, obj.numberOfAlternatives);
           lowerBound = obj.monotony(1:end-1);
           upperBound = obj.monotony(2:end);
           for t = 1:length(obj.normalizedPastGradient) -1
               nextGradient = obj.normalizedPastGradient(t+1);
               currentGradient = obj.normalizedPastGradient(t);
               
               interval1 = find(lowerBound <= currentGradient && currentGradient < upperBound);
               interval2 = find(lowerBound <= nextGradient && nextGradient < upperBound);
               
               obj.typeGradient(interval1, interval2) = obj.typeGradient(interval1, interval2) + 1;
           end
        end
        
        % FIXME: there is another function to handle the null probabilities.
        % I don't understand why there is this problem
        
        function setGradientProba(obj)
            % By totale probability law:
            % proba(DeltaPA(k)) = sum(over c) { proba(DeltaPA(k)) intersects
            % proba(deltaPA_c(k+1)) }
            numberOfEventsPerGradient = sum(obj.typeGradient,2);
            totalNumberOfCases = length(obj.profilePowerAvailable) - 1;
            obj.gradientProba = numberOfEventsPerGradient / totalNumberOfCases;
        end
        
        function setPermutations(obj)
            obj.permutations = permn(obj.disturbanceAlternatives, numberOfGen);
        end
        
    end
    
end