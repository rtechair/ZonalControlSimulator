## Introduction

This project is based on Alessio Iovine's code and the paper "Modeling the Partial Renewable Power Curtailment for Transmission Network Management":
DOI: 10.1109/PowerTech46648.2021.9494993 https://ieeexplore.ieee.org/abstract/document/9494993; alternatively:
HAL Id: hal-0300444 https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v2/document

Specifically, the paper describes a mathematical model, which approximates linearly the dynamic of a zone within a electrical grid. Real power flows of the electrical grid is computed using Matpower, while controllers supervising the studied zones will use the mathematical model to take actions.

## Installation

### Requirements
- Matlab, version R2019b at least
- Matpower: available at https://matpower.org/

### Download the project
in the repository where you want to install the project:

*With Git*
```
git clone https://github.com/rtechair/ZonalControlSimulator
```
*Else*

In https://github.com/rtechair/ZonalControlSimulator, click the green button 'code', download zip and extract it.

### Set up search paths for matlab
If you work on this project through the `main` file, no action is needed. 

However, if you intend to work with matlab in a different repository and call the transmission simulator, then the search paths of matlab need to be updated:
1) open matlab in the repository of the simulator
2) In the command window, type:
```
addpath(genpath(pwd))
rmpath(genpath([pwd filesep '.git'])) % remove useless .git paths, which are intrinsic to git
savepath % might need to run matlab as admin to be valid
```


## Simulator of transmission
The intent is to study the power flows of specific zones, by simulating the electrical grid containing the zones. 
Zones are made of buses, i.e. nodes, and branches, i.e. edges. On some buses, there are generators, and possibly batteries. 
There is one controller per zone, which takes decisions on generators and batteries within its zone. The decisions are partial curtailments for generators and battery injections. 
A time Series is provided to describe the evolution of power available for the generators as they are wind turbines.
They are telecommunications that represents the transfer of information within a zone: the controls from the controller to the zone, the power available from the time series to the zone, and states of a the zone for the controller.

Visually, the interactions are for 2 zones:
```
	______electrical grid____
	|			|
	zone			zone
	|			|
	telecom			telecom
	|      |		|      |
controller  time series   controller  time series
```

The current use case of the simulation is:
- simulate the zones and the electrical grid over the time period.
- A controller, here a simple limiter, determines the controls to take on the zone:
	if the power flow on a branch within the zone is too high, the limiter orders to curtail the production on all generators within the zone.
	if the power flows of all branches are too low, the limiter orders to increase the production on all generators within the zone.
	else, no control taken.
- the transmission of information through the telecommunications between the controller and the zone is delayed, in both directions.
- the transmission of information through the telecommunication from the time series to the zone is not delayed.
- the different zones do not have a common 'control cycle' (frequency of update), the transmission simulator handles the asynchronous scheluding of the zones.


Regarding the results of the simulation, for each zone is displayed :
- the topology
- the power flows
- the state elements of generators
- the control and disturbances of generators
- the disturbance of transit power

Because the limiter takes no action on the batteries, no information regarding the batteries is currently displayed.

Regarding the setting of the simulation, it is mostly based on 3 types of data, all in json files:
- the simulation setting, with 'simulation.json':
	- the basecase: e.g. "case6468rte_zone_VG_VTV_BLA.m"
	- the duration of the simulation
	- the time step of the global simulator, called 'window'
	- the studied zones: e.g. VG, VTV, BLA
- the setting of the studied zones, each requires a json file of the form = 'zone[zoneName].json', where [zoneName] can be :VG, VTV, BLA. e.g. 'zoneVG.json'.
- the setting of the limiter of the studied zones, each requires a json file of the form = 'limiter[zoneName].json', where [zoneName] can be: VG, VTV, BLA, e.g. 'zoneBLA.json'.

Miscellaneous information:
- The time series of power available is provided by 'tauxDeChargeMTJLMA2juillet2018.txt'.
It is the same for each generator, an offset is defined per generator in the setting of the zone.


Regarding future zones to analyze, one should check the associate buses, branches, generators and batteries already exist in the current matpower case. Otherwise, the matpower case requires to be modified with the use of the class 'BasecaseModification'.

Precedent works were mostly tested on zone VG, now present and future works will be tested on all 3 zones: VG, VTV and BLA.
