## Introduction

In an electrical network, some defined zones are studied for power congestion management objectives. A discrete-time simulation is done, at each iteration, the zones have their states updated, notably, the line power flows are updated through a simulator of power flows for the whole electrical network, based on MATPOWER.

Each zone has its own local controller to make control actions at each time step.
The information from a zone is given to its controller, this exchange of information is based on the interface defined by the abstract class Controller.m.
All controllers inherit this interface/ abstract class to ensure that information is correctly transmitted.

Consequently, if a new controller needs to be created, it has to inherit the abstract class Controller.m.

## Explanation of the controllers
The controllers used in the simulation are now described. The order is based on the time of creation and the context.

0. Controller: Abstract class

1. **Limiter**: for each zone to simulate, e.g. a zone named *zone1*, a JSON file has to be located in ZonalControlSimulator/Settings/Limiter*zone1*.json. This JSON file corresponds to the setting of this controller. The parameters of the JSON file that can be changed are, they are expressed in percentage, i.e. 0.1 means 10%:
    - <ins>IncreaseCurtPercentEchelon</ins>: curtailment control value to **increase** the curtailment state of all generators in the zone
    - <ins>DecreaseCurtPercentEchelon</ins>: curtailment control value to **decrease** the curtailment state of all generators in the zone
    - <ins>UpperThresholdPercent</ins>: if at least one line of the zone has its power flow **over** the **upper** threshold, then the controller takes a control to **increase** the curtailment of all generators in the zone. The control is equal to the value of <ins>IncreaseCurtPercentEchelon</ins>
    - <ins>LowerThresholdPercent</ins>: if at least one line of the zone has its power flow **under** the **lower** threshold, then the controller takes a control to increase the curtailment of all generators in the zone. The control is equal to the value of <ins>IncreaseCurtPercentEchelon</ins>
    
    The situation of no controller in the zone can be represented by providing specific settings to the parameters.

2. **ApproximateLinearMPC**: based on [[1]](#1),[[2]](#2), [[3]](#3). The mathematical model used by this controller is built by ApproximateLinearModel.m.

3. **MixedLogicalDynamicalMPC**: based on [[1]](#1), [[6]](#6), [[7]](#7). The mathematical model used by this controller is built by MixedLogicalDynamicalModel.m.

4. **MixedLogicalDynamicalMPC_PAunknown_DeltaPCreal**: based on [[7]](#7)

5. **ApproximateLinearMPC_PAunknown_DeltaPCreal**: based on [[7]](#7), but not presented in the paper.

6. **FakeApproximateLinearMPC**: at each iteration, both ApproximateLinearMPC and MixedLogicalDynamicalMPC are running, the controls applied to the zone are those of MixedLogicalDynamicalMPC and the controls saved in the workspace are those of the ApproximateLinearMPC. The objective is to compare the behavior of ApproximateLinearMPC with MixedLogicalDynamicalMPC based on the same state at each iteration.

7. **ApproximateLinearMPC_iterative**: obsolete

8. **MixedLogicalDynamicalMPC_PAunknown_DeltaPCreal_coefDeltaPA**: unused and not presented

9. **MpcWithUncertainty**: deprecated

## References
<a id="1">[1]<a>
Iovine, Alessio and Hoang, Duc-Trung and Olaru, Sorin and Maeght, Jean and Panciatici, Patrick and Ruiz, Manuel
Modeling the Partial Renewable Power Curtailment for Transmission Network Management.
2021 IEEE Madrid PowerTech.
[https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v3](https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v3)

<a id="2">[2]<a>
Predictive Control for Zonal Congestion Management of a Transmission Network, 
Duc-Trung Hoang, S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz 
2021 29th Mediterranean Conference on Control and Automation (MED), PUGLIA (virtual), Italy, 2021, MED2021,
[https://hal-centralesupelec.archives-ouvertes.fr/hal-03414267](https://hal-centralesupelec.archives-ouvertes.fr/hal-03414267)

<a id="3">[3]<a>
Power Congestion Management of a sub-Transmission Area Power Network using Partial Renewable Power Curtailment via MPC, 
Duc-Trung Hoang, S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz 
Control and Decision Conference, Austin, Texas, USA, 2021, CDC2021
[https://hal-centralesupelec.archives-ouvertes.fr/hal-03405213](https://hal-centralesupelec.archives-ouvertes.fr/hal-03405213)

<a id="4">[4]<a>
Advanced management of network overload in areas with Renewable Energies Sources, 
Thanh-Hung Pham, S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz 
CPES 2022, Moscow, Russie, 2022
[https://hal-centralesupelec.archives-ouvertes.fr/hal-03616849](https://hal-centralesupelec.archives-ouvertes.fr/hal-03616849)

<a id="5">[5]<a> 
Predictive control based on stochastic disturbance trajectories for congestion management in sub-transmission grids,
Nouha Dkhili,S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz 
18th IFAC Workshop on Control Applications of Optimization, Gif-sur-Yvette, France, 2022, CAO2022
[https://hal.science/hal-03767400](https://hal.science/hal-03767400)

<a id="6">[6]<a> 
Nonlinearity handling in MPC for Power Congestion management in sub-transmission areas, 
Thanh-Hung Pham, S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz
CAO2022, [https://hal.science/hal-03767398](https://hal.science/hal-03767398)

<a id="7">[7]<a>
G. Ganet--Lepage, S. Olaru, A. Iovine, J. Maeght, P. Panciatici, M. Ruiz
Towards a safe maximisation of renewable's flexibility in power transmission sub-grids: An MPC approach
European Control Conference 2023
