function object = buildTimeSeries(zoneSetting, zoneTopology,...
    simulationWindow, simulationDuration)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        simulationWindow double
        simulationDuration double
    end
    chargingRateFilename = zoneSetting.getTimeSeriesFilename();
    genStart = zoneSetting.getStartGenInSeconds();
    
    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();

    object = TimeSeries(chargingRateFilename, simulationWindow, ...
                simulationDuration, maxPowerGeneration, genStart);
end