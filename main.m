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
%zone1_busBorder = [1446;2504;2694;4231;5313;5411];
%zone1_bus_id = [zone1_bus_id ; zone1_busBorder];

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
windDataName= 'tauxDeChargeMTJLMA2juillet2018.txt';
durationSimulation = 600;
branchPowerLimit = 45;

[basecase, basecaseInt, mapBus_id2idx, mapBus_idx2id, ...
    mapBus_id_e2i, mapBus_id_i2e, mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getBasecaseAndMap(basecaseName);

% TODO handle if branches or buses are deleted for other instances.
% TODO crash test, add a island bus, not connected to the rest of the network
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

zone1 = Zone(basecase, zone1_bus_id);



%% Information about zone 1 or its simulation

zone1.SimulationTime = 1; 
z1_cb = 0.001; % conversion factor for battery power output
zone1.BattConstPowerReduc = z1_cb * ones(zone1.NumberBattOn,1); % TODO: needs to be changed afterwards, with each battery coef

zone1.Duration = durationSimulation;
zone1.SamplingTime = 5;

zone1.DelayBattSec = 1;
zone1.DelayCurtSec = 45;


%% Set the interior id and indices related to the internal basecase, for the zone

setInteriorIdAndIdx( zone1, mapBus_id_e2i, mapGenOn_idx_e2i);


%% Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k-tau)+Dd(k)
%{
x = [Fij Pc Pb Eb Pg Pa ]'     uc = DeltaPc      ub =DeltaPb    w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
cf Powertech paper
%}

setDynamicSystem(zone1, basecaseInt, mapBus_id_e2i, mapGenOn_idx_e2i);

%% Simulation initialization


zone1.initializeDynamicVariables;

%% Compute available power (PA) and delta PA using real data
% all PA and DeltaPA values are computed prior to the simulation

zone1 = getPAandDeltaPA(zone1, basecase, windDataName);

%z2 = getPAandDeltaPA(z2, basecase, 'tauxDeChargeMTJLMA2juillet2018.txt');

%% Initialize PC and DeltaPC

% the following line is now a comment, as a limiter/ controller is used
% instead
% zone1 = setDeltaPC(zone1, [1/7 1/3 2/3], 0.2, zone1.MaxPG); 


%PC(1) = 0; Other PC values will be computed online with DeltaPC values provided by the MPC

%z2 = setDeltaPC(z2, [1/7 1/3 2/3], 0.2, z2.MaxPG); 

%PB(1) = 0; Other PB values will be computed online with DeltaPB values provided by the MPC

% EB(1) = 0; Other EB values will be computed online
% for the zone 1: EB_init = 750 in Alessio's code

%% Initialization
% Define PG(1)
zone1 = setInitialPG(zone1);


% matpower option for the 'runpf' function configuration, see help runpf and help mpoption
% https://matpower.org/docs/ref/matpower7.1/lib/mpoption.html
mpopt = mpoption('model', 'AC', ... default = 'AC', select 'AC' or 'DC'
        'verbose', 0, ...  default = 1, select 0, 1, 2, 3. Select 0 to hide text
        'out.all', 0); % default = -1, select -1, 0, 1. Select 0 to hide text
    
% save the power flow results, i.e. take a snapshot of the whole electric
% network for each time frame of the simulation
cellOfResults = cell(1,zone1.NumberIteration+1);
    

%% Initialization

% State(1) is already defined from the variables initilization, except
% Fij(1). DeltaPT(0) is not necessary for the rest of the simulation, so let it remain at value = 0

% update the generator productions and battery injections in the matpower case structs 
[basecase, basecaseInt] = updateGeneration(basecase, basecaseInt, zone1, 1);
[basecase, basecaseInt] = updateRealPowerBatt(basecase, basecaseInt, zone1, 1);
% run the Power Flow
results = runpf(basecaseInt, mpopt);
% Extract the power flows in the zone
zone1.Fij(:,1) = results.branch(zone1.BranchIdx, 14);
% store the snapshot of the whole electric network 
 cellOfResults{1} = results;

 
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

for step = 2:zone1.NumberIteration+1
    
    %% CONTROL from the controller 
    
    [DeltaPB, DeltaPC] = limiter(zone1, step, branchPowerLimit);
    zone1.DeltaPB(:,step-1) = DeltaPB;
    zone1.DeltaPC(:,step-1) = DeltaPC;
    
       
    [basecase, basecaseInt, zone1, cellOfResults, ~] = simulationIteration(...
        basecase, basecaseInt, zone1, step, cellOfResults, mpopt, 0, 0); % currently the last 2 inputs are not used in the function
end

%% Graphic representation

simulation = copy(zone1);

