function zone = getPT_k(results, zone, step)
% Returns the zone with the property PT(:,step) computed
    arguments
        results
        zone {mustBeA(zone, 'Zone')}
        step (1,1) {mustBeInteger, mustBePositive}
    end
    mustBeLessThanOrEqual(step, zone.N_iteration+1)

    % create a map associating the bus id to bus idx in the zone.Bus_id array 
    mapBusZone_id2idx = sparse(zone.Bus_id, ones(zone.N_bus,1), 1:zone.N_bus);

    % for each branch at the border
    for br = 1: size(zone.Branch_border_idx,1)
        br_idx = zone.Branch_border_idx(br,1);
        fbus = results.branch(br_idx,1);
        % is fbus inside the zone
        if ismember(fbus, zone.Bus_id)
            fbus_idx = mapBusZone_id2idx(fbus);
            powerInjection_at_fbus = results.branch(br_idx, 14);
            % add the power injection from this branch to the associate bus PT
            zone.PT(fbus_idx,step) = zone.PT(fbus_idx,step) + powerInjection_at_fbus;
        else % fbus outside, tbus inside
            tbus = results.branch(br_idx,2);
            tbus_idx = mapBusZone_id2idx(tbus);
            powerInjection_at_tbus = results.branch(br_idx, 16);
            % add the power injection from this branch to the associate bus PT
            zone.PT(tbus_idx,step) = zone.PT(tbus_idx,step) + powerInjection_at_tbus;
        end
    end        
end