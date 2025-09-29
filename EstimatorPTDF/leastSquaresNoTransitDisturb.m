function [PTDF_G, PTDF_B] = leastSquaresNoTransitDisturb(powerFlowVariation, powerGenerationVariation, powerBatteryVariation)
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
sol = optimize(constraints, objective, options);

if sol.problem == 0
    PTDF_G = value(var_PTDF_G);
    PTDF_B = value(var_PTDF_B);
else
    disp("something went wrong, no solution found.")
    sol.info
    yalmip.error(sol.problem)
end