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
function object = buildTimeSeries(zoneSetting, zoneTopology,...
    samplingTime, simulationDuration)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        samplingTime double
        simulationDuration double
    end
    chargingRateFilename = zoneSetting.getTimeSeriesFilename();
    genStart = zoneSetting.getStartGenInSeconds();
    
    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();

    object = TimeSeries(chargingRateFilename, samplingTime, ...
                simulationDuration, maxPowerGeneration, genStart);
end