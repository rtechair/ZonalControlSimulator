%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}
function [PTDF_G, PTDF_B] = leastSquares_ConstraintSumPtdf(powerFlowVariation, powerGenerationVariation, powerBatteryVariation)
arguments
    powerFlowVariation
    powerGenerationVariation
    powerBatteryVariation
end
numberOfLines = height(powerFlowVariation);
numberOfGen = height(powerGenerationVariation);
numberOfBatt = height(powerBatteryVariation);

var_PTDF_G = sdpvar(numberOfLines, numberOfGen, 'full');
var_PTDF_B = sdpvar(numberOfLines, numberOfBatt, 'full');

objective = sum((powerFlowVariation -  var_PTDF_G * powerGenerationVariation - var_PTDF_B * powerBatteryVariation).^2, "all");
options = sdpsettings('verbose',0,'solver','gurobi');
constraint_PTDF_G = -1 <= var_PTDF_G <= 1;
constraint_PTDF_B = -1 <= var_PTDF_B <= 1;
constraints = [constraint_PTDF_G, constraint_PTDF_B];

isConstraint100Percent = true;
if isConstraint100Percent
    gen = 1;
    lineFrom = 7;
    lineTo = [4 5];
    constraint_bus2 = sum( var_PTDF_G(lineFrom, gen)) - sum(var_PTDF_G(lineTo, gen)) == 1;

    gen = 2;
    lineFrom = [1 3 6];
    lineTo = [];
    constraint_bus4 = sum( var_PTDF_G(lineFrom, gen)) - sum(var_PTDF_G(lineTo, gen)) == 1;

    gen = 4; 
    lineFrom = [];
    lineTo = [6 7];
    constraint_bus6 = sum( var_PTDF_G(lineFrom, gen)) - sum(var_PTDF_G(lineTo, gen)) == 1;
    constraint_batt = sum(var_PTDF_B(lineFrom, 1)) - sum(var_PTDF_B(lineTo, 1)) == 1;

    %constraints = [constraints, constraint_bus2, constraint_bus4, constraint_bus6];
    constraints = [constraints, constraint_bus2, constraint_bus4, constraint_bus6, constraint_batt];
end

sol = optimize(constraints, objective, options);

if sol.problem == 0
    PTDF_G = value(var_PTDF_G);
    PTDF_B = value(var_PTDF_B);
else
    disp("something went wrong, no solution found.")
    sol.info
    yalmip.error(sol.problem)
end