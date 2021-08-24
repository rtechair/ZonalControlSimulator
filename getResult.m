function object = getResult(zoneSetting, zoneTopology, delayInIterations, duration, name)
    controlCycle = zoneSetting.getcontrolCycleInSeconds();
    numberOfBuses = zoneTopology.getNumberOfBuses();
    numberOfBranches = zoneTopology.getNumberOfBranches();
    numberOfGenOn = zoneTopology.getNumberOfGenOn();
    numberOfBattOn = zoneTopology.getNumberOfBattOn();
    maxPowerGeneration = zoneTopology.getMaxPowerGeneration();
    branchFlowLimit = zoneSetting.getBranchFlowLimit();

    busId = zoneTopology.getBusId();
    branchIdx = zoneTopology.getBranchIdx();
    genOnIdx = zoneTopology.getGenOnIdx();
    battOnIdx = zoneTopology.getBattOnIdx();

    delayCurt = delayInIterations.getDelayCurt();
    delayBatt = delayInIterations.getDelayBatt();
    delayTimeSeries2Zone = delayInIterations.getDelayTimeSeries2Zone();
    delayController2Zone = delayInIterations.getDelayController2Zone();
    delayZone2Controller = delayInIterations.getDelayZone2Controller();

    object = ResultGraphic(name, duration, controlCycle,...
                numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, ...
                maxPowerGeneration, branchFlowLimit, ...
                busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller);
end