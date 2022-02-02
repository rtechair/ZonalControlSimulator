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

function cellOfZoneStates = getInitialZoneState(simulationFilename)
% Returns a cell of the initial state of zones. The selection of zones is
% determined by the 'simulationFilename' given as input.
    initialTransmission = TransmissionSimulation(simulationFilename);
    numberOfZones = initialTransmission.getNumberOfZones();
    zones = initialTransmission.getZones();
    
    cellOfZoneStates = cell(numberOfZones,1);
    for z = 1:numberOfZones
        zone = zones{z};
        zoneSimulationEvolution = zone.getSimulationEvolution();
        state = zoneSimulationEvolution.getState();
        cellOfZoneStates{z} = state;
    end
end