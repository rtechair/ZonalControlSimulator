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
function [PTDF_G, PTDF_B, PTDF_N] = leastSquares(powerFlowVariation, powerGenerationVariation, powerBatteryVariation, powerTransitVariation)
arguments
    powerFlowVariation (:, 240)
    powerGenerationVariation
    powerBatteryVariation
    powerTransitVariation
end

numberOfBuses = height(powerTransitVariation);
numberOfLines = height(powerFlowVariation);
numberOfGen = height(powerGenerationVariation);
numberOfBatt = height(powerBatteryVariation);

var_PTDF_G = sdpvar(numberOfLines, numberOfGen, 'full');
var_PTDF_B = sdpvar(numberOfLines, numberOfBatt, 'full');
var_PTDF_N = sdpvar(numberOfLines, numberOfBuses, 'full');

objective = sum((powerFlowVariation - var_PTDF_B * powerBatteryVariation - var_PTDF_G * powerGenerationVariation - var_PTDF_N * powerTransitVariation).^2, "all");
options = sdpsettings('verbose',1,'solver','gurobi');
constraint_PTDF_G = -1 <= var_PTDF_G <= 1;
constraint_PTDF_B = -1 <= var_PTDF_B <= 1;
constraint_PTDF_N = -1 <= var_PTDF_N <= 1;
constraints = [constraint_PTDF_G, constraint_PTDF_B, constraint_PTDF_N];
sol = optimize(constraints, objective, options);

if sol.problem == 0
    PTDF_G = value(var_PTDF_G);
    PTDF_B = value(var_PTDF_B);
    PTDF_N = value(var_PTDF_N);
else
    disp("something went wrong, no solution found.")
    sol.info
    yalmip.error(sol.problem)
end