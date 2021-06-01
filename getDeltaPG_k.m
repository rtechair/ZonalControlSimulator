function zone = getDeltaPG_k(zone, step)
    arguments
        zone {mustBeA(zone, 'Zone')}
        step (1,1) {mustBeInteger, mustBePositive}
    end
    % step <= zone.N_iteration
    mustBeLessThanOrEqual(step, zone.NumberIteration)
    
    
    if step >= zone.DelayCurt + 1
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step) + zone.DeltaPC(step - zone.DelayCurt);
    else
        % there is no information on the curtailement decided prior to the simulation
        f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step);
    end
    g = zone.MaxPG- zone.PC(:,step) - zone.PG(:,step);
    zone.DeltaPG(:,step) = min(f,g);
end