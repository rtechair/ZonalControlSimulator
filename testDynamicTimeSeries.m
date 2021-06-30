



filenameWindChargingRate = 'tauxDeChargeMTJLMA2juillet2018.txt';

zoneVG_startingIterationOfWindForGen = [195 185 175 160]';

zoneVG_samplingTime = 5;

zoneVG_numberOfIterations = 120;
zoneVG_maxGenerationPerGen = [78;66;54;10];
zoneVG_numberOfGenerators = 4;


windTimeSeries = DynamicTimeSeries(filenameWindChargingRate, ...
                zoneVG_startingIterationOfWindForGen, zoneVG_samplingTime, ...
                zoneVG_numberOfIterations, zoneVG_maxGenerationPerGen, zoneVG_numberOfGenerators);
            

windTimeSeries.getCurrentPowerAvailableVariation()
windTimeSeries.updateCurrentStep()
windTimeSeries.getCurrentPowerAvailableVariation()
