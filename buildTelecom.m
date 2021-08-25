function [telecomTimeSeries2Zone, telecomController2Zone, telecomZone2Controller] = buildTelecom(...
    zoneTopology, delayInIterations)
    arguments
        zoneTopology ZoneTopology
        delayInIterations DelayInIterations
    end
    telecomTimeSeries2Zone = buildTelecomTimeSeries2Zone(zoneTopology, delayInIterations);
    telecomController2Zone = buildTelecomController2Zone(zoneTopology, delayInIterations);
    telecomZone2Controller = buildTelecomZone2Controller(zoneTopology, delayInIterations);
end

function object = buildTelecomTimeSeries2Zone(zoneTopology, delayInIterations)
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    delayTimeSeries2Zone = delayInIterations.getDelayTimeSeries2Zone();
    object = TelecomTimeSeries2Zone(numberOfGenOn, delayTimeSeries2Zone);
end

function object = buildTelecomController2Zone(zoneTopology, delayInIterations)
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    delayController2Zone = delayInIterations.getDelayController2Zone();
    object = TelecomController2Zone(...
                numberOfGenOn, numberOfBattOn, delayController2Zone);
end

function object = buildTelecomZone2Controller(zoneTopology, delayInIterations)
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    delayZone2Controller = delayInIterations.getDelayZone2Controller();
    object = TelecomZone2Controller(...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, delayZone2Controller);
end