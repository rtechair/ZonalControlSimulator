function [nb_bus, nb_branch, nb_gen, nb_batt] = findBasecaseDimension(basecase)
    % Show the dimensions of the considered matpower case
    %% Input
    % case: matpower case
    %% Output:
    % 'nb_bus': number of buses
    % 'nb_branch': number of branches
    % 'nb_gen': number of exclusive generators, no battery included
    % 'nb_battery': number of batteries
    
    % number of buses
    nb_bus = size(basecase.bus,1);
    % number of branches
    nb_branch = size(basecase.branch,1);
    
    % new version
    Pg_min = basecase.gen(:,10);
    % a generator is in fact a battery if Pg_min < 0
    isItaBattery = Pg_min < 0; 
    nb_batt = sum(isItaBattery);
    % As both exclusive gen and batteries are contained in the basecase.gen
    % thus, nb_gen = (nb_gen + nb_batt) - nb_batt
    nb_gen = size(basecase.gen,1) - nb_batt;
end
    