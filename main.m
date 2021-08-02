%simulateZoneVG;

transmission = TransmissionSimulator('simulation.json');
transmission.setZoneName();
transmission.setNumberOfZones();

transmission.setZoneFilename();
transmission.setZoneSetting();
% simulateZoneVTV;