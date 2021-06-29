branchFlowLimit = 45;
numberOfGen = 4;
numberOfBatt = 2;
coefIncreaseCurt = 0.1;
coefDecreaseCurt = 0.01;
coefLowerThreshold = 0.6;
coefUpperThreshold = 0.8;
curtailmentDelay = 3;

limiter1 = Limiter(branchFlowLimit, numberOfGen, numberOfBatt, ...
                coefIncreaseCurt, coefDecreaseCurt, coefLowerThreshold, coefUpperThreshold, ...
                curtailmentDelay);

branchFlowState1 = [40 20 20 20 20 20]';
branchFlowState2 = [35 20 20 20 20 20]';
branchFlowState3 = [20 20 20 20 20 20]';

limiter1.computeControls(branchFlowState1); % increase curtailment

limiter1.computeControls(branchFlowState2); % do not alter curt.

limiter1.computeControls(branchFlowState3); % decrease curt.

limiter1.computeControls(branchFlowState3); % decrease curt.

for i=1:10
    limiter1.computeControls(branchFlowState1);
end
% futureCurtailmentState close to 1 now. Test if limiter refuses to increase curtailment

limiter1.computeControls(branchFlowState1) % do not alter