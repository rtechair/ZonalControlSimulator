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
classdef ZonePTDFConstructor < handle

    properties (SetAccess = protected)
        grid
        mapBus_id_e2i
        mapGenOn_idx_e2i
        internalMatpowercase

        networkPTDF
    end

    methods
        function obj = ZonePTDFConstructor(basecaseFilename)
            arguments
                basecaseFilename char
            end
            obj.grid = ElectricalGrid(basecaseFilename);
            obj.mapBus_id_e2i = obj.grid.getMapBus_id_e2i();
            obj.mapGenOn_idx_e2i = obj.grid.getMapGenOn_idx_e2i();
            obj.internalMatpowercase = obj.grid.getInternalMatpowercase();
            obj.setNetworkPTDF();
        end

        function setNetworkPTDF(obj)
            obj.networkPTDF = makePTDF(obj.internalMatpowercase);
        end

        function matrix = getNetworkPTDF(obj)
            matrix = obj.networkPTDF;
        end

        function [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = getZonePTDF(obj, zoneBusId)
            arguments
                obj
                zoneBusId {mustBeVector}
            end
            zoneName = '';
            zoneTopology = ZoneTopology(zoneName, zoneBusId, obj.grid);
            branchIdx = zoneTopology.getBranchIdx();
            genOnIdx = zoneTopology.getGenOnIdx();
            battOnIdx = zoneTopology.getBattOnIdx();

            busIdOfGenOn = obj.grid.getBuses(genOnIdx);
            busIdOfbattOn = obj.grid.getBuses(battOnIdx);
            
            internalBusId = obj.mapBus_id_e2i(zoneBusId);
            internalBranchIdx = branchIdx;
            internalBusIdOfGenOn = obj.mapBus_id_e2i(busIdOfGenOn);
            internalBusIdOfBattOn = obj.mapBus_id_e2i(busIdOfbattOn);

            branchPerBusPTDF = obj.networkPTDF(internalBranchIdx, internalBusId);
            branchPerBusOfGenPTDF = obj.networkPTDF(internalBranchIdx, internalBusIdOfGenOn);
            branchPerBusOfBattPTDF = obj.networkPTDF(internalBranchIdx, internalBusIdOfBattOn);
        end
    end

end