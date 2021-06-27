%{
JEAN'S ORDERING
zone2_bus = [4875 4710 2506 4915 4546 4169]';
zone2_bus_name = ["VTV" "TRE" "LAZ" "VEY" "SPC" "SIS"];

PERSONAL ORDERING, the ascending order has no impact regarding
the effectiveness of the code. 
However, selection of column vectors instead of row vectors is meant for consistency with column vectors obtained using
MatPower functions: https://matpower.org/docs/ref/
%}

zoneVTV_bus_id = [2506 4169 4546 4710 4875 4915]';

zoneVTV_numberOfGenerators = 3;
zoneVTV_numberOfBatteries = 1;

zoneVTV_simulationTimeStep = 1;
zoneVTV_cb = 0.001; % conversion factor for battery power output

zoneVTV_battConstPowerReduc = zoneVTV_cb * ones(zoneVTV_numberOfBatteries,1); % TODO: needs to be changed afterwards, with each battery coef

zoneVTV_SamplingTime = 5;

zoneVTV_DelayBattSec = 1;
zoneVTV_DelayCurtSec = 45;