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

function object = buildZoneEvolution(zoneSetting, zoneTopology, delayInIterations)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        delayInIterations DelayInIterations
    end
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();

    delayCurt = delayInIterations.getDelayCurt();
    delayBatt = delayInIterations.getDelayBatt();

    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();
    batteryConstantPowerReduction = zoneSetting.getBatteryConstantPowerReduction();
    object = ZoneEvolution(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn,...
                delayCurt, delayBatt, maxPowerGeneration, batteryConstantPowerReduction);
end