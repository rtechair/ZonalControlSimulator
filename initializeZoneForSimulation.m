function zone = initializeZoneForSimulation(basecase, zone_bus_id, simulationTimeStep, ...
    battConstrPowerReduc, durationSimulation, samplingTime, delayBattSec, delayCurtSec, ...
   windDataName, mapBus_id_e2i, mapGenOn_idx_e2i)


%% Creation of zone

zone = Zone(basecase, zone_bus_id);

%% Information for simulation

zone.SimulationTime = simulationTimeStep;

zone.BattConstPowerReduc = battConstrPowerReduc;

zone.Duration = durationSimulation;
zone.SamplingTime = samplingTime;

zone.DelayBattSec = delayBattSec;
zone.DelayCurtSec = delayCurtSec;

%% Set the interior id and indices related to the internal basecase, for the zone

setInteriorIdAndIdx( zone, mapBus_id_e2i, mapGenOn_idx_e2i);

%% Simulation initialization

zone.initializeDynamicVariables;

%% Compute available power (PA) and delta PA using real data
% all PA and DeltaPA values are computed prior to the simulation

zone = getPAandDeltaPA(zone, basecase, windDataName);

%% Initialization
% create the PG variable and define PG(1)
zone = setInitialPG(zone);

