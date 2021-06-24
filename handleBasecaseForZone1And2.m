function handleBasecaseForZone1And2()
    isInitialBasecaseHere = exist('case6468rte_mod.m','file') == 2;
    isBasecaseWithZone1Here = exist('case6468rte_zone1.mat','file') == 2; 
    isBasecaseWithZone1And2Here = exist('case6468rte_zone1and2.mat','file') == 2; 
    total = 4*isBasecaseWithZone1And2Here + 2*isBasecaseWithZone1Here + isInitialBasecaseHere;
    switch total
        % basecase includes zone 1 and zone 2
        case {4, 5, 6, 7}
            return
        % basecase includes zone 1 but not zone 2
        case {2, 3}
            updateCaseForZone2();
        % basecase does not include zone 1 nor zone 2, but the initial basecase
        case {1}
            updateCaseForZone1();
            updateCaseForZone2();
        otherwise
            disp("ERROR: Both case6468rte_zone1.mat and case6468rte_mod.mat are missing, can't do anything with no basecase")
    end
end