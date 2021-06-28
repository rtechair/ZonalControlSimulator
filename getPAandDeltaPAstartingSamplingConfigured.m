function zone = getPAandDeltaPAstartingSamplingConfigured(zone, basecase, filenameChargingRate, startingIterationOfWindForGen)
    arguments
        zone {mustBeA(zone, 'Zone')}
        basecase struct
        filenameChargingRate {mustBeTextScalar}
        startingIterationOfWindForGen
    end

    power_available_rate_realtime = table2array(readtable(filenameChargingRate));

    % Sample the available power w.r.t. the selected sampling time
    range_idx = 1 : zone.SamplingTime : size(power_available_rate_realtime,1);
    power_available_rate_simulationtime = power_available_rate_realtime(range_idx);


    % size of the percentage power vector
    n_sample_power_available_rate_realtime= size(range_idx,2);


    % set the initial sample of Power_available_rate_simulationtime to be
    % considered for the simulation, for each generator ON
    max_discrete_range = n_sample_power_available_rate_realtime - zone.NumberIteration;
    
    if any(startingIterationOfWindForGen > max_discrete_range)
        message = ['the starting iterations chosen for wind time series of the generators exceeds ' ...
            'the max discrete range, check that startingIterationOfWindForGen is < ' ...
            num2str(max_discrete_range) ', in the load data zone script'];
        error(message)
    end
    
    PA_starting_time = startingIterationOfWindForGen;

    % Compute the Power Available for the simulation: PA(k)
    maxPA_of_genOn = basecase.gen(zone.GenOnIdx, 9);
    % notice the '+1', in order to have 'n' intervals /variations (DeltaPA), 'n+1' positions/values (PA) are required
    zone.PA = zeros(zone.NumberGenOn, zone.NumberIteration + 1);
    for r=1:zone.NumberGenOn
        tmp_range_col = PA_starting_time(r) : PA_starting_time(r)+zone.NumberIteration; % and not -1, because in order to have 'n_iteration' DeltaPA values, 'n_iteration + 1' PA values are required
        zone.PA(r,:) = maxPA_of_genOn(r,1) * power_available_rate_simulationtime(tmp_range_col,1)';
    end

    % compute DeltaPA as DeltaPA(k)=PA(k+1)-PA(k)
    zone.DeltaPA = zeros(zone.NumberGenOn, zone.NumberIteration);
    for k = 1:zone.NumberIteration
        zone.DeltaPA(:, k) = zone.PA(:,k+1) - zone.PA(:,k);
    end
end