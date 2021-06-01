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

% load and work on basecase
basecaseName = 'case6468rte_zone1and2';

[basecase, basecaseInt, mapBus_id2idx, mapBus_idx2id, ...
    mapBus_id_e2i, mapBus_id_i2e, mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getBasecaseAndMap(basecaseName);

% crash test, add a island bus, not connected to the rest of the network
% issue is: matpower does not delete this bus, 
% basecase_int.order.bus.status.off is empty
% do another crash on the case9.m
%{
basecase = addBus(basecase,99999,    2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);

basecase = addBus(basecase,99998,    2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);
basecase.branch(end+1,:) = [ 99998, 99999, 0.2, 0.4, 0.5, 0, 0, 0, 1, 0, 1, 0, 0];
%}

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

the branches are accessed through their idx, they do not have an id.
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

%% Creation of zone

z1 = Zone(basecase, zone1_bus_id);
z2 = Zone(basecase, zone2_bus_id);

setInteriorIdAndIdx( z1, mapBus_id_e2i, mapGenOn_idx_e2i);
z2 = setInteriorIdAndIdx( z2, mapBus_id_e2i, mapGenOn_idx_e2i);

%% Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k-tau)+Dd(k)
%{
x = [Fij Pc Pb Eb Pg Pa ]'     uc = DeltaPc      ub =DeltaPb    w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
cf Powertech paper
%}


z1.SimulationTime = 1; 
z1_cb = 0.001; % conversion factor for battery power output
z1.BattConstPowerReduc = z1_cb * ones(z1.NumberBattOn,1); % TODO: needs to be changed afterwards, with each battery coef


setDynamicSystem(z1, basecaseInt, mapBus_id_e2i, mapGenOn_idx_e2i);

 
% Zone 2

z2.SimulationTime = 1; % sec, TODO look at the previous main, Sampling_time = 5 and simulation_time_unit = 1, I do not understand
z2_cb = 0.001; % conversion factor for battery power output
z2.BattConstPowerReduc = z2_cb * ones(z2.NumberBattOn,1); % TODO: needs to be changed afterwards, with each battery coef

%{
z2 = setDynamicSystem(z2, basecase_int, z2.Bus_id, z2.Branch_idx, z2.GenOn_idx, z2.BattOn_idx,...
                mapBus_id_e2i, mapGenOn_idx_e2i, z2.Simulation_time_unit, z2.Batt_cst_power_reduc);
%}


%% Simulation initialization

z1.Duration = 600;
z1.SamplingTime = 5;

z1.DelayBattSec = 1;
z1.DelayCurtSec = 45;

z1.initializeDynamicVariables;

%% Compute available power (PA) and delta PA using real data
% all PA and DeltaPA values are computed prior to the simulation

z1 = getPAandDeltaPA(z1, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');

%z2 = getPAandDeltaPA(z2, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');

%% Initialize PC and DeltaPC
%PC(1) = 0; Other PC values will be computed online with DeltaPC values provided by the MPC

%z1.PC = zeros(z1.NumberGenOn, z1.NumberIteration+1);

z1 = setDeltaPC(z1, [1/7 1/3 2/3], 0.2, z1.MaxPG); 

%z2.PC = zeros(z2.NumberGenOn, z2.NumberIteration+1);

%z2 = setDeltaPC(z2, [1/7 1/3 2/3], 0.2, z2.MaxPG); 

%% Initialize PB and DeltaPB
% DeltaPB has not been set previously however
%PB(1) = 0; Other PB values will be computed online with DeltaPB values provided by the MPC
%{
z1.PB = zeros(z1.NumberBattOn, z1.NumberIteration+1);
z1.DeltaPB = zeros(z1.NumberBattOn, z1.NumberIteration);

%% Initialize PG and DeltaPG
z1.PG = zeros(z1.NumberGenOn, z1.NumberIteration+1);
z1.DeltaPG = zeros(z1.NumberGenOn, z1.NumberIteration);
% Define PG(1)

%% Initialize PT and DeltaPT
z1.PT = zeros(z1.NumberBus, z1.NumberIteration+1);
z1.DeltaPT = zeros(z1.NumberBus, z1.NumberIteration);

%% Initialize EB
% EB(1) = 0; Other EB values will be computed online
z1.EB = zeros(z1.NumberBattOn, z1.NumberIteration+1);
% for the zone 1: EB_init = 750 in Alessio's code

%% Initialize Fij
z1.Fij = zeros(z1.NumberBranch, z1.NumberIteration+1);
%}
%% Initialization

z1 = setInitialPG(z1);


% matpower option for the runpf function, see help runpf and help mpoption
% https://matpower.org/docs/ref/matpower7.1/lib/mpoption.html
mpopt = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
        'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
        'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
    
cellOfResults = cell(1,z1.NumberIteration+1);
    

%% Initialization

% State(1) is already defined from the variables initilization, except
% Fij(1). DeltaPT(0) is not important, so let it remain at value = 0

[basecase, basecaseInt] = updateGeneration(basecase, basecaseInt, z1, 1);
[basecase, basecaseInt] = updateRealPowerBatt(basecase, basecaseInt, z1, 1);
results = runpf(basecaseInt, mpopt);
z1.Fij(:,1) = results.branch(z1.BranchIdx, 14);




%% Simulation using runpf of Matpower

%{
1) The simulator receives the controls DeltaPB(k) and DeltaPC(k), from the controller

2) "Receive" DeltaPA(k), i.e. take the value from the array

3) Update STATE to get STATE(k+1) except Fij

