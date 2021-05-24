function zone = getDeltaPG_k(zone, step)
    arguments
        zone {mustBeA(zone, 'Zone')}
        step (1,1) {mustBeInteger, mustBePositive}
    end
    % step <= zone.N_iteration
    mustBeLessThanOrEqual(step, zone.N_iteration)
    
    
    if step > zone.delay_curt
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step) + zone.DeltaPC(step - zone.delay_curt);
    else
        % there is no information on the curtailement decided prior to the simulation
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step);
    end
    g = zone.maxPG(:,step) - zone.PC(:,step) - zone.PG(:,step);
    zone.Delta(:,step) = min(f,g);
end