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

handleBasecase();

basecase = loadcase('case6468rte_zone1and2'); %mpc_ext



%% MAP
% get a map of bus id to bus index for basecase.bus
mapBus_id2idx = getMapBus_id2idx(basecase);
% while idx2id is immediate using basecase.bus
mapBus_idx2id = containers.Map(1:size(basecase.bus,1),basecase.bus(:,1));

basecase_int = ext2int(basecase);

mapBus_ext2int = basecase_int.order.bus.e2i; % 10000x1 sparse double
mapBus_int2ext = basecase_int.order.bus.i2e; % 6469x1 double



%% HOW CONVERSION WORKS
%{
In terms of conversion:
bus_id
bus_idx     using id2idx
bus_int_idx using e2i
Let MatPower do its work
then convert back:
bus_idx     using i2e
bus_id      using idx2id
%}



%% CONVERSION OF ZONE 1
% get the list of indices corresponding to where zone1_bus buses are
% recall zone1_bus =                                                  [2076 2135 2745 4720  1445 10000]'
zone1_bus_idx = getValues(mapBus_id2idx, zone1_bus);                % [2076;2135;2743;4717;1445;6469]

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

function [gen_idx, battery_idx] = findGenAndBattery(bus_zone_id, basecase)
    % Given a zone based on its buses and a basecase, 
    % return the column vectors of the indices of the generators and
    % batteries in the zone, from the basecase
    n_gen = size(basecase.gen,1);
    gen_idx = [];
    battery_idx = [];
    is_gen_or_battery_in_zone = ismember(basecase.gen(:,1),  bus_zone_id); % batteries are generators with Pg_min < 0
    
    %{
    S = sparse(is_gen_or_battery_in_zone);
    
    S2 = basecase.gen(S,:);
    %}
    % https://stackoverflow.com/questions/32903572/how-to-iterate-over-elements-in-a-sparse-matrix-in-matlab
    
    %% TODO simplify the following for loop using a sparse matrix and campare time performance
    
    for k = 1:n_gen
        % this is a generator or a battery
        if is_gen_or_battery_in_zone(k,1) == 1
            % check for a bizarre value for Pg_max
            if basecase.gen(k,9) <= 0
                disp(['this is a strange situation, gen_idx = ', k, ' has a Pg_max <= 0'])
            end
            % this is a battery
            if basecase.gen(k,10) < 0
                battery_idx(end+1,1) = k;
            % this is a generator only
            else
                gen_idx(end+1,1) = k;
            end
        end
    end
end
                
            
        
    
    
    



function bus_border_id = findBorderBus(bus_zone_id, branch_border_idx, basecase)
    % Given a zone based on its buses, the branches at the border of the
    % zone and a basecase,
    % return the column vector of the buses at the border of the zone
    %% Input:
    % bus_zone_id: zone's buses id
    % branch_border_idx: branch indices at the border of the zone
    % basecase
    %% Output:
    % bus_border_id: set of buses id at the border of the zone
    
    % number of border branches
    nbr = size( branch_border_idx,1); 
    bus_border_id = zeros(nbr,1);
    % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row) : [fbus, tbus]
    buses_of_branch_border = basecase.branch(branch_border_idx,[1,2]);
    % determine what end buses are from the zone or outside, as boolean
    is_fbus_tbus_of_branch_in_zone = ismember(buses_of_branch_border, bus_zone_id);
    for row = 1:nbr
        % error if a branch does not have exactly 1 end bus inside the zone
        if is_fbus_tbus_of_branch_in_zone(row,1) + is_fbus_tbus_of_branch_in_zone(row,2) ~= 1
            disp(['Error: branch ', num2str(branch_border_idx(row,1)),' does not have exactly 1 end bus inside the zone, check branch_border_idx is correct'])
            return
        % fbus within zone, hence tbus outside
        elseif is_fbus_tbus_of_branch_in_zone(row,1)==1
            bus_border_id(row,1) = buses_of_branch_border(row,2);
        % tbus within zone, hence fbus outside
        else
            bus_border_id(row,1) = buses_of_branch_border(row,1);
        end
    end
    % return the set, so no repetition, in sorted order
    bus_border_id = unique(bus_border_id);
end
    



function [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(bus_zone_id, basecase)
    % Given a zone with its buses id, plus the basecase, return the column
    % vectors of the branch indices in the basecase, of the branches within the zone and the branches at its
    % border, i.e. both end buses within the zone and only 1 end bus within
    % the zone respectively
    %% Input:
    % bus_zone_id: zone's buses id
    % basecase
    %% Output:
    % branch_inner_idx: inner branches idx, for the basecase
    % branch_border_idx: border branches idx, for the basecase
    
    branch_inner_idx = [];
    branch_border_idx = [];
    % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row) : [fbus, tbus]
    buses_of_branch = basecase.branch(:,[1 2]);
    % determine what end buses are from the zone or outside, as boolean
    is_fbus_tbus_of_branch_in_zone = ismember(buses_of_branch, bus_zone_id);
    % sum booleans per branch :fbusIn + tBusIn, to get the number of end buses of the branch within the zone
    nb_of_buses_of_branch_in_zone = sum(is_fbus_tbus_of_branch_in_zone')'; % notice the ', as the sum is done by column
    % Sort each branch in its corresponding category
    for row = 1:size(buses_of_branch,1)
        switch nb_of_buses_of_branch_in_zone(row)
            % the branch is within the zone as it is connecting 2 inner buses
            case 2
                branch_inner_idx(end+1,1) = row;
            % the branch connects a inner bus with an outer bus
            case 1
                branch_border_idx(end+1,1) = row;
            % the branch is outside the zone
            otherwise
                % not to be considered
        end
    end
end







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