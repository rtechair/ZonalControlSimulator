function zone = setInitialPG(zone, zone_maxPA_of_genOn)
    arguments
        zone {mustBeA(zone, 'Zone')}
        zone_maxPA_of_genOn (:,1) %TODO zone_maxPA_of_genOn would be better as a zone property instead of an argument in every function
    end
    if isempty(zone.PA) || isempty(zone.PC)
        disp('zone.PA and zone.PC must be computed prior to the initialization of PG as PG is function of PA and PC')
        return
    end
    if isempty(zone.PG)
        zone.PG = zeros(zone.N_genOn, zone.N_iteration + 1); %TODO are N_battOn and N_iteration to check? or PA and PC already cover them?
    end
    % Initialization of PG, i.e. PG(k=1), with PG formulation:
    % PG(k) = min { PA(k), maxPA - PC(k) }
    zone.PG(:,1) = min( zone.PA(:,1), zone_maxPA_of_genOn - zone.PC(:,1) );
end
