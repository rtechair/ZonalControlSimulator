function zone = setPC(zone)
    arguments
        zone {mustBeA(zone, 'Zone')}
    end
    if isempty(zone.DeltaPC)
        disp('create or fill DeltaPC before computing PC')
    end
    mustBePositive(zone.N_iteration); % check zone.N_iteration has been computed
    % there might be some instances where there will be no generators ON,
    % so no constraint on N_genOn
    
    % compute PC as DeltaPA(k)=PA(k+1)-PA(k)
    % compute  PC as PC(k+1) = PC(k) + DeltaPC(k), initial curtailment
    % (k=1) is null
    zone.PC = zeros(zone.N_genOn, zone.N_iteration + 1);
    for k = 1: zone.N_iteration
        zone.PC(:, k+1) = zone.PC(:,k) - zone.DeltaPC(:,k);
    end
end