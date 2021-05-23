%{
JEAN'S ORDERING
zone1_bus = [2076 2135 2745 4720  1445 10000]';
zone1_bus_name = ["GR" "GY" "MC" "TR" "CR" "VG"];

zone2_bus = [4875 4710 2506 4915 4546 4169]';
zone2_bus_name = ["VTV" "TRE" "LAZ" "VEY" "SPC" "SIS"];
%}

%PERSONAL ORDERING, the ascending order has no impact regarding
%the effectiveness of the code. 
% However, selection of column vectors instead of row vectors is meant for consistency with column vectors obtained using
%MatPower functions 
% https://matpower.org/docs/ref/

zone1_bus_id = [1445 2076 2135 2745 4720 10000]';
zone1_bus_name = ["CR" "GR" "GY" "MC" "TR" "VG"];

zone2_bus_id = [2506 4169 4546 4710 4875 4915]';
zone2_bus_name = ["LAZ" "SIS" "SPC" "TRE" "VTV" "VEY"];


zone3_bus = [];

zones_bus = {zone1_bus_id, zone2_bus_id, zone3_bus};

%% BASECASE

% if the basecase is not correctly updated, update it
handleBasecase();

basecase = loadcase('case6468rte_zone1and2'); %mpc_ext

% crash test, add a island bus, not connected to the rest of the network
% issue is: matpower does not delete this bus, 
% basecase_int.order.bus.status.off is empty
% do another crash on the case9.m
%{
basecase = addBus(basecase,99999,    2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);

basecase = addBus(basecase,99998,    2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);
basecase.branch(end+1,:) = [ 99998, 99999, 0.2, 0.4, 0.5, 0, 0, 0, 1, 0, 1, 0, 0];
%}

%% MAP
% convert to the internal basecase structure for Matpower
basecase_int = ext2int(basecase);

% check if a bus or a branch has been deleted, currently the code does not
% handle the case if some are deleted/off
[isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecase_int);
if isBusDeleted
    disp('a bus has been deleted, nothing has been made to handle this situation, the code should not work')
end
if isBranchDeleted
    disp('a branch has been deleted, nothing has been made to handle this situation, the code should not work')
end
% bus map
[mapBus_id2idx, mapBus_idx2id] = mapBus_id2idx_idx2id(basecase);
mapBus_id_e2i = basecase_int.order.bus.e2i; % sparse column vector
mapBus_id_i2e = basecase_int.order.bus.i2e; % full column vector

% online gen map, this include batteries
[mapGenOn_idx_e2i, mapGenOn_idx_i2e] = mapGenOn_idx_e2i_i2e(basecase_int);

%% HOW CONVERSION WORKS

% BUS
%{
In terms of conversion:
bus_id
bus_idx     using mapBus_id2idx(bus_id)
bus_id_int  using mapBus_id_e2i(bus_id)
bus_idx_int = bus_id_int
then Matpower does its work
then convert back:
bus_id_back using mapBus_id_e2i(bus_id_int)
bus_idx_back using mapBus_id2idx(bus_id_back)
%}

% BRANCH
%{ 
TODO check branches are not moved during the conversion.

he branches are accessed through their idx, they do not have an id.
if no branch is deleted during the internal conversion, then the branch
will remain as the same index in the internal basecase.

Additionnally, the idx is more important than fbus and tbus, as the former
allows to find the latter, while not necessarily the other way as several
branches can connect the same 2 buses
%}

% GEN
%{
An important point regarding the generators is, the off-generators are
removed in the internal basecase from the external basecase.
the generators are accessed through their idx, they do not have an id
%}

%% CONVERSION OF ZONE 1


% create the object associated to the zone

% get the rest of the info about the zone
%{
[zone1_branch_inner_idx, zone1_branch_border_idx] = findInnerAndBorderBranch(zone1_bus_id, basecase);
zone1_bus_border_id = findBorderBus(zone1_bus_id, zone1_branch_border_idx, basecase);
[zone1_gen_idx, zone1_battery_idx] = findGenAndBattOnInZone(zone1_bus_id, basecase);
%}


z1 = Zone(basecase, zone1_bus_id);
z2 = Zone(basecase, zone2_bus_id);

z1 = setInteriorIdAndIdx( z1, mapBus_id_e2i, mapGenOn_idx_e2i);
z2 = setInteriorIdAndIdx( z2, mapBus_id_e2i, mapGenOn_idx_e2i);



%% Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k-tau)+Dd(k)
%{
x = [Fij Pc Pb Eb Pg ]'     uc = DeltaPc      ub =DeltaPb    w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
cf Powertech paper
%}
% External and internal basecase
[n_bus, n_branch, n_gen, n_batt] = findBasecaseDimension(basecase); % [6469, 9001, 1228, 77]
[n_bus_int, n_branch_int, n_gen_int, n_batt_int] = findBasecaseDimension(basecase_int); % [6469, 9001, 396, 13]

