function handleBasecase()
    b1 = exist('case6468rte_mod.m','file') == 2; % initial basecase provided by Jean
    b2 = exist('case6468rte_zone1.mat','file') == 2; % updated basecase for zone 1
    b3 = exist('case6468rte_zone1and2.mat','file') == 2; % updated basecase for zone 1 & 2
    b_tot = 4*b3 + 2*b2 + b1;
    switch b_tot
        % basecase includes zone 1 and zone 2
        case {4, 5, 6, 7}
            return
        % basecase includes zone 1 but not zone 2
        case {2, 3}
            % TODO
            return
        % basecase does not include zone 1 nor zone 2, but the initial basecase
        case {1}
            % so compute the updated basecase
            updateCaseForZone1();
            updateCaseForZone2();
        otherwise
            disp("ERROR: Both case6468rte_mod2.mat and case6468rte_mod.mat are missing, can't do anything with no basecase")
    end
end