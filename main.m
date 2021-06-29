%% BASECASE

% if the basecase is not correctly updated, update it
handleBasecaseForZone1And2();

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

%% Load data and create zones for simulation

loadDataZoneVG

zone1 = initializeZoneForSimulation(basecase, zoneVG_bus_id, zoneVG_simulationTimeStep, ...
    zoneVG_battConstPowerReduc, durationSimulation, zoneVG_SamplingTime, zoneVG_DelayBattSec, ...
    zoneVG_DelayCurtSec, windDataName, mapBus_id_e2i, mapGenOn_idx_e2i, zoneVG_startingIterationOfWindForGen);

zoneVG_coefIncreaseCurt = 0.1;
zoneVG_coefDecreaseCurt = 0.01;
zoneVG_coefLowerThreshold = 0.6;
zoneVG_coefUpperThreshold = 0.8;
limiterVG = Limiter(branchPowerLimit, zoneVG_numberOfGenerators, zoneVG_numberOfBatteries, ...
    zoneVG_coefIncreaseCurt, zoneVG_coefDecreaseCurt,...
    zoneVG_coefLowerThreshold, zoneVG_coefUpperThreshold, zone1.DelayCurt);

loadDataZoneVTV

zone2 = initializeZoneForSimulation(basecase, zoneVTV_bus_id, zoneVTV_simulationTimeStep, ...
    zoneVTV_battConstPowerReduc, durationSimulation, zoneVTV_SamplingTime, zoneVTV_DelayBattSec, ...
    zoneVTV_DelayCurtSec, windDataName, mapBus_id_e2i, mapGenOn_idx_e2i, zoneVTV_startingIterationOfWindForGen);


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
   
    currentBranchFlow = zone1.Fij(:,step-1);
    
    limiterVG.computeControls(currentBranchFlow);
    zone1.DeltaPB(:,step-1) = limiterVG.getBatteryInjectionControl();
    zone1.DeltaPC(:,step-1) = limiterVG.getCurtailmentControl();
       
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
    
