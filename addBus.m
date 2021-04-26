function addBus(mpc, id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm)
    % addBus adds a bus to an existing MATPOWER file 'mpc' at the bottom
    % of the list
    %% Input
    % All the needed values describing a branch according to MATPOWER
    % manual, see section Bus Data Format of CASEFORMAT, type "help caseformat"
    arguments
        mpc struct      
        id (1,1) double {mustBeInteger, mustBePositive}
        type (1,1) double {mustBeMember(type, [1 2 3 4])}
        Pd (1,1) double
        Qd (1,1) double
        Gs (1,1) double
        Bs (1,1) double
        area (1,1) double {mustBeInteger, mustBePositive}
        Vm (1,1) double
        Va (1,1) double
        baseKV (1,1) double {mustBeInteger, mustBePositive}
        zone (1,1) double {mustBeInteger, mustBePositive}
        maxVm (1,1) double {mustBePositive}
        minVm (1,1) double {mustBePositive, mustBeLessThanOrEqual(minVm,maxVm)}
    end
    mpc.bus(end+1, :) = [id, type, Pd, Qd, Gs, Bs, area, Vm, Va, baseKV, zone, maxVm, minVm];
end