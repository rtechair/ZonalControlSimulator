function zone = updateStateToStep(zone, step)
 % PC(step) and PG(step)
    if step >= zone.DelayCurt + 2
        zone.PC(:,step) = zone.PC(:,step-1)                      + zone.DeltaPC(:,step -1 - zone.DelayCurt);
        zone.PG(:,step) = zone.PG(:,step-1) + zone.DeltaPG(:,step-1) - zone.DeltaPC(:,step -1 - zone.DelayCurt);
    else
        % past commands are not known so they are considered null
        zone.PC(:,step) = zone.PC(:,step-1);
        zone.PG(:,step) = zone.PG(:,step-1) + zone.DeltaPG(:,step-1);
    end
    % PB(step) and EB(step)
    if step >= zone.DelayBatt + 2
        zone.PB(:,step) = zone.PB(:,step-1) + zone.DeltaPB(:,step -1 - zone.DelayBatt);
        zone.EB(:,step) = zone.EB(:,step-1) - zone.BattConstPowerReduc*zone.SimulationTime *...
            ( zone.PB(:,step-1) + zone.DeltaPB(:,step -1 - zone.DelayBatt) );
    else
        % past commands are not known so they are considered null
        zone.PB(:,step) = zone.PB(:,step -1);
        zone.EB(:,step) = zone.EB(:,step -1) - zone.BattConstPowerReduc*zone.SimulationTime * zone.PB(:,step-1);
    end
end