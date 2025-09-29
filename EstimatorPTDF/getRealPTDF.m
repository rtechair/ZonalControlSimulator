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
function [ptdfBus, ptdfGen, ptdfBatt] = getRealPTDF()
    basecaseFilename = "case6468rte_zone_VG_VTV_BLA.m";
    grid = ElectricalGrid(basecaseFilename);
    busId = [1445, 2076, 2135, 2745, 4720, 10000];
    topology = ZoneTopology(" VGsmall", busId, grid);
    
    frontierBusId = topology.getFrontierBusId();
    branchIdx = topology.getBranchIdx();
    genIdx = topology.getGenOnIdx();
    battIdx = topology.getBattOnIdx();
    
    grid.setNetworkPTDF();
    
    ptdfConstruction = PTDFConstruction(busId, frontierBusId, branchIdx, genIdx, battIdx);
    
    ptdfConstruction.setPTDF(grid);
    
    ptdfBus = ptdfConstruction.getPTDFBus();
    ptdfGen = ptdfConstruction.getPTDFGen();
    ptdfBatt = ptdfConstruction.getPTDFBatt();
end