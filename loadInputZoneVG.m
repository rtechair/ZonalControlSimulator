%{
This file is to configure Zone VG's data.

Selection of column vectors instead of row vectors is meant for consistency
with column vectors obtained usingMatPower functions: https://matpower.org/docs/ref/

Regarding data, rows correspond to elements such as bus, gen, batt, etc.
Columns correspond to time steps
%}

inputZoneVG.BusId = [1445 2076 2135 2745 4720 10000]';

inputZoneVG.BranchFlowLimit = 45;

inputZoneVG.FilenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

% When does the time series start for each gen, from the wind charging rate file:
startTimeSeries1 = [195 185 175 160]';
startTimeSeries2 = [150 110 120 100]';
inputZoneVG.StartTimeSeries = startTimeSeries2;


% From the paper 'Modeling the Partial Renewable Power Curtailment
% for Transmission Network Management', BattConstPowerReduc corresponds to:
% T * C_n^B in the battery energy equation
inputZoneVG.BattConstPowerReduc = 0.001;

inputZoneVG.SamplingTime = 5;


inputZoneVG.DelayCurtSec = 45;
inputZoneVG.DelayBattSec = 1;

inputZoneVG.DelayCurt = ceil(inputZoneVG.DelayCurtSec / inputZoneVG.SamplingTime);
inputZoneVG.DelayBatt = ceil(inputZoneVG.DelayBattSec / inputZoneVG.SamplingTime);