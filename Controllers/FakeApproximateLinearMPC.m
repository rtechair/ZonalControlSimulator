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
classdef FakeApproximateLinearMPC < Controller
    
    properties (SetAccess = private)
        approxMPC
        MLDMPC
        countControls
        zoneName
    end

    methods
        function obj = FakeApproximateLinearMPC(basecaseFilename, busId, numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                batteryCoef, timestep, delayCurt, delayBatt, delayTelecom,...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit, horizonInIterations, name)

            obj.setApproximateLinearMPC(basecaseFilename, busId, numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                batteryCoef, timestep, delayCurt, delayBatt, delayTelecom, horizonInIterations,...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit);

            obj.setMixedLogicalDynamicalMPC(basecaseFilename, busId, numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                batteryCoef, timestep, delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit)

            obj.countControls = 0;
            obj.zoneName = name;
        end

        function setApproximateLinearMPC(obj, basecaseFilename, busId, numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                batteryCoef, timestep, delayCurt, delayBatt, delayTelecom, horizonInIterations,...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit)
            zonePTDFConstructor = ZonePTDFConstructor(basecaseFilename);
            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = ApproximateLinearModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, delayCurt, delayBatt);

            operatorStateExtended = model.getOperatorStateExtended;
            operatorControlExtended = model.getOperatorControlExtended;
            operatorDisturbancePowerGenerationExtended = model.getOperatorDisturbancePowerGenerationExtended;
            operatorDisturbancePowerTransitExtended= model.getOperatorDisturbancePowerTransitExtended;
            
            obj.approxMPC = ApproximateLinearMPC(delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorDisturbancePowerGenerationExtended, operatorDisturbancePowerTransitExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit);
        end

        function setMixedLogicalDynamicalMPC(obj, basecaseFilename, busId, numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                batteryCoef, timestep, delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit)
            zonePTDFConstructor = ZonePTDFConstructor(basecaseFilename);

            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, delayCurt, delayBatt);

            operatorStateExtended = model.getOperatorStateExtended();
            operatorControlExtended = model.getOperatorControlExtended();
            operatorNextPowerGenerationExtended = model.getOperatorNextPowerGenerationExtended();
            operatorDisturbanceExtended = model.getOperatorDisturbanceExtended();

            obj.MLDMPC = MixedLogicalDynamicalMPC(delayCurt, delayBatt, delayTelecom, horizonInIterations, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                maxPowerGeneration, minPowerBattery, maxPowerBattery, maxEnergyBattery, flowLimit);
        end

        function computeControl(obj)
            obj.countControls = obj.countControls + 1;
            % (obj.zoneName == "VTV") & (obj.countControls >= 26)
            obj.MLDMPC.computeControl();
            obj.approxMPC.computeControl();

            MIPcontrol = obj.MLDMPC.getControl();
            MIPcurtControl = MIPcontrol.getControlCurtailment();
            MIPbattControl = MIPcontrol.getControlBattery();
            obj.approxMPC.replaceLastPastCurtControl(MIPcurtControl);
            obj.approxMPC.replaceLastPastBattControl(MIPbattControl);
        end

        function object = getControl(obj)
            object = obj.MLDMPC.getControl();
        end

        function receiveState(obj, stateOfZone)
            obj.approxMPC.receiveState(stateOfZone);
            obj.MLDMPC.receiveState(stateOfZone);
        end

        function receiveDisturbancePowerTransit(obj, disturbancePowerTransit)
            obj.approxMPC.receiveDisturbancePowerTransit(disturbancePowerTransit);
            obj.MLDMPC.receiveDisturbancePowerTransit(disturbancePowerTransit);
        end

        function receiveDisturbancePowerAvailable(obj, disturbancePowerAvailable)
            obj.approxMPC.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
            obj.MLDMPC.receiveDisturbancePowerAvailable(disturbancePowerAvailable);
        end

        function saveControl(obj, memory)
            obj.approxMPC.saveControl(memory);
        end

    end

    methods (Access = protected)

    end
end