% from testLimiter.m 
branchFlowLimit = 45;
zoneVG_numberOfGenerators = 4;
zoneVG_numberOfBatteries = 1;
coefIncreaseCurt = 0.1;
coefDecreaseCurt = 0.01;
coefLowerThreshold = 0.6;
coefUpperThreshold = 0.8;
curtailmentDelay = 3;

limiter1 = Limiter(branchFlowLimit, zoneVG_numberOfGenerators, zoneVG_numberOfBatteries, ...
                coefIncreaseCurt, coefDecreaseCurt, coefLowerThreshold, coefUpperThreshold, ...
                curtailmentDelay);


branchFlowState1 = [40 20 20 20 20 20]';
branchFlowState2 = [35 20 20 20 20 20]';
branchFlowState3 = [20 20 20 20 20 20]';
            
% from testDynamicTimeSeries
filenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

zoneVG_startingIterationOfWindForGen = [195 185 175 160]';

zoneVG_samplingTime = 5;

zoneVG_numberOfIterations = 120;
zoneVG_maxGenerationPerGen = [78;66;54;10];



windTimeSeries = DynamicTimeSeries(filenameWindChargingRate, ...
                zoneVG_startingIterationOfWindForGen, zoneVG_samplingTime, ...
                zoneVG_numberOfIterations, zoneVG_maxGenerationPerGen, zoneVG_numberOfGenerators);
            
% Now the test for Telecommunication

zoneVG_delayCommunication = 0;


telecom1 = Telecommunication(zoneVG_delayCommunication, windTimeSeries, limiter1,...
    zoneVG_numberOfGenerators, zoneVG_numberOfBatteries, zoneVG_samplingTime);

[disturbance1, curtailmentControl1, batteryControl1] = telecom1.getControlsAndDisturbance(branchFlowState1);

[disturbance2, curtailmentControl2, batteryControl2] = telecom1.getControlsAndDisturbance(branchFlowState2);

[disturbance3, curtailmentControl3, batteryControl3] = telecom1.getControlsAndDisturbance(branchFlowState3);

[disturbance4, curtailmentControl4, batteryControl4] = telecom1.getControlsAndDisturbance(branchFlowState3);
