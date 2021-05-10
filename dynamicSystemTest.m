% test system dynamic

% basecase 1
basecase1 = loadcase('case6468rte_zone1and2');
basecase1_int = ext2int(basecase1);
    % zone 1
zone1_bus = [1445 2076 2135 2745 4720 10000]';
[zone1_branch_inner_idx, ~] = findInnerAndBorderBranch(zone1_bus, basecase1);
[zone1_gen_idx, zone1_battery_idx] = findGenAndBattOnInZone(zone1_bus, basecase1);
[mapGenOn_idx_e2i, ~] = getMapGenOn_idx_e2i_i2e(basecase1_int);
zone1_sampling_time = 5; % arbitrary
batt_cst_power_reduc = 1; % arbitrary

[A,Bc,Bb,Dg,Dt,Da] = dynamicSystem(basecase1_int, zone1_bus, ...
    zone1_branch_inner_idx, zone1_gen_idx, zone1_battery_idx, mapGenOn_idx_e2i,...
    zone1_sampling_time, batt_cst_power_reduc);

data = load('alessioABCmatrices.mat');


%{
[A,Bc,Bb,Dg,Dt,Da] = dynamicSystem(basecase1_int, zone1_bus, ...
    zone1_branch_inner_idx, zone1_gen_idx, zone1_battery_idx, mapGenOn_idx_e2i,...
    zone1_sampling_time, batt_cst_power_reduc);
data = load('alessioABCmatrices.mat');
%}

%% Test 1: zone 1 - A
assert( isequal(A, data.A), 'incorrect A')

%% Test 2: zone 1 - Bc
assert( isequal(Bc, data.Bc), 'incorrect Bc')

%% Test 3: zone 1 - Bb
assert( isequal(Bb, data.Bb), 'incorrect Bb')

%% Test 4: zone 1 - Dg
assert( isequal(Dg, data.Dg), 'incorrect Dg')

%% Test 5: zone 1 - Dt
assert( isequal(Dt, data.Dn), 'incorrect Dt') % Alessio called it 'Dn' initially

%% Test 6: zone 1 - Da
assert( isequal(Da, data.Da), 'incorrect Da')