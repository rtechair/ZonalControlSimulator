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

zone1_bus = [1445 2076 2135 2745 4720 10000]';
zone1_bus_name = ["CR" "GR" "GY" "MC" "TR" "VG"];

zone2_bus = [2506 4169 4546 4710 4875 4915]';
zone2_bus_name = ["LAZ" "SIS" "SPC" "TRE" "VTV" "VEY"];


zone3_bus = [];

zones_bus = {zone1_bus, zone2_bus, zone3_bus};

%% BASECASE

% if the basecase is not correctly updated, update it
handleBasecase();

basecase = loadcase('case6468rte_zone1and2'); %mpc_ext

% crash test, add a island bus, not connected to the rest of the network
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
[mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase);
mapBus_id_e2i = basecase_int.order.bus.e2i; % sparse matrix
mapBus_id_i2e = basecase_int.order.bus.i2e; % continuous indexing matrix

% online gen map
[mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getMapGenOn_idx_e2i_i2e(basecase_int);

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
if no branch is deleted during the internal conversion, then the branch will remain as the same index
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

% TODO: ensure zone1_bus is a column vector

% create the object associated to the zone
% TODO: the Zone object is not working anymore as based on the
% containers.Map structure

% get the rest of the info about the zone
[zone1_branch_inner_idx, zone1_branch_border_idx] = findInnerAndBorderBranch(zone1_bus, basecase);
zone1_bus_border_id = findBorderBus(zone1_bus, zone1_branch_border_idx, basecase);
[zone1_gen_idx, zone1_battery_idx] = findGenAndBattOnInZone(zone1_bus, basecase);

% BUS
% recall zone1_bus =                                    [1445 2076 2135 2745 4720 10000]'
zone1_bus_idx = mapBus_id2idx(zone1_bus); %             [1445;2076;2135;2743;4717;6469]
zone1_bus_int_id = mapBus_id_e2i(zone1_bus); %          [1445;2076;2135;2743;4717;6469]
zone1_bus_back_id = mapBus_id_i2e(zone1_bus_int_id); %  [1445;2076;2135;2745;4720;10000]
zone1_bus_back_idx = mapBus_id2idx(zone1_bus_back_id);% [1445;2076;2135;2743;4717;6469]

% recall zone1_bus_border_id =                                          [1446;2504;2694;4231;5313;5411]   
zone1_bus_border_idx = mapBus_id2idx(zone1_bus_border_id); %            [1446;2503;2692;4229;5310;5408]
zone1_bus_border_int_id = mapBus_id_e2i(zone1_bus_border_id); %         [1446;2503;2692;4229;5310;5408]
zone1_bus_border_back_id = mapBus_id_i2e(zone1_bus_border_int_id); %    [1446;2504;2694;4231;5313;5411]
zone1_bus_border_back_idx = mapBus_id2idx(zone1_bus_border_back_id); %  [1446;2503;2692;4229;5310;5408]

% BRANCH
%{
nothing to change here,
if no branch is deleted during the internal conversion by matpower then
 zone1_branch_inner_idx = zone1_branch_inner_int_idx
 zone1_branch_border_idx = zone1_branch_border_int_idx
%}

% GEN
% recall zone1_gen_idx =                                    [1297;1299;1300;1301]
zone1_gen_int_idx = mapGenOn_idx_e2i(zone1_gen_idx); %      [401;403;404;405]
zone1_gen_back_idx = mapGenOn_idx_i2e(zone1_gen_int_idx); % [1297;1299;1300;1301]

% recall zone1_battery_idx =                                        1298
zone1_battery_int_idx = mapGenOn_idx_e2i(zone1_battery_idx); %      402
zone1_battery_back_idx = mapGenOn_idx_i2e(zone1_battery_int_idx); % 1298

%% CONVERSION OF ZONE 2
% BUS
% recall zone2_bus =                                    [2506 4169 4546 4710 4875 4915]'
zone2_bus_idx = mapBus_id2idx(zone2_bus); %             [2505;4167;4543;4707;4872;4912]               
zone2_bus_int_id = mapBus_id_e2i(zone2_bus); %          [2505;4167;4543;4707;4872;4912]        
zone2_bus_back_id = mapBus_id_i2e(zone2_bus_int_id); %  [2506;4169;4546;4710;4875;4915]   
zone2_bus_back_idx = mapBus_id2idx(zone2_bus_back_id);% [2505;4167;4543;4707;4872;4912]

%zone2 = Zone(zone2_bus, basecase, basecase_int, mapBus_id2idx, mapBus_idx2id);
[zone2_branch_inner_idx, zone2_branch_border_idx] = findInnerAndBorderBranch(zone2_bus, basecase);
zone2_bus_border_id = findBorderBus(zone2_bus, zone2_branch_border_idx, basecase);
[zone2_gen_idx, zone2_battery_idx] = findGenAndBattOnInZone(zone2_bus, basecase);

% recall zone2_bus_border_id =                                          [347;1614;2093;4170;4236;4548]                                       
zone2_bus_border_idx = mapBus_id2idx(zone2_bus_border_id); %            [347;1614;2093;4168;4234;4545]       
zone2_bus_border_int_id = mapBus_id_e2i(zone2_bus_border_id); %         [347;1614;2093;4168;4234;4545]    
zone2_bus_border_back_id = mapBus_id_i2e(zone2_bus_border_int_id); %    [347;1614;2093;4170;4236;4548]  
zone2_bus_border_back_idx = mapBus_id2idx(zone2_bus_border_back_id); %  [347;1614;2093;4168;4234;4545]

% GEN
% recall zone2_gen_idx = [466;1302;1303;1304] notice the gen_idx = 466 is
% in the zone but not online so not considered
zone2_gen_int_idx = mapGenOn_idx_e2i(zone2_gen_idx); % [406;407;408]     
zone2_gen_back_idx = mapGenOn_idx_i2e(zone2_gen_int_idx);

% zone2_battery_idx = 1305
zone2_battery_int_idx = mapGenOn_idx_e2i(zone2_battery_idx); %  409
zone2_battery_back_idx = mapGenOn_idx_i2e(zone2_battery_int_idx); % 1305

%% Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k-tau)+Dd(k)
%{
x = [Fij Pc Pb Eb Pg ]'     uc = DeltaPc      ub =DeltaPb    w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
cf Powertech paper
%}

[n_bus, n_branch, n_gen, n_batt] = findBasecaseDimension(basecase); % [6469, 9001, 1228, 77]
[n_bus_int, n_branch_int, n_gen_int, n_batt_int] = findBasecaseDimension(basecase_int); % [6469, 9001, 396, 13]

% Zone 1
[n_bus_zone1, n_branch_zone1, n_gen_zone1, n_batt_zone1] = findZoneDimension(zone1_bus, zone1_branch_inner_idx,zone1_gen_idx, zone1_battery_idx);

zone1_sampling_time = 5; % in sec
batt_cst_power_reduc = ones(n_batt_zone1,1); % TODO: needs to be changed afterwards, with each battery coef

[A,Bc,Bb,Dg,Dt,Da] = dynamicSystem(basecase_int, zone1_bus, ...
    zone1_branch_inner_idx, zone1_gen_idx, zone1_battery_idx, mapBus_id_e2i, mapGenOn_idx_e2i,...
    zone1_sampling_time, batt_cst_power_reduc);

