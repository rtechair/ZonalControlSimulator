function cellOfZoneStates = getInitialZoneState(simulationFilename)
% Returns a cell of the initial state of zones. The selection of zones is
% determined by the 'simulationFilename' given as input.
    initialTransmission = TransmissionSimulation(simulationFilename);
    numberOfZones = initialTransmission.getNumberOfZones();
    zones = initialTransmission.getZones();
    
    cellOfZoneStates = cell(numberOfZones,1);
    for z = 1:numberOfZones
        zone = zones{z};
        zoneEvolution = zone.getZoneEvolution();
        state = zoneEvolution.getState();
        cellOfZoneStates{z} = state;
    end
end