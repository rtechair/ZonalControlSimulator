function MATPOWERfile_generic = case_generic
% case_generic describes an empty MATPOWER file

%% MATPOWER Case Format : Version 2
MATPOWERfile_generic.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
MATPOWERfile_generic.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
MATPOWERfile_generic.bus = [
	   
];

%% generator data
%	bus	Pg	  Qg	Qmax	Qmin	Vg	    mBase	status  Pmax Pmin Pc1 Pc2 Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
MATPOWERfile_generic.gen = [
	
];

%% branch data
%	fbus	tbus	r     x	     b	  rateA	 rateB	rateC	ratio	angle	status	angmin	angmax
MATPOWERfile_generic.branch = [
	
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
MATPOWERfile_generic.gencost = [

];
