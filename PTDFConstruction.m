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
classdef PTDFConstruction < handle
    properties (SetAccess = protected)
        PTDFBus
        PTDFGen
        PTDFBatt
        PTDFFrontierBus

        busId
        frontierBusId % buses inside the zone that connects with the rest of the electrical grid
        branchIdx % remember the internalBranchIdx = branchIdx
        genIdx
        battIdx
    end

    methods
        function obj = PTDFConstruction(busId, frontierBusId, branchIdx, genIdx, battIdx)
            arguments
                busId   (:,1)   {mustBeInteger}
                frontierBusId (:,1) {mustBeInteger}
                branchIdx (:,1) {mustBeInteger}
                genIdx (:,1) {mustBeInteger}
                battIdx (:,1) {mustBeInteger}
            end
            obj.busId = busId;
            obj.frontierBusId = frontierBusId;
            obj.branchIdx = branchIdx;
            obj.genIdx = genIdx;
            obj.battIdx = battIdx;
        end

        function ptdf = getPTDFBus(obj)
            ptdf = obj.PTDFBus;
        end

        function ptdf = getPTDFFrontierBus(obj)
            ptdf = obj.PTDFFrontierBus;
        end

        function ptdf = getPTDFGen(obj)
            ptdf = obj.PTDFGen;
        end

        function ptdf = getPTDFBatt(obj)
            ptdf = obj.PTDFBatt;
        end

        function setPTDF(obj, electricalGrid)
            arguments
                obj
                electricalGrid (1,1) ElectricalGrid
            end
            obj.PTDFBus = electricalGrid.getPTDFBus(obj.branchIdx, obj.busId);
            obj.PTDFFrontierBus = electricalGrid.getPTDFBus(obj.branchIdx, obj.frontierBusId);
            obj.PTDFGen = electricalGrid.getPTDFGen(obj.branchIdx, obj.genIdx);
            obj.PTDFBatt = electricalGrid.getPTDFBatt(obj.branchIdx, obj.battIdx);
        end

    end

end