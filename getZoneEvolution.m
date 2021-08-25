function object = getZoneEvolution(zoneSetting, zoneTopology, delayInIterations)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        delayInIterations DelayInIterations
    end
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();

    delayCurt = delayInIterations.getDelayCurt();
    delayBatt = delayInIterations.getDelayBatt();

    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();
    batteryConstantPowerReduction = zoneSetting.getBatteryConstantPowerReduction();
    object = ZoneEvolution(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn,...
                delayCurt, delayBatt, maxPowerGeneration, batteryConstantPowerReduction);
end