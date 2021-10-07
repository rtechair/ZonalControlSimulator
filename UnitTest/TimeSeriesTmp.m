chargingRateFilename = 'tauxDeChargeMTJLMA2juillet2018.txt';
windowSimulation = 5;
durationSimulation = 600;
maxPowerGeneration = [20 30 40]';
genStart = [1 200 500]';


simulationTimeSeries = TimeSeries(chargingRateFilename, windowSimulation, ...
    durationSimulation, maxPowerGeneration, genStart);

for k =1:40
    simulationTimeSeries.goToNextStep();
end

simulationTimeSeries.plotProfilePowerAvailable();

simulationTimeSeries.plotProfileDisturbancePowerAvailable();

controlCycle = 15;

modelTimeSeries = TimeSeries(chargingRateFilename, controlCycle,...
    durationSimulation, maxPowerGeneration, genStart);

modelTimeSeries.plotProfilePowerAvailable();
modelTimeSeries.plotProfileDisturbancePowerAvailable();

%{
time = 1:10;
aa = time * 2;
bb = time * 2 + 1;
cc = bb - 4;
dd = time * 0.5 + 6;

fig = figure('Name', 'test');
hold on
stairs(time, aa);
stairs(time, bb);
stairs(time, cc);
stairs(time, dd);
%}
% fig2 = figure('Name', 'gathering');
% gathering = [aa; bb];

% stairs(time, gathering);