function zone = getPT_k(results, zone, instant)
% WARNING: cautious on the order of the PT column vector returned. The
% order is based on first the fbus indices of the branch_border_idx, then the tbus
% indices. Thus, not the branch border indices directly.
    arguments
        results
        zone {mustBeA(zone, 'Zone')}
        instant (1,1) {mustBeInteger, mustBePositive}
    end
    mustBeLessThanOrEqual(instant, zone.N_iteration+1)
    
    % get the end bus id of the branch
    fbus = results.branch(zone.Branch_border_idx,1);
    tbus = results.branch(zone.Branch_border_idx,2);
    % check what buses are in the zone
    is_fbus_in_zone = ismember(fbus, zone.Bus_id);
    is_tbus_in_zone = ismember(tbus, zone.Bus_id);
    % get the power injection at the buses
    powerInjection_at_fbus = results.branch(zone.Branch_border_idx, 14);
    powerInjection_at_tbus = results.branch(zone.Branch_border_idx, 16);
    % get the power injection at the buses only in the zone
    %% 1st method, does not respect the correct order of the branch indices unfortunately
    %{
    PT_fbus = powerInjection_at_fbus(is_fbus_in_zone);
    PT_tbus = powerInjection_at_tbus(is_tbus_in_zone);
    PT = [PT_fbus; PT_tbus];
    %}
    %% 2nd method, to respect the correct order of the branch indices
    N_branch_border = size(zone.Branch_border_idx,1);
    PT = zeros(N_branch_border,1);
    for br = 1: N_branch_border
        if is_fbus_in_zone(br)
            PT(br,1) = powerInjection_at_fbus(br);
        else %tbus is in zone
            PT(br,1) = powerInjection_at_tbus(br);
        end
    end
    % now what is left is to compute the repartition for each branch within
    % the zone
    
end