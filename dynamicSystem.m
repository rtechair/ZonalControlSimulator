function [A,Bc,Bb,Dg,Dt,Da] = dynamicSystem(basecase_int, zone_bus_id,...
    zone_branch_inner_idx,zone_gen_idx, zone_battery_idx, mapBus_id_e2i, mapGenOn_idx_e2i, ...
    sampling_time, batt_cst_power_reduc)
% important: this concerns only one zone here
%% Input
% batt_cst_power_reduc : must be a vector
%{ 
Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k+tau)+Dd(k)
x = [Fij Pc Pb Eb Pg ]     uc = DeltaPc      ub =DeltaPb     
w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
%}

arguments
    basecase_int
    zone_bus_id
    zone_branch_inner_idx
    zone_gen_idx
    zone_battery_idx
    mapBus_id_e2i
    mapGenOn_idx_e2i
    sampling_time (1,1) double
    batt_cst_power_reduc %must be a vector, of length 'n_battery'
end

%% Global sizes
% in the mathematical model it corresponds to: [n^N, n^L, n^C, n^B]
[n_bus, n_branch, n_gen, n_battery] = findZoneDimension(zone_bus_id, zone_branch_inner_idx,zone_gen_idx, zone_battery_idx);

% X is stated as [ Fij Pc Pb Eb Pg Pa]', thus it includes Pa: available
% power, while not present in the paper explicitely
n_state_variables = n_branch + 3*n_gen + 2*n_battery;

ISF = makePTDF(basecase_int);
     
%% Matrix element definition
%{
 In the following local functions:
'tmp_range_row' and 'tmp_range_col' serve as a temporary ranges of indices to
edit submatrices values
'tmp_start_row' and 'tmp_start_col' indicates what is the initial starting row and column, thus cell, of the submatrices
%}

%% 1) Generate the coefficients for the A matrix w.r.t.:
A = stateSystem(n_state_variables, n_branch, n_gen, n_battery, sampling_time, batt_cst_power_reduc);

%% 2) Generate the coefficients for the Bc matrix
Bc = controlCurtailment(basecase_int, n_state_variables, n_branch, n_gen, n_battery, ...
    zone_branch_inner_idx, zone_gen_idx, mapGenOn_idx_e2i, ISF);

%% 3) Generate the coefficients for the Bb matrix
Bb = controlBattery(basecase_int, n_state_variables, n_branch, n_gen, n_battery,...
    zone_branch_inner_idx, zone_battery_idx, mapGenOn_idx_e2i, ISF, sampling_time, batt_cst_power_reduc);


%% 4) Generate the coefficients for the disturbance of generation Dg
Dg = disturbanceDeltaPowerGenerated(basecase_int, n_state_variables, n_branch, n_gen,...
    zone_branch_inner_idx, zone_gen_idx, mapGenOn_idx_e2i, ISF);


%% 5) Generate the disturbance of power outside the zone, matrix Dt
Dt = disturbanceDeltaPowerTransiting(n_state_variables, n_bus, n_branch,...
    zone_bus_id, zone_branch_inner_idx, mapBus_id_e2i, ISF);


%% 6) Generate the coefficients for the disturbance matrix of power available Da
Da = disturbanceDeltaPowerAvailable(n_state_variables, n_gen);
end


function A = stateSystem(n_state_variables, n_branch, n_gen, n_battery, sampling_time, batt_cst_power_reduc)
% Return the state system operator A

%{
Fij(k+1) += Fij(k)
Pc(k+1) += Pc(k)
Pb(k+1) += Pb(k)
Eb(k+1) += Eb(k)
Pg(k+1) += Pg(k)
Pa(k+1) += Pa(k)
%}
A = eye(n_state_variables);

% Eb(k+1) -= T*diag(cb)*Pb(k)
tmp_start_row = n_branch + n_gen + n_battery + 1;
tmp_start_col = n_branch + n_gen + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
tmp_range_col = tmp_start_col : tmp_start_col + n_battery - 1;
A(tmp_range_row, tmp_range_col) = - sampling_time*diag(batt_cst_power_reduc);
% notice with the previous operation, if there is no battery, then the submatrix to be modified 
% is a empty double matrix which does not modify the matrix, so no special case to handle
end


