numberOfZones = 1;


if exist('case6468rte_mod2.mat','file') ~= 2
    % the file does not exist
    if exist('case6468rte_mod.m','file') ~= 2
        % this one neither
        disp("ERROR: Both case6468rte_mod2.mat and case6468rte_mod.mat are missing, can't do anything with no basecase")
    else
        % compute it using the 1st one
        updateCase()
    end
end

