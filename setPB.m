function zone = setPB(zone)
    arguments
        zone {mustBeA(zone, 'Zone')}
    end
    if isempty(zone.DeltaPB)
        disp('create or fill DeltaPB before computing PB')
    end
    mustBePositive(zone.N_iteration); % check zone.N_iteration has been computed