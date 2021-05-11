classdef Zone
    properties
        % the properties starts a majuscule only because the following tutorial
        % does the same way: https://www.mathworks.com/help/matlab/matlab_oop/example-representing-structured-data.html
        
        % elements of the inner zone
        Bus_id
        Bus_idx
        Bus_int_id

        Branch_idx
        % if no branch deleted, then branch_int_idx =
        % branch_idx, thus unnecessary
        
        GenOn_idx
        BattOn_idx
        GenOn_int_idx
        BattOn_int_idx
        
        % peripheral / nearby zone
        Bus_border_id
        Branch_border_idx
        
        % Number of elements
        
        %Dynamic Model Operator
        A   % state
        Bc  % control curtailment
        Bb  % control battery
        Dg  % disturbance from power generation variation
        Dt  % disturbance from power transmission variation
        Da  % disturbance from power availibity variation
        
        % Other
        Sampling_time
        Batt_cst_power_reduc
    end
    
    methods
        function obj= Zone(bus_id, basecase_int)
            % create the zone, providing the buses, branches, gen and batt ON of
            % the zone, alongside the buses and branches at the border of
            % the zone
            arguments
                bus_id (:,1) {mustBeInteger} % column vector
                basecase_int struct % MatPower Case struct
            end
            obj.Bus_id = bus_id;
            basecase = basecase_int.order.ext;
            [obj.Branch_idx, obj.Branch_border_idx] = findInnerAndBorderBranch(bus_id, basecase);
            obj.Bus_border_id = findBorderBus(bus_id, obj.Branch_border_idx, basecase);
            [obj.GenOn_idx, obj.BattOn_idx] = findGenAndBattOnInZone(bus_id, basecase);
        end
        
        function obj = setInteriorIdAndIdx(obj, mapBus_id_e2i, mapGenOn_idx_e2i)
            % Set the interior properties of the zone with regards to the internal basecase, i.e.
            % Bus_int_id: the internal indices of Buses
            % GenOn_int_idx: the internal indices of generators ON
            % BattOn_int_idx: the internal indices of batteries ON
            arguments
                obj
                mapBus_id_e2i (:,1) {mustBeInteger} % (sparse) double column matrix, serving as map
                mapGenOn_idx_e2i (:,1) {mustBeInteger} % (sparse) double column matrix
            end
            obj.Bus_int_id = mapBus_id_e2i(obj.Bus_id);
            obj.GenOn_int_idx = mapGenOn_idx_e2i(obj.GenOn_idx);
            obj.BattOn_int_idx = mapGenOn_idx_e2i(obj.BattOn_idx);
        end
        
        function obj = setDynamicSystem(obj, basecase_int, bus_id, branch_idx, genOn_idx, battOn_idx,...
                mapBus_id_e2i, mapGenOn_idx_e2i, sampling_time, batt_cst_power_reduc)
            % Set the dynamic model operators:
            % A: state               
            % Bc: control curtailment
            % Bb: control battery
            % Dg: disturbance from power generation variation
            % Dt: disturbance from power transmission variation
            % Da: disturbance from power availibity variation
            [obj.A, obj.Bc, obj.Bb, obj.Dg, obj.Dt, obj.Da] = dynamicSystem(basecase_int, bus_id, branch_idx, genOn_idx, battOn_idx,...
                mapBus_id_e2i, mapGenOn_idx_e2i, sampling_time, batt_cst_power_reduc);
        end
            
    end
end

%{
https://www.mathworks.com/help/matlab/matlab_oop/create-a-simple-class.html
https://www.mathworks.com/help/matlab/matlab_oop/specifying-methods-and-functions.html
https://www.mathworks.com/help/matlab/matlab_oop/properties.html
https://www.mathworks.com/help/matlab/ref/classdef.html

https://www.mathworks.com/matlabcentral/answers/350158-convert-a-struct-to-an-object-of-a-class
https://www.mathworks.com/help/matlab/matlab_oop/example-representing-structured-data.html
%}

%{
issue with outputs:
https://stackoverflow.com/questions/25906833/matlab-multiple-variable-assignments
%}