function [nb_bus, nb_branch, nb_gen, nb_batt] = findZoneDimension(bus, branch, gen, batt)
    nb_bus = size(bus,1);
    nb_branch = size(branch,1);
    nb_gen = size(gen,1);
    nb_batt = size(batt,1);
end