isFigurePlotted = true;

if isFigurePlotted
    figureStateGen = plotStateGenOn(basecase, simulation);

    figureDeltaGen = plotDeltaGenOn(basecase, simulation);

    figureFlowBranch = plotFlowBranch(basecase, simulation);
    
    graphZoneAndBorder = graphStatic(basecase, [simulation.BranchIdx; simulation.BranchBorderIdx]);
    P = plotWithLabel(graphZoneAndBorder, basecase, simulation.BusId, simulation.GenOnIdx, simulation.BattOnIdx);
end

function [deltaPB, deltaPC] = limiter(zone, step, branchPowerLimit)
    isAnyBranchPowerFlowOver80PercentOfLimitAtStepMinusOne = any( abs(zone.Fij(:,step-1)) > branchPowerLimit);
    isAllBranchPowerFlowUnder60PercentAtStepMinusOne = all( abs(zone.Fij(:,step-1)) < branchPowerLimit);
    if isAnyBranchPowerFlowOver80PercentOfLimitAtStepMinusOne
        deltaPC(1:zone.NumberGenOn,1) = 0.2*branchPowerLimit;
    elseif isAllBranchPowerFlowUnder60PercentAtStepMinusOne
            deltaPC(1:zone.NumberGenOn,1) = - 0.1*branchPowerLimit;
    else
        deltaPC(1:zone.NumberGenOn,1) = 0;
    end
    deltaPB(1:zone.NumberBattOn,1) = 0;
end
           
        
    
    
    

function  [basecase, basecaseInt, zone, cellOfResults, state_step, disturbance_step, control_multiPreviousSteps] = simulationIteration(...
    basecase, basecaseInt, zone, step, cellOfResults, mpopt, deltaPC_previousStep, deltaPB_previousStep)
    % from the previous step state, and the previous step control, update
    % the system state to time 'step'. Complement the system state with the
    % simulated value of power flow on zone's branches Fij at time 'step'
    % and get the disturbance from the outside DeltaPT at time 'step' - 1.
    
    %% currently unused and unassigned
    state_step = 0;
    disturbance_step = 0;
    control_multiPreviousSteps = 0;
    
    deltaPC_previousStep = 0;
    deltaPB_previousStep = 0;
    
    %% Function starts here until previous outputs are correctly set up and used
    % DeltaPG(step-1)
    zone = getDeltaPG_k(zone,step-1);
    
    %% Update STATE using the dynamical model, to get the current state, i.e. state at time 'step'
    % X = [ Fij PC PB EB PG PA]'
    % dimension-wise: [ NumberBranch NumberGenOn NumberBattOn NumberBattOn NumberGenOn NumberGenOn]'
    
    % State at time 'step' using the dynamic model, except Fij
    zone = updateStateToStep(zone, step);
    
    %% Update the internal basecase framing the electric system at time 'step' 
    %{
    the current snapshot of the electric network uses the generations and battery injections from 
    the previous step, thus the basecases require to be modified to portray the correct state 
    of the system, in order to do the power flow simulation
    %}
    [basecase, basecaseInt] = updateGeneration(basecase, basecaseInt, zone, step); % write PG(k) in the basecaseInt
    [basecase, basecaseInt] = updateRealPowerBatt(basecase, basecaseInt, zone, step); % write PB(k) in the basecaseInt
    
    %% Run the Power Flower corresponding to to time 'step'
    %{
    Regarding the functioning: the 'runpf' computation is done using the internal basecase 'basecase_int' data.
    However, the result'results' are returned using the external basecase 'basecase' data.
    help: https://matpower.org/docs/ref/matpower7.1/lib/runpf.html
    %}
    results = runpf(basecaseInt, mpopt); 
    
    % Store the information regarding the simulation
    cellOfResults{step} = results;
    
    %% Extract the results from the Power Flow
    % Extract Fij column 14 of results.branch is PF: real power injected at "from" end bus
    % as explained previously on 'runpf' functioning, notice 'zone.Branch_idx' is used, not 'zone.Branch_int_idx'
    zone.Fij(:,step) = results.branch(zone.BranchIdx, 14);
    
     % Extract PT(step)
    zone = getPT_k(results, zone, step);
    
    % Compute DeltaPT(step-1)
    zone.DeltaPT(:,step-1) = zone.PT(:,step) - zone.PT(:, step-1);

end

%% Scheduling between several zones

% TODO currently only care about 1 zone. Later do a scheduling between several

% function zone = updatePC(PC_k, DeltaPC_k, delayCurt)
    

%(DeltaPC_k, DeltaPB_k, DeltaPA_k, Fij_k, PC_k, PB_k, EB_k, PG_k, PA_k,)
    
