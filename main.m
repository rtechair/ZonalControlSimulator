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

%{
Add the project directory and all its subdirectories to the matlab search path.

This action eases the folder management of the project: any source code can
be in any folder of the project, matlab will find it.

These additions are only temporary, they are removed when exiting matlab.

main.m must remain in the root folder of the project, otherwise the following lines must be changed.
%}
filepath = fileparts(mfilename('fullpath'));
addpath(genpath(filepath));

%% RUN A SIMULATION
transmission = TransmissionSimulation('simulation.json');

transmission.runSimulation();

isTopologyShown = false;
isModelResultShown = false;
isSimulationResultShown = true;

% in case of 1 zone:
isSimulationResultSaved = false;
isPtdfEstimationSaved = false;

% in case of at least 2 zones simulated
isMultipleSimulationResultsSaved = false;


if isTopologyShown
    transmission.plotZonesTopology();
end

if isModelResultShown
    transmission.plotZonesModelResult();
end

if isSimulationResultShown
    transmission.plotZonesSimulationResult();
end

if isSimulationResultSaved
    simulationResult = transmission.zones{1,1}.simulationResult;
    save("resultSimulation.mat", "simulationResult");
end

if isPtdfEstimationSaved
    ptdfEstimation.ptdfGen = transmission.zones{1,1}.controller.ptdfGen;
    ptdfEstimation.ptdfBatt = transmission.zones{1,1}.controller.ptdfBatt;
    ptdfEstimation.ptdf_G_matpower =  transmission.zones{1,1}.controller.ptdf_G_matpower;
    ptdfEstimation.ptdf_B_matpower = transmission.zones{1,1}.controller.ptdf_Batt_matpower;
    save("resultPtdfEstimation.mat", "ptdfEstimation");
end


if isMultipleSimulationResultsSaved
    a = 'result_';
    z1 = 'VGsmall';
    z2 = 'VTV';
    
    %situation = '_Approx';
    situation = '_FakeApprox';
    %situation = '_MIP';
    %situation = '_NoController';
    b = '.mat';

    nameFileZ1 = string([a z1 situation b]);
    nameFileZ2 = string([a z2 situation b]);

    simulationResult = transmission.zones{1,1}.simulationResult;
    save(nameFileZ1,"simulationResult");
    simulationResult = transmission.zones{2,1}.simulationResult;
    save(nameFileZ2,"simulationResult");
end