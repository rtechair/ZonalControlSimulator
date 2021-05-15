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
    arguments
        bus_zone_id (:,1) {mustBeInteger, mustBeNonempty}
        basecase struct
    end
    
    % check buses are present in the basecase
    mustBusBeFromBasecase(bus_zone_id, basecase)
    
    % from the basecase, extract the branches' "from" bus and "to" bus info, for each branch (row) : [fbus, tbus]
    buses_of_branch = basecase.branch(:,[1 2]);
    % determine what end buses are from the zone or outside, as boolean
    is_fbus_tbus_of_branch_in_zone = ismember(buses_of_branch, bus_zone_id);
    % sum booleans per branch :fbusIn + tBusIn, i.e. over the columns, to get the number of end buses of the branch within the zone  
    nb_of_buses_of_branch_in_zone = sum(is_fbus_tbus_of_branch_in_zone,2); 
    S = sparse(nb_of_buses_of_branch_in_zone);
    % the branch is within the zone as it is connecting 2 inner buses
    branch_inner_idx = find(S==2); 
    % the branch connects a inner bus with an outer bus
    branch_border_idx = find(S==1);    
end