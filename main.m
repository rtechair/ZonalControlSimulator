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

setInteriorIdAndIdx( z1, mapBus_id_e2i, mapGenOn_idx_e2i);
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
setDynamicSystem(z1, basecase_int, z1.Bus_id, z1.Branch_idx, z1.GenOn_idx, z1.BattOn_idx,...
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

duration = 600;
z1.Sampling_time = 5;
z1.N_iteration = floor(duration / z1.Sampling_time);
z1.maxPG = basecase.gen(z1.GenOn_idx, 9);

z1_delay_batt_sec = 1;
z1_delay_curt_sec = 45;
z1.Delay_batt = ceil(z1_delay_batt_sec/ z1.Sampling_time);
z1.Delay_curt = ceil(z1_delay_curt_sec/ z1.Sampling_time);


z2.Sampling_time = 5;
z2.N_iteration = floor(duration / z2.Sampling_time);
z2.maxPG = basecase.gen(z2.GenOn_idx, 9);

%% Compute available power (PA) and delta PA using real data
% all PA and DeltaPA values are computed prior to the simulation

z1 = getPAandDeltaPA(z1, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');


z2 = getPAandDeltaPA(z2, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');


%% Set some preconfigurated curtailment DeltaPC
z1_maxPG_of_genOn = basecase.gen(z1.GenOn_idx, 9); % computed inside getPAandDeltaPA, but can't be in setDeltaPC as basecase not provided


%% Initialize PC and DeltaPC
%PC(1) = 0; Other PC values will be computed online with DeltaPC values provided by the MPC

z1.PC = zeros(z1.N_genOn, z1.N_iteration+1);

z1 = setDeltaPC(z1, [1/7 1/3 2/3], 0.2, z1.maxPG); 

z2.PC = zeros(z2.N_genOn, z2.N_iteration+1);

z2 = setDeltaPC(z2, [1/7 1/3 2/3], 0.2, z2.maxPG); 

%% Initialize PB and DeltaPB
% DeltaPB has not been set previously however
%PB(1) = 0; Other PB values will be computed online with DeltaPB values provided by the MPC
z1.PB = zeros(z1.N_battOn, z1.N_iteration+1);
z1.DeltaPB = zeros(z1.N_battOn, z1.N_iteration);

%% Initialize PG and DeltaPG
z1.PG = zeros(z1.N_genOn, z1.N_iteration+1);
z1.DeltaPG = zeros(z1.N_genOn, z1.N_iteration);
% Define PG(1)
z1 = setInitialPG(z1);

%% Initialize PT and DeltaPT
z1.PT = zeros(z1.N_bus, z1.N_iteration+1);
z1.DeltaPT = zeros(z1.N_bus, z1.N_iteration);

%% Initialize EB
% EB(1) = 0; Other EB values will be computed online
z1.EB = zeros(z1.N_battOn, z1.N_iteration+1);

%% Initialize Fij
z1.Fij = zeros(z1.N_branch, z1.N_iteration+1);

%% Initialization

% matpower option for the runpf function, see help runpf and help mpoption
% https://matpower.org/docs/ref/matpower7.1/lib/mpoption.html
mpopt = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
        'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
        'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
    
cellOfResults = cell(1,z1.N_iteration+1);
    
%% Simulation using runpf of Matpower

for step = 1: z1.N_iteration
    % update both basecase and basecase_int with the initial PG values, due to the generators On
    [basecase, basecase_int] = updateGeneration(basecase, basecase_int, z1, step);

    % Similarly, update for the batteries On
    [basecase, basecase_int] = updateRealPowerBatt(basecase, basecase_int, z1, step);
    
    % Run the power flow
    [results, success] = runpf(basecase_int, mpopt); % https://matpower.org/docs/ref/matpower7.1/lib/runpf.html
    
    % Extract Fij column 14 of results.branch is PF: real power injected at "from" end bus
    z1.Fij(:,step) = results.branch(z1.Branch_idx, 14);
    % Fij_fromBus = results.branch(z1.Branch_idx, 14);
    % Fij_endBus = results.branch(z1.Branch_idx, 16);
    
    % Extract PT(step)
    z1 = getPT_k(results, z1, step);
    
    %Compute DeltaPT(step-1) except if step = 1
    if step >= 2
        z1.DeltaPT(:,step-1) = z1.PT(:,step) - z1.PT(:, step-1);
    end
    
    % Notice DeltaPA(step-1) is already precomputed, so no need to compute
    % it. Maybe in the future
    
    %{
    Control actions: 
    here there is no MPC, however in the future there will be
    z1.DeltaPC(:,step) = getMPCDeltaPC(z1,step);
    z1.DeltaPB(:,step) = getMPCDeltaPB(z1,step);
    %}
    
    % Compute DeltaPG(step) except if step = N_iteration+1, i.e. the last iteration
    if step <= z1.N_iteration
        z1 = getDeltaPG_k(z1,step);
    end
    
    % Update the states
        % PC and PG
    if step >= z1.Delay_curt + 1
        z1.PC(:,step+1) = z1.PC(:,step)                      + z1.DeltaPC(:,step - z1.Delay_curt);
        z1.PG(:,step+1) = z1.PG(:,step) + z1.DeltaPG(:,step) - z1.DeltaPC(:,step - z1.Delay_curt);
    else
        z1.PC(:,step+1) = z1.PC(:,step);
        z1.PG(:,step+1) = z1.PG(:,step) + z1.DeltaPG(:,step);
    end
        % PB and EB
    if step >= z1.Delay_batt + 1
        z1.PB(:,step+1) = z1.PB(:,step) + z1.DeltaPB(:,step - z1.Delay_batt);
        z1.EB(:,step+1) = z1.EB(:,step) - z1.Batt_cst_power_reduc*z1.Simulation_time_unit *...
            ( z1.PB(:,step) + z1.DeltaPB(:,step - z1.Delay_batt) );
    else
        z1.PB(:,step+1) = z1.PB(:,step);
        z1.EB(:,step+1) = z1.EB(:,step) - z1.Batt_cst_power_reduc*z1.Simulation_time_unit * z1.PB(:,step);
    end
    
    % PA(step+1) being already precomputed, no need to compute it
    
    % Store the information regarding the simulation
    cellOfResults{step} = results;
  
end

% Do the power flow on the last iteration to get Fij and DeltaPT
[basecase, basecase_int] = updateGeneration(basecase, basecase_int, z1, z1.N_iteration+1);
[basecase, basecase_int] = updateRealPowerBatt(basecase, basecase_int, z1, z1.N_iteration+1);
[results, success] = runpf(basecase_int, mpopt);
z1.Fij(:,z1.N_iteration+1) = results.branch(z1.Branch_idx, 14);
z1 = getPT_k(results, z1, z1.N_iteration+1);
z1.DeltaPT(:,z1.N_iteration) = z1.PT(:,z1.N_iteration+1) - z1.PT(:, z1.N_iteration);
    
% Store the info regarding the simulation
infoRunpf(1:3,z1.N_iteration+1) = [results.success results.et results.iterations]';
cellOfResults{z1.N_iteration+1} = results;
    
%% Extraction from results

simulation = copy(z1);

t = 1:simulation.N_iteration+1;

if simulation.N_bus >= 9
    n_row_graph = 3;
else
    n_row_graph = 2;
end

fGen = figure('Name','for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)',...
    'NumberTitle', 'off'); 
% see for more info about figures: 
% https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
% https://www.mathworks.com/help/matlab/ref/figure.html
fGen.WindowState = 'maximize';

% plot for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
for gen = 1:simulation.N_genOn
    subplot(n_row_graph, n_row_graph, gen); ...
        hold on; ...
        stairs(t, simulation.PA(gen,:)); ...
        stairs(t, simulation.PC(gen,:)); ...
        f1 = simulation.maxPG(gen) - simulation.PC(gen,:);
        stairs(t, f1);...
        stairs(t, min(simulation.PA(gen,:), f1));
        % Description of the subplot
        bus_id_of_genOn = basecase.gen(simulation.GenOn_idx(gen),1);
        name = ['Gen\_idx: ', int2str(simulation.GenOn_idx(gen)), ', at bus: ', int2str(bus_id_of_genOn)];
        title(name);
    
end



% if PG > 0, does it mean the power goes on the network or in the battery?
%{
IMPORTANT: 'results' are returned using 'basecase' data, not
'basecase_int' even though the 'runpf' computation was done while
providing the internal basecase
%}
% X = [ Fij PC PB EB PG PA]', 
% dimension-wise: [ N_branch N_genOn N_battOn N_battOn N_genOn N_genOn] '
% X_0 = zeros(z1.N_branch + 3*z1.N_genOn + 2*z1.N_battOn, 1);


% for the zone 1: EB_init = 750



% store info about 'runpf' convergence


% save the whole set of produced data:



%% Step 0 for simulation: saving the data of initial values


% currently only care about 1 zone. Later do a scheduling between several


 
%{
Fij         obtained from 'results', precisely: results.branch(z1.Branch_idx, 14);
PC          here it is precomputed, but should be a deduced information
PB          deduced from control DeltaPB. It also corresponds to results.gen(z1.BattOn_idx, 2);
EB          computed based on PB and DeltaPB values
PG          computed using several variables. It also corresponds to results.gen(z1.GenOn_idx,2);
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