classdef Zone < matlab.mixin.Copyable
    % matlab.mixin.Copyable
    % https://www.mathworks.com/help/matlab/matlab_oop/custom-copy-behavior.html
    % Now the class inherits 'handle', so it is a handle class and not a
    % value class
    properties
        % By convention on Matlab, properties start with a capital letter
        %{
        The basecase can be seen as an external one, matpower creates an
        internal basecase based on the external basecase:
        - If necessary, bus are reordered in increasing consecutive order
        - generators off, including batteries off, are not conserved in the
        internal basecase
        - "islands", i.e. isolated buses, are not conserved in the internal
        basecase, and adjacent branches neither. No such bus or branch are
        deleted for the Rte basecases, thus handling this peculiar
        situation has not been done. If such a situation happens, nothing
        in the code has been done in order to handle it.
        %}
        
        %% elements of the inner zone
        BusId (:,1) {mustBeInteger}
        BusIdx (:,1) {mustBeInteger}
        BusIntId (:,1) {mustBeInteger}
        BranchIdx (:,1) {mustBeInteger}
        
        %{
        BranchIntIdx ? No need for it:
        if no branch deleted, then branchIntIdx = BranchIdx, thus unnecessary. 
        However, in case some branches are deleted due to the selection of a different basecase,
        then the whole code is incorrect. All basecase instances from Rte have been checked
        that no branch is deleted
        %}
        
        
        %{
        Generators and batteries do not have an id, their index is used as such.
        Batteries are treated as generators with negative value for minimal power injection in the matpower case.
        
        during the internal basecase conversion by Matpower using
        'ext2int', all generators Off and batteries Off are deleted and
        does not appear in the internal basecase. Thus the specification of
        ON generators and batteries.
        %}
        GenOnIdx (:,1) {mustBeInteger}
        BattOnIdx (:,1) {mustBeInteger}
        GenOnIntIdx (:,1) {mustBeInteger}
        BattOnIntIdx (:,1) {mustBeInteger}
        
        %% border / nearby zone
        BusBorderId (:,1) {mustBeInteger}
        BranchBorderIdx (:,1) {mustBeInteger}
        
        %% Number of elements
        NumberBus (1,1) {mustBeInteger}
        NumberBranch (1,1) {mustBeInteger}
        NumberGenOn (1,1) {mustBeInteger}
        NumberBattOn (1,1) {mustBeInteger}
             
        %% Dynamic Model Operator
        A   % state
        Bc  % control curtailment
        Bb  % control battery
        Dg  % disturbance from power generation variation
        Dt  % disturbance from power transmission variation
        Da  % disturbance from power availibity variation
        
        % Variable and Storage of results
        PA
        DeltaPA
        PB
        DeltaPB
        PC
        DeltaPC
        PG
        DeltaPG
        PT
        DeltaPT
        Fij
        EB
        
        %% Other
        SamplingTime (1,1) {mustBeInteger, mustBeNonempty} = 5 
        % 'SamplingTime' default value  is necessary for function 'updateNumberIteration'
        SimulationTimeUnit (1,1) {mustBeInteger, mustBeNonempty}
        BattConstPowerReduc (1,1) {mustBeNonempty}
        
        DelayBattSec (1,1) {mustBeInteger}
        DelayCurtSec (1,1) {mustBeInteger}
        
        MaxPG (:,1)
        Duration (1,1) {mustBeInteger}
    end
    
    properties (SetAccess = private)
        NumberIteration (1,1) {mustBeInteger}
        DelayBatt (1,1) {mustBeInteger, mustBeNonempty}
        DelayCurt (1,1) {mustBeInteger, mustBeNonempty}      
    end
    
    methods
        function obj = Zone(basecase, busId)
            % create the zone, providing the buses, branches, gen and batt ON of
            % the zone, alongside the buses and branches at the border of
            % the zone
            arguments
                basecase struct % MatPower Case struct
                busId (:,1) {mustBeInteger, mustBeNonempty, mustBusBeFromBasecase(busId, basecase)}
            end
            % Define the bus id, branch indices, generators and batteries On within the zone.            
            % plus bus and branches at the border of the zone
            obj.BusId = busId;
            [obj.BranchIdx, obj.BranchBorderIdx] = findInnerAndBorderBranch(basecase, busId);
            obj.BusBorderId = findBorderBus(basecase, busId, obj.BranchBorderIdx);
            [obj.GenOnIdx, obj.BattOnIdx] = findGenAndBattOnInZone(busId, basecase);
            
            obj.updateNumberElement;
        end
        
        function obj = setInteriorIdAndIdx(obj, mapBus_id_e2i, mapGenOn_idx_e2i)
            % Set the interior properties of the zone with regards to the internal basecase, i.e.
            % Bus_int_id: the internal indices of Buses
            % GenOn_int_idx: the internal indices of generators ON
            % BattOn_int_idx: the internal indices of batteries ON
            arguments
                obj
                mapBus_id_e2i (:,1) {mustBeInteger} % sparse double column matrix, serving as map
                mapGenOn_idx_e2i (:,1) {mustBeInteger} % sparse double column matrix
            end
            % because the maps are sparse matrix, the returned column vector is
            % also sparsed, hence the use of 'full' function to obtain a
            % full column vector
            obj.BusIntId = full(mapBus_id_e2i(obj.BusId)); 
            obj.GenOnIntIdx = full(mapGenOn_idx_e2i(obj.GenOnIdx));
            obj.BattOnIntIdx = full(mapGenOn_idx_e2i(obj.BattOnIdx));
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

        
        %% Set property
        function set.Duration(obj, duration)
            arguments
                obj
                duration {mustBeInteger, mustBePositive}
            end
            obj.Duration = duration;
            obj.updateNumberIteration;
        end
        
        function set.SamplingTime(obj, samplingTime)
            arguments
                obj
                samplingTime {mustBeInteger, mustBePositive}
            end
            obj.SamplingTime = samplingTime;
            obj.updateNumberIteration;
        end
          
        function set.DelayBattSec(obj, delayBattSec)
            obj.DelayBattSec = delayBattSec;
            obj.updateDelayBatt;
        end
        
        function set.DelayCurtSec(obj, delayCurtSec)
            obj.DelayCurtSec = delayCurtSec;
            obj.updateDelayCurt;
        end
        
    end
    
    methods(Access = private)
            
        function updateDelayBatt(obj)
            obj.DelayBatt = ceil(obj.DelayBattSec/obj.SamplingTime);
        end

        function updateDelayCurt(obj)
            obj.DelayCurt = ceil(obj.DelayCurtSec/obj.SamplingTime);
        end

        function updateNumberIteration(obj)
            obj.NumberIteration = floor( obj.Duration / obj.SamplingTime);
        end

        function obj = updateNumberElement(obj)
        % Set the zone dimensions: within the zone, number of buses/branches/generators On/batteries On
        obj.NumberBus = size(obj.BusId,1);
        obj.NumberBranch = size(obj.BranchIdx,1);
        obj.NumberGenOn = size(obj.GenOnIdx,1);
        obj.NumberBattOn = size(obj.BattOnIdx,1);
        end
        
    end

