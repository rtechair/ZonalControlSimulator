function [A,Bc,Bb,Dg,Dt,Da,x,u,d] = fromMatpowerToABD(basecase_int, zone_bus,...
    zone_branch_inner_idx,zone_gen_idx, zone_battery_idx, ...
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
    zone_bus
    zone_branch_inner_idx
    zone_gen_idx
    zone_battery_idx

    sampling_time (1,1) double
    batt_cst_power_reduc %must be a vector, of length 'n_battery'
end
    
ISF = makePTDF(basecase_int);

% [nb_bus, nb_branch, nb_gen, nb_batt] = findBasecaseDimension(basecase); % [6469, 9001, 1228, 77]
%[nb_bus_int, nb_branch_int, nb_gen_int, nb_batt_int] = findBasecaseDimension(basecase_int); % [6469, 9001, 396, 13]

% in the mathematical model it corresponds to: [n^N, n^L, n^C, n^B]
[n_bus, n_branch, n_gen, n_battery] = findZoneDimension(zone_bus, zone_branch_inner_idx,zone_gen_idx, zone_battery_idx);

%% MATRIX INITIALIZATION
% X is stated as [ F, 
n_state_variables = n_branch + 3*n_gen + 2*n_battery;


%disturbance of generation
Dg = zeros(n_state_variables, n_gen);
% disturbance of power outside the zone
Dt = zeros(n_state_variables, n_bus);

% TODO: the variables are useless in this function, maybe create them
% later?
x = zeros(n_state_variables, 1);
u = zeros(n_gen + n_battery, 1); % TODO why Bc and Bb separated but not 'u'
d = zeros(n_bus, 1); 
     
%% Matrix element definition
%{
 In the following:
'tmp_range_row' and 'tmp_range_col' serve as a temporary ranges of indices to
edit submatrices values
'tmp_start_row' and 'tmp_start_col' indicates what is the initial starting row and column, thus cell, of the submatrices
%}

% 1) generate the coefficients for the A matrix w.r.t.:
%{
Fij(k+1) += Fij(k)
Pc(k+1) += Pc(k)
Pb(k+1) += Pb(k)
Eb(k+1) += Eb(k)
Pg(k+1) += Pg(k)
Pa(k+1) += Pa(k)
%}
A = eyes(n_state_variables);

% Eb(k+1) -= T*diag(cb)*Pb(k)
tmp_start_row = n_branch + n_gen + n_battery + 1;
tmp_start_col = n_branch + n_gen + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
tmp_range_col = tmp_start_col : tmp_start_col + n_battery - 1;

A(tmp_range_row, tmp_range_col) = - sampling_time*diag(batt_cst_power_reduc);
% notice with the previous operation, if there is no battery, then the
% submatrix to be modified is a empty double matrix which does not modify the matrix, so no special case to
% handle

% 2) Generate the coefficients for the Bc matrix w.r.t.
Bc = zeros(n_state_variables, n_gen);

% Pc(k+1) += DeltaPc(k-tau)
tmp_start_row = n_branch + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_gen - 1;
Bc(tmp_range_row, :) = eye(n_gen);

% Pg(k+1) -= DeltaPc(k-tau)
tmp_start_row = n_branch + n_gen + 2*n_battery + 1;
tmp_range_row = tmp_start_row : tmp_start_row +  nJ_gen - 1;
Bc(tmp_range_row , :) = - eye(n_gen);

% F(k+1) -= diag(ptdf)*DeltaPc(k-tau)
%TODO

%{
% TODO check if no special case is needed
% depending on if there are some batteries within the zone or not
if n_battery == 0
    Bb = 0; 
    Bb = zeros(n_state_variables, n_battery);
end
%}

% 3) Generate the coefficients for the Bc matrix w.r.t.
Bb = zeros(n_state_variables, n_battery); % here the special case of no battery should be handled

% Pb(k+1) += DeltaPb(k-delay_batt)
tmp_start_row = n_branch + n_gen + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
Bb(tmp_range_row,:) = eye(n_battery);

% Eb(k+1) -= T*diag(cb)*DeltaPb(k-delay_batt)
tmp_start_row = n_branch + n_gen + n_battery + 1;
tmp_range_row = tmp_start_row : tmp_start_row + n_battery - 1;
Bb(tmp_range_row,:) = - sampling_time*diag(batt_cst_power_reduc);


% F(k+1) += diag(ptdf)*DeltaPb(k-delay_batt)
% TODO

% XX) Generate the coefficients for the disturbance matrix of power available
Da = zeros(n_state_variables, n_gen);
tmp_start_row = n_state_variables - n_gen + 1;
tmp_range_row = tmp_start_row : n_state_variables;
Da(tmp_range_row,:) = eye(n_gen);





