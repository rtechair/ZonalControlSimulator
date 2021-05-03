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