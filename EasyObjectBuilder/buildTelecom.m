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

function [telecomTimeSeries2Zone, telecomController2Zone, telecomZone2Controller] = buildTelecom(...
    zoneTopology, delayInIterations)
    arguments
        zoneTopology ZoneTopology
        delayInIterations DelayInIterations
    end
    telecomTimeSeries2Zone = buildTelecomTimeSeries2Zone(zoneTopology, delayInIterations);
    telecomController2Zone = buildTelecomController2Zone(zoneTopology, delayInIterations);
    telecomZone2Controller = buildTelecomZone2Controller(zoneTopology, delayInIterations);
end

function object = buildTelecomTimeSeries2Zone(zoneTopology, delayInIterations)
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    delayTimeSeries2Zone = delayInIterations.getDelayTimeSeries2Zone();
    object = TelecomTimeSeries2Zone(numberOfGenOn, delayTimeSeries2Zone);
end

function object = buildTelecomController2Zone(zoneTopology, delayInIterations)
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    delayController2Zone = delayInIterations.getDelayController2Zone();
    object = TelecomController2Zone(...
                numberOfGenOn, numberOfBattOn, delayController2Zone);
end

function object = buildTelecomZone2Controller(zoneTopology, delayInIterations)
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    delayZone2Controller = delayInIterations.getDelayZone2Controller();
    object = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, delayZone2Controller);
end