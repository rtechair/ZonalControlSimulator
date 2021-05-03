function [isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecase_int)
    % Check if some buses or branches have been deleted during the internal
    % conversion by MatPower function 'ext2int2'
    % Return booleans, respectively for deleted buses and for deleted branches
    %% Input
    % basecase_int: the internal basecase produced by the ext2int function
    %% Output
    % isBusDeleted: boolean, if there is at least a bus deleted compared to
    % the exterior basecase
    % isBranchDeleted: boolean, if there is at least a branch deleted compared to
    % the exterior basecase
    
    % a bus is deleted if the number of off buses >= 1
    isBusDeleted = size(basecase_int.order.bus.status.off,1) ~= 0;
    % a branch is deleted if the number of off branches >= 1
    isBranchDeleted = size(basecase_int.order.branch.status.off,1) ~= 0;
    