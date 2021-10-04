function object = buildTimeSeries(zoneSetting, zoneTopology,...
    samplingTime, simulationDuration)
    arguments
        zoneSetting ZoneSetting
        zoneTopology ZoneTopology
        samplingTime double
        simulationDuration double
    end
    chargingRateFilename = zoneSetting.getTimeSeriesFilename();
    genStart = zoneSetting.getStartGenInSeconds();
    
    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();

    object = TimeSeries(chargingRateFilename, samplingTime, ...
                simulationDuration, maxPowerGeneration, genStart);
end