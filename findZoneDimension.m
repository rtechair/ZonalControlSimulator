function [nb_bus, nb_branch, nb_gen, nb_batt] = findZoneDimension(bus, branch, gen, batt)
    nb_bus = size(bus);
    nb_branch = size(branch);
    nb_gen = size(gen);
    nb_batt = size(batt);
end