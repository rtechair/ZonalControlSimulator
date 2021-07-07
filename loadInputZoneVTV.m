%{
JEAN'S ORDERING
zone2_bus = [4875 4710 2506 4915 4546 4169]';
zone2_bus_name = ["VTV" "TRE" "LAZ" "VEY" "SPC" "SIS"];

PERSONAL ORDERING, the ascending order has no impact regarding
the effectiveness of the code. 
However, selection of column vectors instead of row vectors is meant for consistency with column vectors obtained using
MatPower functions: https://matpower.org/docs/ref/
%}

inputZoneVTV.BusId = [2506 4169 4546 4710 4875 4915]';

vtvTS1 = [195 185 175 160]';
vtvTS1 = floor(vtvTS1 / 3);
vtvTS2 = [150 110 120 100]';
vtvTS2 = floor(vtvTS2 / 3);
inputZoneVTV.StartTimeSeries = vtvTS2;


inputZoneVTV.BattConstPowerReduc = 0.001;

inputZoneVTV.SamplingTime = 15;


inputZoneVTV.DelayCurtSec = 45;
inputZoneVTV.DelayBattSec = 1;

inputZoneVTV.DelayCurt = ceil(inputZoneVTV.DelayCurtSec / inputZoneVTV.SamplingTime);
inputZoneVTV.DelayBatt = ceil(inputZoneVTV.DelayBattSec / inputZoneVTV.SamplingTime);