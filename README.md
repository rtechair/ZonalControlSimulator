This project is based on Alessio Iovine's code.

It requires:
- Matlab, version R2019b at least
- Matpower: available at https://matpower.org/

To customize a simulation, currently one can modify the scripts with 'Input' in the name:
- the script containing the zone's data, e.g. for zone VG: 'loadInputZoneVG.m'
- the script containing the limiter's parameters, e.g. for zone VG: 'loadInputLimiterZoneVG.m'

Regarding future zones to analyze, one should check the associate buses, branches, generators and batteries already exist in the current matpower case. Otherwise, the matpower case requires to be modified.

New functionalities are tested first on zone VG, correct functioning of zone VTV is not ensured


The Current use case of the simulation is:
- The electrical grid is based on 'case6468rte_zoneVGandVTV.m'.
- The simulation is done on zone VG, which is defined in the 'loadInputZoneVG.m' and caracterized in the basecase.
- A controller, here a simple limiter, determines the controls to take on the zone:
	if the power flow on a branch within the zone is too high, the limiter orders to curtail the production on all generators within the zone
	if the power flows of all branches are too low, the limiter orders to increase the production on all generators within the zone
	else, no control taken
- The time series of power available is provided by 'tauxDeChargeMTJLMA2juillet2018.txt'.
- The telecommunication interfaces between the controller, the time series and the zone, at each iteration of the simulation, to exchande data.
- The topology of zone VG is displayed.
- results of controls taken, informations of generators and branch power flows are displayed.

Visually, the interactions are:

controller
|
|
telecommunication ---------- time series
|
|
simulated zone
|
|
electrical grid
