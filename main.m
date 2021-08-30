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
isResultShown = true;

if isTopologyShown
transmission.plotZonesTopology();
end

if isResultShown
transmission.plotZonesResult();
end