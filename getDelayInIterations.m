function object = getDelayInIterations(zoneSetting)
% create an object of class 'DelayInIterations' by providing an object of class 'ZoneSetting'
    controlCycle = zoneSetting.getcontrolCycleInSeconds();
    delayCurtInSeconds = zoneSetting.getDelayCurtInSeconds();
    delayBattInSeconds = zoneSetting.getDelayBattInSeconds();
    delayTimeSeries2ZoneInSeconds = zoneSetting.getDelayTimeSeries2ZoneInSeconds;
    delayController2ZoneInSeconds = zoneSetting.getDelayController2ZoneInSeconds;
    delayZone2ControllerInSeconds = zoneSetting.getDelayZone2ControllerInSeconds;

    object = DelayInIterations(controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayTimeSeries2ZoneInSeconds, delayController2ZoneInSeconds, ...
                delayZone2ControllerInSeconds);
end