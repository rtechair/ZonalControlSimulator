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

isTopologyShown = true;
isModelResultShown = false;
isSimulationResultShown = true;
isPtdfEstimationShown = false;

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

if isPtdfEstimationShown
    ptdfEstimation.ptdfGen = transmission.zones{1,1}.controller.ptdfGen;
    ptdfEstimation.ptdfBatt = transmission.zones{1,1}.controller.ptdfBatt;
    ptdfEstimation.ptdf_G_matpower =  transmission.zones{1,1}.controller.ptdf_G_matpower;
    ptdfEstimation.ptdf_B_matpower = transmission.zones{1,1}.controller.ptdf_Batt_matpower;
    duration = 1200;
    timestep = 5;
    n_step = duration / timestep;
    time = timestep:timestep:duration;

    ptdfBr1Gen2 = ptdfEstimation.ptdfGen(1,2,:);
    ptdfBr1Gen2 = reshape(ptdfBr1Gen2, [n_step, 1]);
    figure;
    stairs(time, ptdfBr1Gen2, 'LineWidth',2);
    hold on
    stairs(time, ptdfEstimation.ptdf_G_matpower(1,2) * ones(n_step,1));
    xlegend = "time in seconds";
    xlabel(xlegend);
    ylabel("percentage")
    title("PTDF Br 1 Gen 2");

    ptdfBr3Gen2 = ptdfEstimation.ptdfGen(3,2,:);
    ptdfBr3Gen2 = reshape(ptdfBr3Gen2, [n_step, 1]);
    figure;
    stairs(time, ptdfBr3Gen2, 'LineWidth',2);
    hold on
    stairs(time, ptdfEstimation.ptdf_G_matpower(3,2) * ones(n_step,1));
    xlegend = "time in seconds";
    xlabel(xlegend);
    ylabel("percentage")
    title("PTDF Br 3 Gen 2");

    ptdfBr1Gen4 = ptdfEstimation.ptdfGen(1,4,:);
    ptdfBr1Gen4 = reshape(ptdfBr1Gen4, [n_step, 1]);
    figure;
    stairs(time, ptdfBr1Gen4, 'LineWidth',2);
    hold on
    stairs(time, ptdfEstimation.ptdf_G_matpower(1,4) * ones(n_step,1));
    xlegend = "time in seconds";
    xlabel(xlegend);
    ylabel("percentage")
    title("PTDF Br 1 Gen 4");

    ptdfBr1Batt = ptdfEstimation.ptdfBatt(1,1,:);
    ptdfBr1Batt = reshape(ptdfBr1Batt, [n_step, 1]);
    figure;
    stairs(time, ptdfBr1Batt, 'LineWidth',2);
    hold on
    stairs(time, ptdfEstimation.ptdf_B_matpower(1,1) * ones(n_step,1));
    xlegend = "time in seconds";
    xlabel(xlegend);
    ylabel("percentage")
    title("PTDF Br 1 Batt");

    ptdfBr4Gen4 = ptdfEstimation.ptdfGen(4,4,:);
    ptdfBr4Gen4 = reshape(ptdfBr4Gen4, [n_step, 1]);
    figure;
    stairs(time, ptdfBr4Gen4, 'LineWidth',2);
    hold on
    stairs(time, ptdfEstimation.ptdf_G_matpower(4,4) * ones(n_step,1));
    xlegend = "time in seconds";
    xlabel(xlegend);
    ylabel("percentage")
    title("PTDF Br 4 Gen 4");
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