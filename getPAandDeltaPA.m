function zone = getPAandDeltaPA(zone, basecase, filename_charging_rate)
    arguments
        zone {mustBeA(zone, 'Zone')}
        basecase struct
        filename_charging_rate {mustBeTextScalar}
    end
    % check the property zone.Sampling_time has been initialized
    if isempty(zone.Sampling_time)
        error(' the property Sampling_time has not been initialized, initialize it before using getPAandDeltaPA function')
    end
    mustBePositive(zone.N_iteration); % check zone.N_iteration has been computed
    
    % The property zone.GenOn_idx exists because it is computed during the construction of a Zone object

    % check the property zone.N_genOn has been initialized, if not compute it
    if isempty(zone.N_genOn)
        [zone.N_bus, zone.N_branch, zone.N_genOn, zone.N_battOn] = findZoneDimension(zone.Bus_id, zone.Branch_idx, zone.GenOn_idx, zone.BattOn_idx);
        message = ['The property Zone.N_genOn was not initialized prior to the getPAandDeltaPA function.' newline ...
            'No worries, it was computed internally using the findZoneDimension function.' newline 'It is adviced to compute it before'];
        disp(message)
        %{
        issue: I tried to get the name of the object to be more precise using
         'inputname' function, but it only shows 'zone' instead, i.e. the name
         of the object inside this function, not the original object name.
         https://fr.mathworks.com/matlabcentral/answers/382503-how-can-i-get-the-name-of-a-matlab-variable-as-a-string
        %}
    end

    power_available_rate_realtime = table2array(readtable(filename_charging_rate));

    % Sample the available power w.r.t. the selected sampling time
    range_idx = 1 : zone.Sampling_time : size(power_available_rate_realtime,1);
    power_available_rate_simulationtime = power_available_rate_realtime(range_idx);


    % size of the percentage power vector
    n_sample_power_available_rate_realtime= size(range_idx,2);


    if zone.N_iteration > n_sample_power_available_rate_realtime
        disp('Error, the number of iterations of the simulation is greater than the number of samples of data of power available')
    end

    % set the initial sample of Power_available_rate_simulationtime to be
    % considered for the simulation, for each generator ON
    max_discrete_range = n_sample_power_available_rate_realtime - zone.N_iteration;
    PA_starting_time = randi(max_discrete_range, zone.N_genOn,1); % random column vector of size z1.N_genOn, of integers picked from the range [1, max_discrete_range]
    % randomness, uniform law, discrete value: https://www.mathworks.com/help/matlab/math/create-arrays-of-random-numbers.html

    % Compute the Power Available for the simulation: PA(k)
    maxPA_of_genOn = basecase.gen(zone.GenOn_idx, 9);
    % notice the '+1', in order to have 'n' intervals /variations (DeltaPA), 'n+1' positions/values (PA) are required
    zone.PA = zeros(zone.N_genOn, zone.N_iteration + 1);
    for r=1:zone.N_genOn
        tmp_range_col = PA_starting_time(r) : PA_starting_time(r)+zone.N_iteration; % and not -1, because in order to have 'n_iteration' DeltaPA values, 'n_iteration + 1' PA values are required
        zone.PA(r,:) = maxPA_of_genOn(r,1) * power_available_rate_simulationtime(tmp_range_col,1)';
    end

    % compute DeltaPA as DeltaPA(k)=PA(k+1)-PA(k)
    zone.DeltaPA = zeros(zone.N_genOn, zone.N_iteration);
    for k = 1:zone.N_iteration
        zone.DeltaPA(:, k) = zone.PA(:,k+1) - zone.PA(:,k);
    end
end