%simulateZoneVG;

transmission = TransmissionSimulator('simulation.json');
transmission.setZoneName();
transmission.setNumberOfZones();

transmission.setZoneSetting();
% simulateZoneVTV;