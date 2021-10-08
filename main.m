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

transmission.runSimulation2();

isTopologyShown = false;
isResultShown = true;

if isTopologyShown
transmission.plotZonesTopology();
end

if isResultShown
transmission.plotZonesResult();
end