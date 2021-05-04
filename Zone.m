classdef Zone
    properties
        % general elements
        basecase
        basecase_int % MatPower vision
        mapBus_id2idx
        mapBus_idx2id
        mapBus_ext2int
        mapBus_int2ext
        % elements of the zone
        bus_id
        bus_idx
        bus_int_idx
        mapBus_id2idxZone
        mapBus_idxZone2id
        branch_idx
        branch_int_idx
        
        % peripheral / nearby zone
        bus_near_id
        bus_near_idx
        bus_near_int_idx
        
        branch_inner_id
        branch_inner_idx
        branch_near_id
        
        gen_inner
    end
    
    methods
        function obj= Zone(bus_id, basecase, basecase_int, mapBus_id2idx, mapBus_idx2id)
            obj.bus_id = bus_id;
            obj.basecase = basecase;
            obj.basecase_int = basecase_int;
            obj.mapBus_id2idx = mapBus_id2idx;
            obj.mapBus_idx2id = mapBus_idx2id;
            obj.mapBus_ext2int = basecase_int.order.bus.e2i;
            obj.mapBus_int2ext = basecase_int.order.bus.i2e;
            
            obj.bus_idx = getValues(obj.mapBus_id2idx, obj.bus_id);
            obj.bus_int_idx = obj.mapBus_ext2int(obj.bus_idx,1);
        end
        
        %function obj = identifyBranch(obj)
            
    end
end

%{

https://www.mathworks.com/help/matlab/matlab_oop/create-a-simple-class.html
https://www.mathworks.com/help/matlab/matlab_oop/specifying-methods-and-functions.html
https://www.mathworks.com/help/matlab/matlab_oop/properties.html
https://www.mathworks.com/help/matlab/ref/classdef.html
%}

%{
issue with outputs:
https://stackoverflow.com/questions/25906833/matlab-multiple-variable-assignments

%}