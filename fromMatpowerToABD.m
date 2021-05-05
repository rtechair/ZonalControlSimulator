function [A,Bc,Bd,Dg,Dn,Da,x,u,d] = fromMatpowerToABD(basecase_int, zone_bus, zone_branch_inner_idx,zone_gen_idx, zone_battery_idx)
% important: this concerns only one zone here
%{ 
Matrices definition for the linear system x(k+1)=Ax(k)+Bu(k+tau)+Dd(k)
x = [Fij Pc Pb Eb Pg ]     uc = DeltaPc      ub =DeltaPb     
w = DeltaPg      h = DeltaPT
The model is described by the equations x(k+1) = A*x(k) + Bc*DPC(k-tau_c) + Bb*DPB(k-tau_b) + Dg*DPG(k) + Dn*DPT(k) + Da*DPA(k)
%}

ISF = makePTDF(basecase_int);

% [nb_bus, nb_branch, nb_gen, nb_batt] = findBasecaseDimension(basecase); % [6469, 9001, 1228, 77]
%[nb_bus_int, nb_branch_int, nb_gen_int, nb_batt_int] = findBasecaseDimension(basecase_int); % [6469, 9001, 396, 13]

% in the mathematical model it corresponds to: [n^N, n^L, n^C, n^B]
[n_bus, n_branch, n_gen, n_battery] = findZoneDimension(zone_bus, zone_branch_inner_idx,zone_gen_idx, zone_battery_idx);

%% MATRIX INITIALIZATION
n_state_variables = n_branch + 2*n_gen + 2*n_battery;
n_time_steps = 5; %TODO check this is indeed the nb_of_time_steps, can it be an input?

% A = zeros(n_state_variables);
Bc = zeros(n_state_variables, n_gen);

% depending on if there are some batteries within the zone or not
if n_battery == 0
    Bb = 0;
else
    Bb = zeros(n_state_variables);
end
%disturbance of generation
Dg = zeros(n_state_variables, n_gen);
% disturbance of power outside the zone
Dn = zeros(n_state_variables, n_bus);
% disturbance of power available
Da = zeros(n_state_variables, n_gen);

x = zeros(n_state_variables, n_time_steps);
u = zeros(n_gen + n_battery, n_time_steps): %TODO why Bc and Bb separated but not u
d = zeros(n_bus, n_time_steps); %TODO check it is correct
     
%% Matrix element definition
%{
 In the following:
tmp_idx serves as temporary indices to construct the submatrices that are modified
tmp_start indicates what is the initial starting row and column, thus cell, of the submatrices
%}

% 1) generate the coefficients for the A matrix w.r.t.:
%{
Fij(k+1) += Fij(k)
Pc(k+1) += Pc(k)
Pb(k+1) += Pb(k)
Eb(k+1) += Eb(k)
Pg(k+1) += Pg(k)
%}
A = eyes(n_state_variables);

%{
USELESS NOW AS THIS IS REPLACED BY WHAT COMES BEFORE
% w.r.t. Fij(k+1) += Fij(k)
tmp_idx = 1:n_branch;
A(tmp_idx,tmp_idx) = eye(n_branch);

% w.r.t. Pc(k+1) += Pc(k)
tmp_start = n_branch + 1;
tmp_idx = tmp_start: tmp_start+n_gen-1; % if n_gen = 0, then A(I,I) = [], so no modification on A. No need to handle special case n_gen = 0
A(tmp_idx,tmp_idx) = eye(n_gen);

% w.r.t. Pb(k+1) += Pb(k)
tmp_start = n_branch + n_gen + 1
tmp_idx = tmp_start : tmp_start + n_battery - 1
% w.r.t. Eb(k+1) += Eb(k)
%}

% Eb(k+1) += Eb(k+1)







