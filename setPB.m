function zone = setPB(zone)
    arguments
        zone {mustBeA(zone, 'Zone')}
    end
    mustBePositive(zone.N_iteration); % check zone.N_iteration has been computed
    % check zone.DeltaPB has been computed
    if isempty(zone.DeltaPB)
        disp(['Advise: deltaPB should be created or filled before computing PB.'...
            ' No worries, deltaPB has been initialized to zero'])
        zone.DeltaPB = zeros(zone.N_battOn, zone.N_iteration);
    end
    
    zone.PB = zeros(zone.N_battOn, zone.N_iteration+1);
    % compute PB as PB(k+1) = PB(k) + DeltaPB(k)
    for k = 1:zone.N_iteration
        zone.PB(:,k+1) = zone.PB(:,k) + zone.DeltaPB(:,k);
    end
end