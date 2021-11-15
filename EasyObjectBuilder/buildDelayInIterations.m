%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

function object = buildDelayInIterations(zoneSetting)
    arguments
        zoneSetting ZoneSetting
    end
% create an object of class 'DelayInIterations' by providing an object of class 'ZoneSetting'
    controlCycle = zoneSetting.getControlCycleInSeconds();
    delayCurtInSeconds = zoneSetting.getDelayCurtInSeconds();
    delayBattInSeconds = zoneSetting.getDelayBattInSeconds();
    delayTimeSeries2ZoneInSeconds = zoneSetting.getDelayTimeSeries2ZoneInSeconds;
    delayController2ZoneInSeconds = zoneSetting.getDelayController2ZoneInSeconds;
    delayZone2ControllerInSeconds = zoneSetting.getDelayZone2ControllerInSeconds;

    object = DelayInIterations(controlCycle, delayCurtInSeconds, delayBattInSeconds, ...
                delayTimeSeries2ZoneInSeconds, delayController2ZoneInSeconds, ...
                delayZone2ControllerInSeconds);
end