function Bc = controlCurtailment(basecase_int, n_state_variables, n_branch, n_gen, n_battery, ...
    zone_branch_inner_idx, zone_gen_idx, mapGenOn_idx_e2i, ISF)

Bc = zeros(n_state_variables, n_gen);

% F(k+1) -= diag(ptdf)*DeltaPc(k-tau)
zone_gen_on_int_idx = mapGenOn_idx_e2i(zone_gen_idx);
bus_id_int_of_gen_on = basecase_int.gen(zone_gen_on_int_idx,1); % as bus_id_int = bus_idx_int
Bc(1:n_branch,:) = - ISF( zone_branch_inner_idx,... % indices for branch are the same for int and ext
    bus_id_int_of_gen_on); % = - Mc in the paper

% Pc(k+1) += DeltaPc(k-tau)
tmp_start_row = n_branch + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_gen - 1;
Bc(tmp_range_row, :) = eye(n_gen);

% Pg(k+1) -= DeltaPc(k-tau)
tmp_start_row = n_branch + n_gen + 2*n_battery + 1;
tmp_range_row = tmp_start_row : tmp_start_row +  n_gen - 1;
Bc(tmp_range_row , :) = - eye(n_gen);
end


function Bb = controlBattery(basecase_int, n_state_variables, n_branch, n_gen, n_battery,...
    zone_branch_inner_idx, zone_battery_idx, mapGenOn_idx_e2i, ISF, sampling_time, batt_cst_power_reduc)
% initialization, the special case of no battery should be handled
Bb = zeros(n_state_variables, n_battery);

% F(k+1) += diag(ptdf)*DeltaPb(k-delay_batt), i.e. matrix Mb
zone_battery_int_idx = mapGenOn_idx_e2i(zone_battery_idx);
bus_id_int_of_batt_on = basecase_int.gen(zone_battery_int_idx,1);
Bb(1:n_branch , :) = ISF(zone_branch_inner_idx, bus_id_int_of_batt_on); % as id_int = idx_int

% Pb(k+1) += DeltaPb(k-delay_batt), i.e. matrix eye
tmp_start_row = n_branch + n_gen + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
Bb(tmp_range_row , :) = eye(n_battery);

% Eb(k+1) -= T*diag(cb)*DeltaPb(k-delay_batt), i.e. matrix -Ab
tmp_start_row = n_branch + n_gen + n_battery + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
Bb(tmp_range_row , :) = - sampling_time*diag(batt_cst_power_reduc);
end


function Dg = disturbanceDeltaPowerGenerated(basecase_int, n_state_variables, n_branch, n_gen,...
    zone_branch_inner_idx, zone_gen_idx, mapGenOn_idx_e2i, ISF)
Dg = zeros(n_state_variables, n_gen);
zone_gen_on_int_idx = mapGenOn_idx_e2i(zone_gen_idx);
bus_id_int_of_gen_on = basecase_int.gen(zone_gen_on_int_idx,1); % as bus_id_int = bus_idx_int
Dg(1:n_branch , :) = ISF( zone_branch_inner_idx,... % branch indices are the same for int and ext
    bus_id_int_of_gen_on); % = Mc in the paper
end


function Dt = disturbanceDeltaPowerTransiting(n_state_variables, n_bus, n_branch,...
    zone_bus_id, zone_branch_inner_idx, mapBus_id_e2i, ISF)
Dt = zeros(n_state_variables, n_bus);
zone_bus_int_idx = mapBus_id_e2i(zone_bus_id); % recall interior idx = interior id
Dt(1:n_branch , :) = ISF(zone_branch_inner_idx, zone_bus_int_idx);
end


function Da = disturbanceDeltaPowerAvailable(n_state_variables, n_gen)
Da = zeros(n_state_variables, n_gen);
tmp_start_row = n_state_variables - n_gen + 1;
tmp_range_row = tmp_start_row : n_state_variables;
Da(tmp_range_row , :) = eye(n_gen);
end
