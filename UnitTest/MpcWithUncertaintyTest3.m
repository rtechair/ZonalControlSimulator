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
classdef MpcWithUncertaintyTest3 < matlab.unittest.TestCase
% This class aims at obtaining zone VG functional, not VGsmall.
    
    properties
        % setup objects
        zoneName
        delayCurt
        delayBatt
        delayTelecom
        controlCycle
        horizonInSeconds
        predictionHorizon
        numberOfScenarios
        
        amplifierQ_ep1
        maxPowerGeneration
        minPowerBattery
        maxPowerBattery
        maxEnergyBattery
        flowLimit
        maxEpsilon
        
        mpc
    end
    
    methods(TestMethodSetup)
        function setProperties(testCase)
            testCase.zoneName = 'VG';
            testCase.delayCurt = 9;
            testCase.delayBatt = 1;
            testCase.delayTelecom = 0;
            testCase.controlCycle = 5;
            testCase.horizonInSeconds = 50;
            horizonInIterations = ceil(testCase.horizonInSeconds / testCase.controlCycle);
            testCase.predictionHorizon = horizonInIterations;
            testCase.numberOfScenarios = 1;
            
            testCase.amplifierQ_ep1 = 10^7;
            testCase.maxPowerGeneration = [78;66;54;10];
            testCase.minPowerBattery = -10;
            testCase.maxPowerBattery = 10;
            testCase.maxEnergyBattery = 800;
            testCase.flowLimit = 45;
            testCase.maxEpsilon = 0.05;
        end
        
        
    end
    
    methods(Test)
        function createMpc(testCase)
            testCase.mpc = MpcWithUncertainty(testCase.zoneName,...
                testCase.delayCurt, testCase.delayBatt, testCase.delayTelecom, ...
                testCase.controlCycle, testCase.horizonInSeconds, ...
                testCase.numberOfScenarios);
            
            testCase.mpc.setOtherElements(testCase.amplifierQ_ep1, ...
                testCase.maxPowerGeneration, ...
                testCase.minPowerBattery, ...
                testCase.maxPowerBattery, ...
                testCase.maxEnergyBattery, ...
                testCase.flowLimit, ...
                testCase.maxEpsilon);
        end
        
        %{
        countControls = 92
        [1.51034186665433,0.114540957189138,0.0292984412437711,0.137801076847395,0.186617019861339,0.00121728736213470,0.00121199901481334,0.00121221038427849,6.41769347218417,NaN;...
        3.68238402962365,-0.478405363756706,-0.732510876618226,-0.409068729391818,-0.263550785372388,-0.818635430289161,-0.818620453547219,-0.818646652130787,5.61038150217831,NaN;...
        0.387255706979233,0.0293700573064339,0.00751806826892238,0.0353342967822654,0.0478496326640304,0.00112985686683580,0.00108874157551904,0.00116328901896677,0.184844113632701,NaN;...
        4.19050234657760,1.41220713469354,1.24253291405792,1.45850550046232,1.55567249515506,1.18539449470162,0.833754786501928,0,0,NaN]
        
        PA_initial = [57.0000000240000;48.2710659660000;9.09090909000000;65.0023996440000]
        deltaPA = [0;-0.819843120000002;0;1.18421784000000]
        
        ucK_new = [NaN, NaN, NaN, NaN] at step 91
        
        %}
        
        %{
        countControls = 90
        PB = [-9.26996637737875]
        deltaPB(89) = [4.58846695179640e-07]
        deltaPB(90) = [1.39754453759025e-06]
        
        deltaPC(90) =
        [0.00121221038427849;0.00119646786921499;0.00116328901896677;0.00116974949105486];
        
        issue: delays from telecommunication.
                "Telecom":
        {
            "timeSeries2Zone":0,
            "controller2Zone":20,
            "zone2Controller":5
        }
        %}
        
        function zoneVGIteration92LeadingToInfeasibility(testCase)
            Fij = [42.7869953445236;9.97073542251703;37.4054015192758;-39.9647776591132;-32.1272255982003;-27.2286630960758;31.2473992656819;27.2286630960747;-31.1014877777981;-17.2516152475515];
            PC = [0.599210419090701;0.774741655931391;0.212658589730657;1.11818363123455];
            PB = [-14.0696229230754]; % IMPOSSIBLE!
            EB = [0.0819300267430820];
            PG = [57.0000000240000;49.0909090860000;9.09090909000000;63.8181818040000];
        end
    end
end