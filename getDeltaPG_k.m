function zone = getDeltaPG_k(zone, step)
    arguments
        zone {mustBeA(zone, 'Zone')}
        step (1,1) {mustBeInteger, mustBePositive}
    end
    % step <= zone.N_iteration
    mustBeLessThanOrEqual(step, zone.N_iteration)
    
    
    if step >= zone.Delay_curt + 1
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step) + zone.DeltaPC(step - zone.Delay_curt);
    else
        % there is no information on the curtailement decided prior to the simulation
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step);
    end
    g = zone.maxPG- zone.PC(:,step) - zone.PG(:,step);
    zone.DeltaPG(:,step) = min(f,g);
end