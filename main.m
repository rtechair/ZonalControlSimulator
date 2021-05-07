numberOfZones = 2;

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
% TODO: maybe the maps can be created as sparse matrices only and no
% containers.Map require to be handle, plus this would avoid creating
% associated functions
% get a map of bus id to bus index for basecase.bus and vice versa
[mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase);


basecase_int = ext2int(basecase);

[isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecase_int);

if isBusDeleted
    disp('a bus has been deleted, nothing has been made to handle this situation, the code should not work')
end
if isBranchDeleted
    disp('a branch has been deleted, nothing has been made to handle this situation, the code should not work')
end


mapBus_id_e2i = basecase_int.order.bus.e2i; % sparse matrix
mapBus_id_i2e = basecase_int.order.bus.i2e; % continuous indexing matrix

% TODO?
%[mapBus_idx_e2i,mapBus_idx_i2e] = getMapBus_idx_e2i_i2e(basecase_int,mapBus_id2idx, mapBus_idx2id, mapBus_id_e2i, mapBus_id_i2e);


[mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getMapGenOn_idx_e2i_i2e(basecase_int);

%% HOW CONVERSION WORKS

% BUS
%{
In terms of conversion:
bus_id
bus_idx     using mapBus_id2idx
bus_id_int using 
/ bus_idx_int as they are both the same due to matpower modifications
Then Matpower does its work


then convert back:
bus_id_back using basecase_int.order.bus.i2e (mapBus_int2ext)
bus_idx_back using mapBus_idx2id

TODO : TODELETE bus_int_idx using mapBus_ext2int      notice that bus_int_id = bus_int_idx
%}

% BRANCH
%{
no map is required regarding the branches, the branches are accessed through their indices,
if no branch is deleted during the internal conversion, then the branch will remain as the same index
TODO check branches are not moved during the conversion.
The branches are accessed through their idx, they do not have an id.
Additionnally, the idx is more important than fbus and tbus
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
[zone1_gen_idx, zone1_battery_idx] = findGenAndBattery(zone1_bus, basecase);

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
% recall zone1_gen_idx =                                [1297;1299;1300;1301]
% recall zone1_battery_idx =                                             1298

zone1_gen_int_idx = mapGenOn_idx_e2i(zone1_gen_idx); %          [401;403;404;405]
zone1_battery_int_idx = mapGenOn_idx_e2i(zone1_battery_idx); %   402

zone1_gen_back_idx = mapGenOn_idx_i2e(zone1_gen_int_idx); %     [1297;1299;1300;1301]
zone1_battery_back_idx = mapGenOn_idx_i2e(zone1_battery_int_idx); % 1298
    



%% CONVERSION OF ZONE 2
% recall zone2_bus =                                    [2506 4169 4546 4710 4875 4915]'
zone2_bus_idx = mapBus_id2idx(zone2_bus); %             [2505;4167;4543;4707;4872;4912]               
zone2_bus_int_id = mapBus_id_e2i(zone2_bus); %          [2505;4167;4543;4707;4872;4912]        
zone2_bus_back_id = mapBus_id_i2e(zone2_bus_int_id); %  [2506;4169;4546;4710;4875;4915]   
zone2_bus_back_idx = mapBus_id2idx(zone2_bus_back_id);% [2505;4167;4543;4707;4872;4912]


%zone2 = Zone(zone2_bus, basecase, basecase_int, mapBus_id2idx, mapBus_idx2id);
[zone2_branch_inner_idx, zone2_branch_border_idx] = findInnerAndBorderBranch(zone2_bus, basecase);
zone2_bus_border_id = findBorderBus(zone2_bus, zone2_branch_border_idx, basecase);

% recall zone2_bus_border_id =                                          [347;1614;2093;4170;4236;4548]                                       
zone2_bus_border_idx = mapBus_id2idx(zone2_bus_border_id); %            [347;1614;2093;4168;4234;4545]       
zone2_bus_border_int_id = mapBus_id_e2i(zone2_bus_border_id); %         [347;1614;2093;4168;4234;4545]    
zone2_bus_border_back_id = mapBus_id_i2e(zone2_bus_border_int_id); %    [347;1614;2093;4170;4236;4548]  
zone2_bus_border_back_idx = mapBus_id2idx(zone2_bus_border_back_id); %  [347;1614;2093;4168;4234;4545]

% the rest of the info could be computed as done with zone 1

%% Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k-tau)+Dd(k)
%{
x = [Fij Pc Pb Eb Pg ]'     uc = DeltaPc      ub =DeltaPb    w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
cf Powertech paper
%}

[n_bus, n_branch, n_gen, n_batt] = findBasecaseDimension(basecase); % [6469, 9001, 1228, 77]
[n_bus_int, n_branch_int, n_gen_int, n_batt_int] = findBasecaseDimension(basecase_int); % [6469, 9001, 396, 13]

[n_bus_zone1, n_branch_zone1, n_gen_zone1, n_batt_zone1] = findZoneDimension(zone1_bus, zone1_branch_inner_idx,zone1_gen_idx, zone1_battery_idx);

zone1_sampling_time = 5; % in sec
batt_cst_power_reduc = ones(n_batt_zone1,1); % TODO: needs to be changed afterwards, with each battery coef
% Zone 1
[A,Bc,Bb,Dg,Dt,Da,x,u,d] = fromMatpowerToABD(basecase_int, zone1_bus, ...
    zone1_branch_inner_idx, zone1_gen_idx, zone1_battery_idx,...
    zone1_sampling_time, batt_cst_power_reduc);
    