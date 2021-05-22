function zone = getDeltaPG_k(zone, step)
    arguments
        zone {mustBeA(zone, 'Zone')}
        step (1,1) {mustBeInteger, mustBePositive}
    end
    % step <= zone.N_iteration
    mustBeLessThanOrEqual(step, zone.N_iteration)
    
    f = zone.PA(:,step) + zone.DeltaPA(:,step) - zone.PG(:,step) + zone.DeltaPC(k - zone.delay_curt);
    g = zone.maxPG(:,step) - zone.PC(:,step) - zone.PG(:,step);
    zone.Delta(:,step) = min(f,g);
end