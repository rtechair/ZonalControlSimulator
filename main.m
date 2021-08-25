transmission = TransmissionSimulation('simulation.json');

transmission.runSimulation();

isTopologyShown = false;
isResultShown = true;

if isTopologyShown
transmission.plotZonesTopology();
end

if isResultShown
transmission.plotZonesResult();
end