numberOfZones = 1;

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



%% MAP
% get a map of bus id to bus index for basecase.bus
mapBus_id2idx = getMapBus_id2idx(basecase);
% while idx2id is immediate using basecase.bus
mapBus_idx2id = containers.Map(1:size(basecase.bus,1),basecase.bus(:,1));

basecase_int = ext2int(basecase);

[isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecase_int);

mapBus_ext2int = basecase_int.order.bus.e2i; % 10000x1 sparse double
mapBus_int2ext = basecase_int.order.bus.i2e; % 6469x1 double



%% HOW CONVERSION WORKS
%{
In terms of conversion:
bus_id
bus_idx     using id2idx
bus_int_idx using e2i      notice that bus_int_id = bus_int_idx
Let MatPower do its work
then convert back:
bus_idx     using i2e
bus_id      using idx2id
%}



%% CONVERSION OF ZONE 1
% get the list of indices corresponding to where zone1_bus buses are
% recall zone1_bus =                                                  [1445 2076 2135 2745 4720 10000]'
zone1_bus_idx = getValues(mapBus_id2idx, zone1_bus);                % [1445;2076;2135;2743;4717;6469]

zone1_bus_int_idx = mapBus_ext2int(zone1_bus_idx,1);                % [1445;2076;2135;2741;4714;6462]
zone1_bus_back_idx = mapBus_int2ext(zone1_bus_int_idx);             % [1445;2076;2135;2743;4717;6469]
zone1_bus_back_id = getValues(mapBus_idx2id,zone1_bus_back_idx);    % [1445;2076;2135;2745;4720;10000]

% TODO: investigate why when zone1_bus is a row vector, some resulting
% variables remain column vectors and not all variables become row vectors
% too


%get the matrix corresponding to the subset of basecase.bus of zone 1
corresponding_zone1_bus_idx = basecase.bus(zone1_bus_idx,:);

%% CONVERSION OF ZONE 2
% recall zone2_bus =                                                  [2506 4169 4546 4710 4875 4915]'
zone2_bus_idx = getValues(mapBus_id2idx, zone2_bus);                % [2505;4167;4543;4707;4872;4912]
zone2_bus_int_idx = mapBus_ext2int(zone2_bus_idx,1);                % [2504;4165;4540;4704;4869;4909]
zone2_bus_back_idx = mapBus_int2ext(zone2_bus_int_idx);             % [2505;4167;4543;4707;4872;4912]
zone2_bus_back_id = getValues(mapBus_idx2id,zone2_bus_back_idx);    % [2506;4169;4546;4710;4875;4915]




zone1 = Zone(zone1_bus, basecase, basecase_int, mapBus_id2idx, mapBus_idx2id);
[zone1_branch_inner_idx, zone1_branch_border_idx] = findInnerAndBorderBranch(zone1_bus, basecase);
zone1_bus_border_id = findBorderBus(zone1_bus, zone1_branch_border_idx, basecase);
[zone1_gen_idx, zone1_battery_idx] = findGenAndBattery(zone1_bus, basecase);





zone2 = Zone(zone2_bus, basecase, basecase_int, mapBus_id2idx, mapBus_idx2id);
[zone2_branch_inner_idx, zone2_branch_border_idx] = findInnerAndBorderBranch(zone2_bus, basecase);
zone2_bus_border_id = findBorderBus(zone2_bus, zone2_branch_border_idx, basecase);


a = 1;


%% USEFUL FUNCTION


    











function handleBasecase()
    b1 = exist('case6468rte_mod.m','file') == 2; % initial basecase provided by Jean
    b2 = exist('case6468rte_zone1.mat','file') == 2; % updated basecase for zone 1
    b3 = exist('case6468rte_zone1and2.mat','file') == 2; % updated basecase for zone 1 & 2
    b_tot = 4*b3 + 2*b2 + b1;
    switch b_tot
        % basecase includes zone 1 and zone 2
        case {4, 5, 6, 7}
            return
        % basecase includes zone 1 but not zone 2
        case {2, 3}
            % TODO
            return
        % basecase does not include zone 1 nor zone 2, but the initial basecase
        case {1}
            % so compute the updated basecase
            updateCaseForZone1();
            updateCaseForZone2();
        otherwise
            disp("ERROR: Both case6468rte_mod2.mat and case6468rte_mod.mat are missing, can't do anything with no basecase")
    end
end