end


    
%{
Help regarding Matlab classes:
https://www.mathworks.com/help/matlab/matlab_oop/create-a-simple-class.html
https://www.mathworks.com/help/matlab/matlab_oop/specifying-methods-and-functions.html
https://www.mathworks.com/help/matlab/matlab_oop/property-access-methods.html
https://www.mathworks.com/help/matlab/matlab_oop/properties.html
https://www.mathworks.com/help/matlab/ref/classdef.html

https://www.mathworks.com/matlabcentral/answers/350158-convert-a-struct-to-an-object-of-a-class
https://www.mathworks.com/help/matlab/matlab_oop/example-representing-structured-data.html

https://www.mathworks.com/help/matlab/matlab_oop/comparing-handle-and-value-classes.html
https://www.mathworks.com/help/matlab/matlab_oop/validate-property-values.html
https://stackoverflow.com/questions/51294245/why-do-some-matlab-class-methods-require-apparently-unnecessary-output-argumen

https://www.mathworks.com/help/matlab/matlab_oop/property-set-methods.html
https://www.mathworks.com/help/matlab/matlab_oop/avoiding-property-initialization-order-dependency.html
https://www.mathworks.com/help/matlab/matlab_oop/access-methods-for-dependent-properties.html
https://www.mathworks.com/help/matlab/matlab_oop/property-attributes.html
https://www.mathworks.com/help/matlab/matlab_oop/example-representing-structured-data.html#f2-85430

https://www.mathworks.com/matlabcentral/answers/128905-how-to-efficiently-use-dependent-properties-if-dependence-is-computational-costly
%}

%{
issue with outputs:
https://stackoverflow.com/questions/25906833/matlab-multiple-variable-assignments
%}