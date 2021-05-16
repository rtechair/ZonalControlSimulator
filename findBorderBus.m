function bus_border_id = findBorderBus(basecase, bus_zone_id, branch_border_idx)
    % Given a zone based on its buses, the branches at the border of the
    % zone and a basecase,
    % return the column vector of the buses at the border of the zone
    %% Input:
    % bus_zone_id: zone's buses id
    % branch_border_idx: branch indices at the border of the zone
    % basecase
    %% Output:
    % bus_border_id: set of buses id at the border of the zone
    arguments
        basecase struct
        bus_zone_id (:,1) {mustBeInteger, mustBeNonempty, mustBusBeFromBasecase(bus_zone_id, basecase)}
        branch_border_idx (:,1) {mustBeInteger}
    end
    
    % number of border branches
    nbr = size( branch_border_idx,1); 
    %% First way, depreciated
    %{
    % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row) : [fbus, tbus]
    buses_of_branch_border = basecase.branch(branch_border_idx,[1,2]);
    % For each branch, determine what end buses are from the zone or outside
    is_fbus_tbus_of_branch_in_zone = ismember(buses_of_branch_border, bus_zone_id); % nbr x 2 boolean matrix
    
    bus_border_id = zeros(nbr,1);
    for row = 1:nbr
        % error if a branch does not have exactly 1 end bus inside the zone
        if is_fbus_tbus_of_branch_in_zone(row,1) + is_fbus_tbus_of_branch_in_zone(row,2) ~= 1
            disp(['Error: branch ', num2str(branch_border_idx(row,1)),' does not have exactly 1 end bus inside the zone'...
                'check branch_border_idx is correct, i.e. all branches are at the border of the zone'])
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
    %}
    
    %% Second way
    % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row)
    fbus= basecase.branch(branch_border_idx, 1);
    tbus= basecase.branch(branch_border_idx, 2);
    % look for the end buses of each branch at the border, i.e. not in the zone. As boolean column vectors
    is_fbus_border = ~ismember(fbus, bus_zone_id);
    is_tbus_border = ~ismember(tbus, bus_zone_id);
    if any(is_fbus_border + is_tbus_border ~= 1)
        % error if a branch does not have exactly 1 end bus inside the zone
        disp(['Error: a branch does not have exactly 1 end bus inside the zone'...
                'check branch_border_idx is correct, i.e. all branches are at the border of the zone'])
            return
    end
    % Get the buses id of the end buses at the border
    fbus_border_id = fbus(is_fbus_border);
    tbus_border_id = tbus(is_tbus_border);
    % the buses at the border are the union set, i.e. no repetition, in sorted order, as a column vector
    bus_border_id = union(fbus_border_id, tbus_border_id, 'rows', 'sorted');
end