function [gen_on_in_zone_idx, batt_on_in_zone_idx] = findGenAndBattOnInZone(zone_bus_id, basecase)
    % Given a zone based on its buses id and a basecase, 
    % return the column vectors of the indices, from the basecase, of the generators and
    % batteries online and in the zone
    %% INPUT
    % zone_bus_id: zone's buses id as an column vector
    % basecase
    %% OUTPUT
    % gen_on_in_zone_idx: column vector of indices, from the basecase, of generators online and in the zone
    % bus_on_in_zone_idx: column vector of indices, from the basecase, of batteries online and in the zone
    
    % 1st condition: gen and batt are in the zone, i.e. in one of the zone's buses
    gen_and_batt_bus_id = basecase.gen(:,1);
    is_gen_and_batt_in_zone = ismember(gen_and_batt_bus_id, zone_bus_id); 
    % 2nd condition: gen and batt are online
    is_gen_and_batt_on = basecase.gen(:,8) > 0;
    % both conditions: intersection
    inter = is_gen_and_batt_in_zone .* is_gen_and_batt_on;
    gen_and_batt_on_in_zone_idx = find(inter);
    
    % separate gen and batt
    % batteries are generators with Pg_min < 0
    Pg_min = basecase.gen(:,10);
    batt_on_in_zone_idx = find(inter .* Pg_min < 0);
    % Gen = GenAndBatt minus Batt
    gen_on_in_zone_idx = setdiff(gen_and_batt_on_in_zone_idx, batt_on_in_zone_idx);
end