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