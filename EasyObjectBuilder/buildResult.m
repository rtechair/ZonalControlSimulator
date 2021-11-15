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

function object = buildResult(zoneSetting, zoneTopology, delayInIterations, duration, name)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        delayInIterations DelayInIterations
        duration double
        name {mustBeText(name)}
    end
    controlCycle = zoneSetting.getControlCycleInSeconds();
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();
    branchFlowLimit = zoneSetting.getBranchFlowLimit();

    busId = zoneTopology.getBusId();
    branchIdx = zoneTopology.getBranchIdx();
    genOnIdx = zoneTopology.getGenOnIdx();
    battOnIdx = zoneTopology.getBattOnIdx();

    delayCurt = delayInIterations.getDelayCurt();
    delayBatt = delayInIterations.getDelayBatt();
    delayTimeSeries2Zone = delayInIterations.getDelayTimeSeries2Zone();
    delayController2Zone = delayInIterations.getDelayController2Zone();
    delayZone2Controller = delayInIterations.getDelayZone2Controller();

    object = ResultGraphic(name, duration, controlCycle,...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, ...
                maxPowerGeneration, branchFlowLimit, ...
                busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller);
end