%{
JEAN'S ORDERING:
zone1_bus = [2076 2135 2745 4720  1445 10000]';
zone1_bus_name = ["GR" "GY" "MC" "TR" "CR" "VG"];

PERSONAL ORDERING, the ascending order has no impact regarding
the effectiveness of the code. 
However, selection of column vectors instead of row vectors is meant for consistency with column vectors obtained using
MatPower functions: https://matpower.org/docs/ref/
%}

inputZoneVG.BusId = [1445 2076 2135 2745 4720 10000]';

vgTS1 = [195 185 175 160]';
vgTS2 = [150 110 120 100]';
inputZoneVG.StartTimeSeries = vgTS2;


inputZoneVG.BattConstPowerReduc = 0.001;

inputZoneVG.SamplingTime = 5;


inputZoneVG.DelayCurtSec = 45; %45
inputZoneVG.DelayBattSec = 1;

inputZoneVG.DelayCurt = ceil(inputZoneVG.DelayCurtSec / inputZoneVG.SamplingTime);
inputZoneVG.DelayBatt = ceil(inputZoneVG.DelayBattSec / inputZoneVG.SamplingTime);