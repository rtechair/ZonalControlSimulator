This project is based on Alessio Iovine's code and the paper "Modeling the Partial Renewable Power Curtailment for Transmission Network Management"
HAL Id: hal-0300444
available at: https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v2/document

Specifically, the paper describes a mathematical model, which approximates linearly the dynamic of a zone within a electrical grid. Real power flows of the electrical grid is computed using Matpower, while controllers supervising the studied zones will use the mathematical model to take actions.
 
The code requires:
- Matlab, version R2019b at least
- Matpower: available at https://matpower.org/

Transmission simulator:
The intent is to study the power flows of specific zones, by simulating the electrical grid containing the zones. 
Zones are made of buses, i.e. nodes, and branches, i.e. edges. On some buses, there are generators, and possibly batteries. There is one controller per zone, which takes decisions on generators and batteries within its zone. The decisions are partial curtailments for generators and battery injections.
Dynamic Time Series are provided to describe the evolution of power available for the generators as they are wind turbines.
They are telecommunications that represents the transfer of information within a zone: the controls from the controller to the zone, the power available from the time series to the zone, and states of a the zone for the controller.

Visually, the interactions are for 2 zones:

	______electrical grid____
	|			|
	zone			zone
	|			|
	telecom			telecom
	|      |		|      |
controller  time series   controller  time series


The Current use case of the simulation is:
- The electrical grid is based on the basecase 'case6468rte_zoneVGandVTV.m'.
- The studied zone is: zone VG, which is defined in 'zoneVG.json' and caracterized in the basecase.
- A controller, here a simple limiter, determines the controls to take on the zone:
	if the power flow on a branch within the zone is too high, the limiter orders to curtail the production on all generators within the zone
	if the power flows of all branches are too low, the limiter orders to increase the production on all generators within the zone
	else, no control taken
- The time series of power available is provided by 'tauxDeChargeMTJLMA2juillet2018.txt'
- The telecommunications have no delay
- The topology of zone VG is displayed
- results of controls taken, informations of generators, branch power flows and disturbance of powers transiting through the zone are displayed.


% TODO, the following is no more true, now it is done with JSON files.
To customize a simulation, currently one can modify the scripts with 'Input' in the name:
- the script containing the zone's data, e.g. for zone VG: 'loadInputZoneVG.m'
- the script containing the limiter's parameters, e.g. for zone VG: 'loadInputLimiterZoneVG.m'

Regarding future zones to analyze, one should check the associate buses, branches, generators and batteries already exist in the current matpower case. Otherwise, the matpower case requires to be modified.

New functionalities are tested first on zone VG, correct functioning of zone VTV is not ensured





