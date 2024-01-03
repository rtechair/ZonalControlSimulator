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
classdef MPCLeastSquaresEstimPtdf < Controller

    properties (SetAccess = private)
        controller

        PF
        PG
        PB

        deltaPF
        deltaPG
        deltaPB

        nGen
        nBatt
        nLine
        nBus
        window
        ptdfGen
        ptdfBatt
        ptdf_G_matpower
        ptdf_Batt_matpower

        nameMethod
        currentStep
    end

    methods
        function obj = MPCLeastSquaresEstimPtdf(curtailmentDelay, batteryDelay, horizonInIterations, ...
                numberOfBuses, numberOfFrontierBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                PTDFBus, PTDFFrontierBus, PTDFGen, PTDFBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, minPowerFlow, maxPowerFlow, ...
                batteryCoef, timestepInSeconds, solverName, pastHorizonInSteps, nameMethod)

            obj.controller = ExactMPC(curtailmentDelay, batteryDelay, horizonInIterations, ...
                numberOfBuses, numberOfFrontierBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                PTDFBus, PTDFFrontierBus, PTDFGen, PTDFBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, minPowerFlow, maxPowerFlow, ...
                batteryCoef, timestepInSeconds, solverName);

            obj.nBus = numberOfBuses;
            obj.nGen = numberOfGen;
            obj.nBatt = numberOfBatt;
            obj.nLine = numberOfBranches;
            obj.window = pastHorizonInSteps;

            obj.ptdf_G_matpower = PTDFGen;
            obj.ptdf_Batt_matpower = PTDFBatt;
            
            totalNumberOfSteps = 240;
            obj.ptdfGen = NaN(obj.nLine, obj.nGen, totalNumberOfSteps);
            obj.ptdfBatt = NaN(obj.nLine, obj.nBatt, totalNumberOfSteps);

            obj.nameMethod = nameMethod;
            obj.currentStep = 0;
        end

        function computeControl(obj)
            obj.estimatePtdf();
            currentPtdfGen = obj.ptdfGen(:,:, obj.currentStep);
            obj.controller.setPtdfGen( currentPtdfGen );
            currentPtdfBatt = obj.ptdfBatt(:,:, obj.currentStep);
            obj.controller.setPtdfBatt( currentPtdfBatt );
            obj.controller.computeControl();
        end

        function object = getControl(obj)
            object = obj.controller.getControl();
        end

        function receiveState(obj, stateOfZone)
            obj.currentStep = obj.currentStep + 1;
            obj.controller.receiveState(stateOfZone);
            obj.PB(:, obj.currentStep) = stateOfZone.getPowerBattery();
            obj.PG(:, obj.currentStep) = stateOfZone.getPowerGeneration();
            obj.PF(:, obj.currentStep) = stateOfZone.getPowerFlow();
            
            % 2023-10-26: the initial state is currently not provided to
            % the estimator, thus an adaptation is needed without initialization
            if obj.currentStep >= 2
                obj.deltaPB(:, obj.currentStep-1) = obj.PB(:, obj.currentStep) - obj.PB(:, obj.currentStep-1);
                obj.deltaPG(:, obj.currentStep-1) = obj.PG(:, obj.currentStep) - obj.PG(:, obj.currentStep-1);
                obj.deltaPF(:, obj.currentStep-1) = obj.PF(:, obj.currentStep) - obj.PF(:, obj.currentStep-1);
            end
        end

        function receiveDisturbancePowerTransit(obj, disturbancePowerTransit)
            obj.controller.receiveDisturbancePowerTransit(disturbancePowerTransit);
        end

        function receiveDisturbancePowerAvailable(obj, disturbancePowerAvailable)
            obj.controller.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
        end

        function saveControl(obj, memory)
            obj.controller.saveControl(memory);
        end

        %%

        function estimPtdfLeastSquaresRegularizedWithTopology(obj)
             t_ini = max(1, obj.currentStep - obj.window);
            deltaPF_used = obj.deltaPF(:, t_ini : (obj.currentStep-1) );
            deltaPG_used = obj.deltaPG(:, t_ini: (obj.currentStep-1) );
            deltaPB_used = obj.deltaPB(:, t_ini: (obj.currentStep-1) );
            coef = 10^(-1);
            [variationPtdf_G, variationPtdf_Batt] = leastSquares_SumPtdf_DefaultValue(deltaPF_used, deltaPG_used, deltaPB_used, ...
            obj.ptdf_G_matpower, obj.ptdf_Batt_matpower, coef);
            
            newPtdfGen = variationPtdf_G + obj.ptdf_G_matpower;
            obj.ptdfGen(:,:, obj.currentStep) = newPtdfGen;

            newPtdfBatt = variationPtdf_Batt + obj.ptdf_Batt_matpower;
            obj.ptdfBatt(:,:, obj.currentStep) = newPtdfBatt;
        end

        function estimPtdfLeastSquaresWithTopology(obj)
            t_ini = max(1, obj.currentStep - obj.window);
            deltaPF_used = obj.deltaPF(:, t_ini : (obj.currentStep-1) );
            deltaPG_used = obj.deltaPG(:, t_ini: (obj.currentStep-1) );
            deltaPB_used = obj.deltaPB(:, t_ini: (obj.currentStep-1) );
            [newPtdfGen, newPtdfBatt] = leastSquares_ConstraintSumPtdf(deltaPF_used, deltaPG_used, deltaPB_used);
            obj.ptdfGen(:,:, obj.currentStep) = newPtdfGen;
            obj.ptdfBatt(:,:, obj.currentStep) = newPtdfBatt;
        end

        function estimPtdfLeastSquaresNoTopology(obj)
            t_ini = max(1, obj.currentStep - obj.window);
            deltaPF_used = obj.deltaPF(:, t_ini : (obj.currentStep-1) );
            deltaPG_used = obj.deltaPG(:, t_ini: (obj.currentStep-1) );
            deltaPB_used = obj.deltaPB(:, t_ini: (obj.currentStep-1) );
            [newPtdfGen, newPtdfBatt] = leastSquaresNoTransitDisturb(deltaPF_used, deltaPG_used, deltaPB_used);
            obj.ptdfGen(:,:, obj.currentStep) = newPtdfGen;
            obj.ptdfBatt(:,:, obj.currentStep) = newPtdfBatt;
        end

        function estimatePtdf(obj)
            if obj.currentStep <= 2
                obj.estimPtdfMatpower;
            else
                switch obj.nameMethod
                    case "LeastSquaresRegularizedWithTopology"
                        obj.estimPtdfLeastSquaresRegularizedWithTopology();
                    case "matpower"
                        obj.estimPtdfMatpower();
                    case "LeastSquaresWithTopology"
                        obj.estimPtdfLeastSquaresWithTopology();
                    case "LeastSquaresNoTopology"
                        obj.estimPtdfLeastSquaresNoTopology();
                    otherwise
                        disp('nameMethod does not have a valid value, give a valid name to pick an estimation method')
                end
            end
        end

        function estimPtdfMatpower(obj)
                obj.ptdfGen(:, :, obj.currentStep) = obj.ptdf_G_matpower;
                obj.ptdfBatt(:,:, obj.currentStep) = obj.ptdf_Batt_matpower;
        end

    end

end