% Zone 1
[z1.N_bus, z1.N_branch, z1.N_genOn, z1.N_battOn] = findZoneDimension(z1.Bus_id, z1.Branch_idx,z1.GenOn_idx, z1.BattOn_idx);

z1.Simulation_time_unit = 1; % sec, TODO look at the previous main, Sampling_time = 5 and simulation_time_unit = 1, I do not understand
z1_cb = 0.001; % conversion factor for battery power output
z1.Batt_cst_power_reduc = z1_cb * ones(z1.N_battOn,1); % TODO: needs to be changed afterwards, with each battery coef

%{
 z1 = setDynamicSystem(z1, basecase_int, z1.Bus_id, z1.Branch_idx, z1.GenOn_idx, z1.BattOn_idx,...
                mapBus_id_e2i, mapGenOn_idx_e2i, z1.Simulation_time_unit, z1.Batt_cst_power_reduc);
%}
%{
 [z1.A, z1.Bc, z1.Bb, z1.Dg, z1.Dt, z1.Da] = dynamicSystem(basecase_int, z1.Bus_id, z1.Branch_idx, z1.GenOn_idx, z1.BattOn_idx,...
               mapBus_id_e2i, mapGenOn_idx_e2i, z1.Simulation_time_unit, z1.Batt_cst_power_reduc);
 %}
 
% Zone 2
[z2.N_bus, z2.N_branch, z2.N_genOn, z2.N_battOn] = findZoneDimension(z2.Bus_id, z2.Branch_idx,z2.GenOn_idx, z2.BattOn_idx);

z2.Simulation_time_unit = 1; % sec, TODO look at the previous main, Sampling_time = 5 and simulation_time_unit = 1, I do not understand
z2_cb = 0.001; % conversion factor for battery power output
z2.Batt_cst_power_reduc = z2_cb * ones(z2.N_battOn,1); % TODO: needs to be changed afterwards, with each battery coef

%{
z2 = setDynamicSystem(z2, basecase_int, z2.Bus_id, z2.Branch_idx, z2.GenOn_idx, z2.BattOn_idx,...
                mapBus_id_e2i, mapGenOn_idx_e2i, z2.Simulation_time_unit, z2.Batt_cst_power_reduc);
%}

%% Simulation initialization

%% Compute available power (PA) and delta PA using real data
% all PA and DeltaPA values are computed prior to the simulation
duration = 600;
z1.Sampling_time = 5;

