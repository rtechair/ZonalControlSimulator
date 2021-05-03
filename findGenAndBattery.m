function [gen_idx, battery_idx] = findGenAndBattery(bus_zone_id, basecase)
    % Given a zone based on its buses and a basecase, 
    % return the column vectors of the indices of the generators and
    % batteries in the zone, from the basecase
    n_gen = size(basecase.gen,1);
    gen_idx = [];
    battery_idx = [];
    is_gen_or_battery_in_zone = ismember(basecase.gen(:,1),  bus_zone_id); % batteries are generators with Pg_min < 0
    
    %{
    S = sparse(is_gen_or_battery_in_zone);
    
    S2 = basecase.gen(S,:);
    %}
    % https://stackoverflow.com/questions/32903572/how-to-iterate-over-elements-in-a-sparse-matrix-in-matlab
    
    %% TODO simplify the following for loop using a sparse matrix and campare time performance
    
    for k = 1:n_gen
        % this is a generator or a battery
        if is_gen_or_battery_in_zone(k,1) == 1
            % check for a bizarre value for Pg_max
            if basecase.gen(k,9) <= 0
                disp(['this is a strange situation, gen_idx = ', k, ' has a Pg_max <= 0'])
            end
            % this is a battery
            if basecase.gen(k,10) < 0
                battery_idx(end+1,1) = k;
            % this is a generator only
            else
                gen_idx(end+1,1) = k;
            end
        end
    end
end