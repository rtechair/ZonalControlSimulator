numberOfZones = 1;

zone1_bus = [2076 2135 2745 4720  1445 10000]';
zone2_bus = [];

zones_bus = {zone1_bus, zone2_bus};

% Check the basecase is available or computable
if exist('case6468rte_mod2.mat','file') ~= 2
    % the file does not exist
    if exist('case6468rte_mod.m','file') ~= 2
        % this one neither
        disp("ERROR: Both case6468rte_mod2.mat and case6468rte_mod.mat are missing, can't do anything with no basecase")
    else
        % compute it using the 1st one
        updateCase()
    end
end

basecase = loadcase('case6468rte_mod2'); %mpc_ext

%%MAP
% get a map of bus id to bus index for basecase.bus
mapBus_id2idx = getMapBus_id2idx(basecase);
% while idx2id is immediate using basecase.bus
mapBus_idx2id = containers.Map(1:size(basecase.bus,1),basecase.bus(:,1));

%%CONVERSION
% get the list of indices corresponding to where zone1_bus buses are
% recall zone1_bus = [2076 2135 2745 4720  1445 10000]'
zone1_bus_idx = cell2mat(values(mapBus_id2idx, num2cell(zone1_bus))); % [2076;2135;2743;4717;1445;6469]

%this get the matrix corresponding to the subset of basecase.bus of zone 1
corresponding_zone1_bus_idx = basecase.bus(zone1_bus_idx,:);


basecase_int = ext2int(basecase);

% NOT WORKING zone1_bus_int = e2i_data(basecase_int, corresponding_zone1_bus_idx, 'bus');

mapBus_ext2int = basecase_int.order.bus.e2i; % 10000x1 sparse double
mapBus_int2ext = basecase_int.order.bus.i2e; % 6469x1 double

zone1_bus_int_idx = mapBus_ext2int(zone1_bus_idx,1); %mapBus_ext2int(zone1_bus_idx,:)

zone1_bus_back_idx = mapBus_int2ext(zone1_bus_int_idx);

zone1_bus_back_id = cell2mat(values(mapBus_idx2id,num2cell(zone1_bus_back_idx)));
% mapBus_idx2id(zone1_bus_back_idx);

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

% https://matpower.org/docs/ref/matpower7.1/lib/e2i_data.html
% https://matpower.org/docs/ref/matpower7.1/lib/e2i_field.html
% https://matpower.org/docs/ref/





a = 1;


% creating class: https://www.mathworks.com/help/matlab/matlab_oop/create-a-simple-class.html