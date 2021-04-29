function updateCaseForZone1()
% update basecase 'case6468rte_mod', this function won't remain as it is in the
% final version
% TODO: create flexibility for the update of a basecase

%%Alessio's comment:
% In order to make the simulations as simple and portable we will use the following framework: 
% in Matlab the powerflow function (non-linear) within matpower toolbox.
% In particular, you need to use in matpower, the case 'case6468rte.m'.
% The zone to be controlled via MPC is the one including the lines between
% the following buses:  (the letters are indicative, the numbers are important)
% GR 2076
% GY 2135
% MC 2745
% TR 4720
% CR 1445
% Also, you need to add a bus VG in the middle of the line between MC and GR (by dividing by two the impedances)
% Add the production groups:
% 78MW at VG
% 66MW at GR 2076
% 54MW at MC 2745
% 10MW at TR 4720
% A battery of 30Mwh at VG, with power of 10MW both upward and downward.
% For now, we do not consider the energy of the battery.
% You need to downsize homogenously the thermal limits up to the point where the line with the highest charge is at 130%.
% Use a wind production time-line for each production group in the above list.
% Consider as control lever the fact that we can decrease the production with levels of 25% for each of the busses.
% The function runpf of matpower should function for the simulation.

%%Update basecase

% load the original case
mpc=loadcase('case6468rte_mod');


% Define the maximum power output for the production groups and the batteries
PG_max_VG = 78; % 78MW at VG
PG_max_GR = 66; % 66MW at GR 2076
PG_max_MC = 54; % 54MW at MC 2745
PG_max_TR = 10; % 10MW at TR 4720
PB_max_VG = 10; % 10MW at VG for the battery, PB_min_VG = - PB_max_VG

%% Step 1): Add the desired bus and generators
% Create a new bus: VG 10000
bus_VG = 10000;
mpc = addBus(mpc,bus_VG,    2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);
% Create a new generator at bus VG 10000
mpc = addGenerator(mpc,bus_VG,PG_max_VG,0);
% Create a  new battery at bus VG 10000
mpc = addGenerator(mpc,bus_VG,PB_max_VG,- PB_max_VG);
% Create a  new generator at bus GR 2076
mpc = addGenerator(mpc,2076,PG_max_GR,0);
% Create a  new generator at bus MC 2745
mpc = addGenerator(mpc,2745,PG_max_MC,0);
% Create a  new generator at bus TR 4720
mpc = addGenerator(mpc,4720,PG_max_TR,0);

%% Step 2): Check if there is a line between MC and GR; take the values and create the lines between MC and VG, and VG and GR
% look for the branch between MC and GR
bus_MC = 2745; %MC
bus_GR = 2076; %GR
% there is an unique branch between those 2 buses in this direction
% there is no branch (2076,fbus) that's why the other direction is not tested
[branch_idx,~]= find(mpc.branch(:,1)==bus_MC & mpc.branch(:,2)==bus_GR); 

branch_info = num2cell(mpc.branch(branch_idx,:)); %https://stackoverflow.com/questions/2337126/how-do-i-do-multiple-assignment-in-matlab;
[~, ~, r,x, b, rateA, rateB, rateC,ratio,angle,status,angmin,angmax] = branch_info{:};

% remove the branch
mpc.branch(branch_idx,:) = [];
% create the new branches between MC and VG, and VG and GR, with half the values of the old branch

mpc.branch(end+1,:) = [bus_MC, bus_VG,r/2,x/2,b/2,rateA,rateB,rateC,ratio,angle,status,angmin,angmax];
mpc.branch(end+1,:) = [bus_GR, bus_VG,r/2,x/2,b/2,rateA,rateB,rateC,ratio,angle,status,angmin,angmax];

% save the updated basecase
savecase('case6468rte_zone1','mpc')


