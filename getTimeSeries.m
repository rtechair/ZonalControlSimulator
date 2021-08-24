function object = getTimeSeries(zoneSetting, zoneTopology, simulationDuration)
    timeSeriesFilename = zoneSetting.getTimeSeriesFilename();
    startGenInSeconds = zoneSetting.getStartGenInSeconds();
    controlCycle = zoneSetting.getcontrolCycleInSeconds();

    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    object = TimeSeries(timeSeriesFilename, startGenInSeconds, controlCycle, ...
        simulationDuration, maxPowerGeneration, numberOfGenOn);
end