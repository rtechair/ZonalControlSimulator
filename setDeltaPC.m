function zone = setDeltaPC(zone, instant, curtailment, maxPA_per_genOn)
    arguments
        zone {mustBeA(zone, 'Zone')}
        instant (:,1) % column vector, if row vector given, this converts it into a column vector, cf. https://www.mathworks.com/help/matlab/ref/arguments.html
        curtailment (:,:)
        maxPA_per_genOn (:,1) % column vector
    end
    
    %{
    4 cases: 
    1) either curtailment is 1 value, i.e. a double, applied to all generators on and to
    % all instants
    2) curtailment is a column vector of length zone.N_genOn, each value correspond to a
    generator which is applied to all instants
    3) curtailment is a column vector of length size(instant,1), so a value
    per instant, applied to all generators
    4) curtailment is a matrix of size zone.N_genOn * size(instant,1): each
    cell corresponds to the curtailment of a given generator at a given
    instant
    %}
    
    %% Handling error
    
    mustBePositive(zone.N_iteration); % check zone.N_iteration has been computed
    if isempty(zone.N_genOn)
        error('compute Zone.N_genOn using the findZoneDimension function, prior to using setGivenCurtailment')
    end
    
            
    
    if size(maxPA_per_genOn,1) ~= zone.N_genOn
        error('maxPA_of_genOn is of incorrect size, it is a vector of length zone.N_genOn')
    end
    
    n_instant = size(instant,1);
    [n_row_curt, n_col_curt] = size(curtailment);
    
    % check if curtailment is of correct size, if not then abort function
    if  (n_row_curt ~= 1 && n_row_curt ~= zone.N_genOn) || (n_col_curt ~= 1 && n_col_curt ~= n_instant)
        error(['curtailment is of incorrect size. The number of rows is 1 or zone.N_genOn.' newline ...
            'The number of columns is 1 or the same length as instant'])
    end
    
    %% Set the values for DeltaPC
    
    % initialize DeltaPC if necessary
    if isempty(zone.DeltaPC)
        zone.DeltaPC = zeros(zone.N_genOn,zone.N_iteration);
    end
    
    instant_to_modify = floor(zone.N_iteration * instant);
    
    % case 4
    if n_row_curt == zone.N_genOn && n_col_curt == n_instant
        zone.DeltaPC(:,instant_to_modify) = curtailment .* maxPA_per_genOn;
    else
        % case 1 & 2 & 3
        zone.DeltaPC(:,instant_to_modify) = curtailment .* repmat(maxPA_per_genOn, 1, n_instant);
    end
    
    %TODO check if the distinction is necessary, I believe all for cases
    %are fine with the 2nd equation
    
    %{
    elseif (n_row_curt == 1 || n_row_curt == zone.N_genOn) && (n_col_curt == 1 || n_col_curt == n_instant)
        zone.DeltaPC(:,instant_to_modify) = curtailment .* repmat( maxPA_per_gen, 1, n_instant);
    
    % error
    else
        error(['curtailment is of incorrect size. The number of rows is 1 or zone.N_genOn.' newline ...
            'The number of columns is 1 or the same length as instant'])
    end
    %}
    
end