z1.N_iteration = floor(duration / z1.Sampling_time);
z1 = getPAandDeltaPA(z1, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');

z2.Sampling_time = 5;
z2.N_iteration = floor(duration / z2.Sampling_time);
z2 = getPAandDeltaPA(z2, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');


%% Set some preconfigurated curtailment DeltaPC
z1_maxPA_of_genOn = basecase.gen(z1.GenOn_idx, 9); % computed inside getPAandDeltaPA, but can't be in setDeltaPC as basecase not provided
z1 = setDeltaPC(z1, [1/7 1/3 2/3], 0.2, z1_maxPA_of_genOn); 
z1.maxPG = basecase.gen(z1.GenOn_idx, 9);

z2_maxPA_of_genOn = basecase.gen(z2.GenOn_idx, 9);
z2 = setDeltaPC(z2, [1/7 1/3 2/3], 0.2, z2_maxPA_of_genOn);

%% Initialize PC and DeltaPC
%PC(1) = 0; Other PC values will be computed online with DeltaPC values provided by the MPC

z1.PC = zeros(z1.N_genOn, zone.N_iteration+1);
z1.DeltaPC = zeros(z1.N_genOn, zone.N_iteration);


%% Initialize PB and DeltaPB
% DeltaPB has not been set previously however

z1.DeltaPB = zeros(z1.N_battOn, z1.N_iteration);
z1.PB = zeros(z1.N_battOn, z1.N_iteration+1);
%PB(1) = 0; which is already the case from the previous line
z1 = setPB(z1);

%% Initialization
step = 1;

z1 = setInitialPG(z1);


% update both basecase and basecase_int with the initial PG values, due to
% the generators On
initialInstant = 1;
[basecase, basecase_int] = updateGeneration(basecase, basecase_int, z1, initialInstant);


% Similarly, update for the batteries On
[basecase, basecase_int] = updateRealPowerBatt(basecase, basecase_int, z1, initialInstant);

% matpower option for the runpf function, see help runpf and help mpoption
% https://matpower.org/docs/ref/matpower7.1/lib/mpoption.html
mpopt = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
        'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
        'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
    
[results, success] = runpf( basecase_int, mpopt); % https://matpower.org/docs/ref/matpower7.1/lib/runpf.html

%% Extraction from results
% TODO: check if matpower values fits the model, e.g. for PG =
% results.gen(:,2), real power output,
% if PG > 0, does it mean the power goes on the network or in the battery?
%{
IMPORTANT: 'results' are returned using 'basecase' data, not
'basecase_int' even though the 'runpf' computation was done while
providing the internal basecase
%}
% X = [ Fij PC PB EB PG PA]', 
% dimension-wise: [ N_branch N_genOn N_battOn N_battOn N_genOn N_genOn] '
% X_0 = zeros(z1.N_branch + 3*z1.N_genOn + 2*z1.N_battOn, 1);

% z1_Fij_K = results.branch(z1.Branch_idx, 14); % column 14 is PF: real power injected at "from" end bus

% for the zone 1: EB_init = 750


% initialize the energy in the batteries, as zeros
z1.EB = zeros(z1.N_battOn,z1.N_iteration+1);

%{
z2_Fij_K = results.branch(z1.Branch_idx, 14);
z2_PB_K = results.gen(z1.BattOn_idx, 2);
z2_PG_K = results.gen(z1.GenOn_idx,2);
%}

Fij = zeros(z1.N_branch, z1.N_iteration);
% column 14 of results.branch is PF: real power injected at "from" end bus
z1.Fij(:,step) = results.branch(z1.Branch_idx, 14); 


% set the initial values for PT(k) in x(k)
z1 = getPT_k(results, z1, step);

z1.DeltaPT = zeros(z1.N_branch,z1.N_iteration);

% store info about 'runpf' convergence
infoRUNPF(1:3,step) = [results.success results.et results.iterations]';

% save the whole set of produced data:
cellOfResults = cell(1,z1.N_iteration);
cellOfResults{1} = results;


%% Preallocation data structure for the whole simulation
%{
% could create a simulation, associate with a basecase and a zone ?

% State
z1.STATE = zeros(z1.N_branch + 3*z1.N_genOn + 2*z1.N_battOn, z1.N_iteration + 1);
% Control: curtailment and battery
z1.CONTROL_C = zeros(z1.N_genOn, z1.N_iteration + 1);
z1.CONTROL_B = zeros(z1.N_battOn, z1.N_iteration + 1);
% Disturbance: DeltaPA, DeltaPG, DeltaPT
z1.DIST_A = zeros(z1.N_genOn, z1.N_iteration + 1);
z1.DIST_G = zeros(z1.N_genOn, z1.N_iteration + 1);
z1.DIST_T = zeros(z1.N_genOn, z1.N_iteration + 1);
%}

%% Step 0 for simulation: saving the data of initial values


% currently only care about 1 zone. Later do a scheduling between several


 
%{
Fij         obtained from 'results'
PC          here it is precomputed, but should be a deduced information
PB          deduced from control DeltaPB
EB          computed based on PB and DeltaPB values
PG          computed using several variables
PA          Precomputed (L168)
PT          obtained from 'results', using the associate function getPT

DeltaPC     Control, here precomputed
DeltaPB     Control, here precomputed

DeltaPG     Computed using the associate function

DeltaPA     Precomputed (L168)

DeltaPT     computed based on PT
%}

%{
Fully computed
PA
DeltaPA
PB
DeltaPB
PC
DeltaPC


In Alessio's code :
Initialization
compute PG
set PG and PB in the basecase
'runpf': to get PT and Fij
compute and save all variables: 
Fij (from runpf)
PT (from runpf)
PC (given data)
PB
EB
PG (previously computed)


for k= 2:zone.N_iteration + 1 ?
DeltaPC
DeltaPB
DeltaPG
DeltaPA

update
PG(k+1) = PG(k) + DeltaPG(k) - DeltaPC(k-tau)
PB(k+1) = PB(k) + DeltaPB(k-d)
on the basecase??
why not on the case obtained from 'results'??

results = runpf
Get the updated values for Fij, Pb, Eb, Pa

update
PC(k+1) = PC(k) + DeltaPC(k)
PG(k+1) = PG(k) + DeltaPG(k) - DeltaPC(k-tau) , notice here it is
DeltaPC(k), so the delay does not seem to be considered

line 604: why the PG(k+1) value is computed in Xk, but with:
PG(k+1) = PG(k) + DeltaPG(k)
PT(k+1) computed from the results
hence, DeltaPT(k) = PT(k+1) - PT(k)

%}



    


%{
classdef Simulation
    properties
        Basecase
        Basecase_int
        cellOfZones
        
        cellOfResults
        PGCD
    end
    
    methods
        function obj = Simulation(basecase, basecase_int, cellOfZones)
            arguments
                basecase
                basecase_int
                cellOfZones
            end
        end
            
    end
end
    
%}