4) using PG(k+1) and PB(k+1) freshly computed, update the internal basecase

5) run the Power Flow simulation using Matpower function 'runpf'
 
6) extract from the simualtion Fij(k+1) and PT(k+1), thus DeltaPT(k).
    Fij(k+1) corresponds to results.branch(zone.Branch_idx, 14)
    PT(k+1) is obtained using the 'getPT_k' function

7) Give to the controller:
    the full STATE(k+1)
    previous CONTROL(k+1 - delay + i) for all i in [[0, delay -1 ]]


Regarding the initialization:

1) build the dynamic model in order to send it the controller which will
use it for the optimization

2) fully compute PA and DeltaPA for the whole duration, prior to the simulation
    - PA: computed using the profile data 'tauxDeCharge'
    - DeltaPA: computed using PA, based on DeltaPA(k) = PA(k+1) - PA(k)

%}

for step = 1:z1.NumberIteration
    
    %% CONTROL from the controller 
    %{
    [DeltaPB, DeltaPC] = controller(z1, step);
    z1.DeltaPB(:,step) = DeltaPB;
    z1.DeltaPC(:,step) = DeltaPC;
    %}
    
    %% Update STATE
    
    % DeltaPG(step)
    z1 = getDeltaPG_k(z1,step);
    % PC(step+1) and PG(step+1)
    if step >= z1.DelayCurt + 1
        z1.PC(:,step+1) = z1.PC(:,step)                      + z1.DeltaPC(:,step - z1.DelayCurt);
        z1.PG(:,step+1) = z1.PG(:,step) + z1.DeltaPG(:,step) - z1.DeltaPC(:,step - z1.DelayCurt);
    else
        % past commands are not known so they are considered null
        z1.PC(:,step+1) = z1.PC(:,step);
        z1.PG(:,step+1) = z1.PG(:,step) + z1.DeltaPG(:,step);
    end
    % PB(step+1) and EB(step+1)
    if step >= z1.DelayBatt + 1
        z1.PB(:,step+1) = z1.PB(:,step) + z1.DeltaPB(:,step - z1.DelayBatt);
        z1.EB(:,step+1) = z1.EB(:,step) - z1.BattConstPowerReduc*z1.SimulationTime *...
            ( z1.PB(:,step) + z1.DeltaPB(:,step - z1.DelayBatt) );
    else
        % past commands are not known so they are considered null
        z1.PB(:,step+1) = z1.PB(:,step);
        z1.EB(:,step+1) = z1.EB(:,step) - z1.BattConstPowerReduc*z1.SimulationTime * z1.PB(:,step);
    end
    
    %% Update the internal basecase framing step k+1
    [basecase, basecaseInt] = updateGeneration(basecase, basecaseInt, z1, step+1); % write PG(k+1) in the basecase_int
    [basecase, basecaseInt] = updateRealPowerBatt(basecase, basecaseInt, z1, step+1); % write PB(k+1) in the basecase_int
    
    %% Run the Power Flower corresponding to step k+1
    results = runpf(basecaseInt, mpopt); 
    
    %{
    Regarding the functioning: the 'runpf' computation is done using the internal basecase 'basecase_int' data.
    However, the result'results' are returned using the external basecase 'basecase' data.
    help: https://matpower.org/docs/ref/matpower7.1/lib/runpf.html
    %}
    
    % Store the information regarding the simulation
    cellOfResults{step} = results;
    
    %% Extract the results from the Power Flow
    % Extract Fij column 14 of results.branch is PF: real power injected at "from" end bus
    % as explained previously on 'runpf' functioning, notice 'zone.Branch_idx' is used, not 'zone.Branch_int_idx'
    z1.Fij(:,step+1) = results.branch(z1.BranchIdx, 14);
    
    % Extract PT(step+1)
    z1 = getPT_k(results, z1, step+1);
    
    % Compute DeltaPT(step)
    z1.DeltaPT(:,step) = z1.PT(:,step+1) - z1.PT(:, step);

end


%% Graphic representation

simulation = copy(z1);

isFigurePlotted = true;

if isFigurePlotted
    figureStateGen = plotStateGenOn(basecase, simulation);

    figureDeltaGen = plotDeltaGenOn(basecase, simulation);

    figureFlowBranch = plotFlowBranch(basecase, simulation);
end



% X = [ Fij PC PB EB PG PA]', 
% dimension-wise: [ N_branch N_genOn N_battOn N_battOn N_genOn N_genOn] '

%% Scheduling between several zones

% currently only care about 1 zone. Later do a scheduling between several


 

%{
    %Later for the scheduling:
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