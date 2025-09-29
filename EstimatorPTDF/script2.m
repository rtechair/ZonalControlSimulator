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

ptdfBus= ptdfConstruction.getPTDFBus();
ptdfGen = ptdfConstruction.getPTDFGen();
ptdfBatt = ptdfConstruction.getPTDFBatt();


isBranch9000SwitchedOff = true;
isBranch2857SwitchedOff = true;
isBranch7703SwitchedOff = true;
isBranch7704SwitchedOff = true;
isBranch3974SwitchedOff = true;
isBranch4764SwitchedOff = true;

if isBranch9000SwitchedOff
    branchBorderIdxToBreak = 9000;
    [ptdfBus9000, ptdfGen9000, ptdfBatt9000] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

if isBranch2857SwitchedOff
    branchBorderIdxToBreak = 2857;
    [ptdfBus2857, ptdfGen2857, ptdfBatt2857] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

if isBranch7703SwitchedOff
    branchBorderIdxToBreak = 7703;
    [ptdfBus7703, ptdfGen7703, ptdfBatt7703] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

if isBranch7704SwitchedOff
    branchBorderIdxToBreak = 7704;
    [ptdfBus7704, ptdfGen7704, ptdfBatt7704] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

if isBranch3974SwitchedOff
    branchBorderIdxToBreak = 3974;
    [ptdfBus3974, ptdfGen3974, ptdfBatt3974] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

if isBranch4764SwitchedOff
    branchBorderIdxToBreak = 4764;
    [ptdfBus4764, ptdfGen4764, ptdfBatt4764] = getAllPTDF(branchBorderIdxToBreak, grid, ptdfConstruction);
end

function [ptdfBus, ptdfGen, ptdfBatt] = getAllPTDF(branchIdxToSwitchOff, grid, ptdfConstruction)
    statusBranchOff = 0;
    grid.setBranchStatus(branchIdxToSwitchOff, statusBranchOff);
    grid.setNetworkPTDF();
    ptdfConstruction.setPTDF(grid);
    ptdfBus= ptdfConstruction.getPTDFBus();
    ptdfGen = ptdfConstruction.getPTDFGen();
    ptdfBatt = ptdfConstruction.getPTDFBatt();

    statusBranchOn = true;
    grid.setBranchStatus(branchIdxToSwitchOff, statusBranchOn);
    %grid.setNetworkPTDF();
end