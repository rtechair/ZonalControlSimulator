function updateCaseForZone2()

mpc = loadcase('case6468rte_zone1');

% Define the bus identity
bus_LAZ = 2506;
bus_SIS = 4169;
bus_SPC = 4546;
bus_TRE = 4710;
bus_VTV = 4875;
bus_VEY = 4915;

% Define the maximum power output for the production groups and the batteries

PG_max_TRE = 64.7;
PG_max_VTV = 53.07;
PB_max_VTV = 10; %Jean said 10 or 12MW at VTV for the battery, PB_min_VTV = - PB_max_VTV
PG_max_VEY = 35.5;
% power gen of other buses are unchanged

%{
All the buses already exist, check using find(mpc.bus(:,1)==bus_id) for each
bus_id
, however there is no information on:
GENERATORS at buses TRE, VTV and VEY
BATTERY at VTV
checked using find(mpc.gen(:,1)==bus_id)
%}
% Add the generators
mpc = addGenerator(mpc, bus_TRE, PG_max_TRE,0);
mpc = addGenerator(mpc, bus_VTV, PG_max_VTV,0);
mpc = addGenerator(mpc, bus_VEY, PG_max_VEY,0);
% Add the battery
mpc = addGenerator(mpc, bus_VTV, PB_max_VTV, - PB_max_VTV);

%save the updated basecase
savecase('case6468rte_zone1and2','mpc')
