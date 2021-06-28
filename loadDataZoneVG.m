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

%{
From Alessio's code:
 set the initial sample of Power_available_percentage_simulationtime to be
considered for the simulation, for each generator
PA1_ini = 195;%% 150;
PA2_ini = 185;% 165;
PA3_ini = 175;% 170;
PA4_ini = 160;% 140;
% PA1_ini = 95;%% 150;
% PA2_ini =  85;% 165;
% PA3_ini =  75;% 170;
% PA4_ini =  60;% 140;
%}
zoneVG_startingIterationOfWindForGen = [195 185 175 160]';

zoneVG_simulationTimeStep = 1;
zoneVG_cb = 0.001; % conversion factor for battery power output

zoneVG_battConstPowerReduc = zoneVG_cb * ones(zoneVG_numberOfBatteries,1); % TODO: needs to be changed afterwards, with each battery coef

zoneVG_SamplingTime = 5;

zoneVG_DelayBattSec = 1;
zoneVG_DelayCurtSec = 45;