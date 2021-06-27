%{
JEAN'S ORDERING:
zone1_bus = [2076 2135 2745 4720  1445 10000]';
zone1_bus_name = ["GR" "GY" "MC" "TR" "CR" "VG"];

PERSONAL ORDERING, the ascending order has no impact regarding
the effectiveness of the code. 
However, selection of column vectors instead of row vectors is meant for consistency with column vectors obtained using
MatPower functions: https://matpower.org/docs/ref/
%}


zoneVG_bus_id = [1445 2076 2135 2745 4720 10000]';

zoneVG_numberOfGenerators = 4;
zoneVG_numberOfBatteries = 1;

zoneVG_simulationTimeStep = 1;
zoneVG_cb = 0.001; % conversion factor for battery power output

zoneVG_battConstPowerReduc = zoneVG_cb * ones(zoneVG_numberOfBatteries,1); % TODO: needs to be changed afterwards, with each battery coef

zoneVG_SamplingTime = 5;

zoneVG_DelayBattSec = 1;
zoneVG_DelayCurtSec = 45;