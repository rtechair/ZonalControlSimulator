function [n_bus, n_branch, n_gen, n_batt] = findZoneDimension(bus, branch, gen, batt)
    n_bus = size(bus,1);
    n_branch = size(branch,1);
    n_gen = size(gen,1);
    n_batt = size(batt,1);
end