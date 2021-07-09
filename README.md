This project is based on Alessio Iovine's code.

It requires:
- Matlab, version R2019b at least
- Matpower: available at https://matpower.org/

To customize a simulation, currently one can modify the scripts with 'Input' in the name:
- the script containing the zone's data, e.g. for zone VG: 'loadInputZoneVG.m'
- the script containing the limiter's parameters, e.g. for zone VG: 'loadInputLimiterZoneVG.m'

Regarding future zones to analyze, one should check the associate buses, branches, generators and batteries already exist in the current matpower case. Otherwise, the matpower case requires to be modified.

New functionalities are tested first on zone VG, correct functioning of zone VTV is not ensured




