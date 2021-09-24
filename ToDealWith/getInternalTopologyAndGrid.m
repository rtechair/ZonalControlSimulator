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

function [internalTopology, internalGrid] = getInternalTopologyAndGrid(basecaseFilename, zoneName)
% Create the topology of a zone but with ID and IDX matching those of the internal matpowercase.
% the matpowercase of the internalGrid is the internal matpowercase.
% Goal: access easily the information of the zone of the internal matpowercase.
% A usecase is to check the matrices of the mathematical model.


    grid = ElectricalGrid(basecaseFilename);
    zoneFilename = ['zone' zoneName '.json'];
    zoneSetting = decodeJsonFile(zoneFilename);
    busId = zoneSetting.busId;
    
    % internal elements
    mapBus_id_e2i = grid.getMapBus_id_e2i();
    % because the mapping is sparse, it will return a sparse matrix, hence
    % the need for the function 'full'
    internalBusId = full(mapBus_id_e2i(busId));
    internalGrid = grid;
    internalGrid.replaceExternalByInternalMatpowercase();
    internalTopology = ZoneTopology(zoneName, internalBusId, internalGrid);
end