%simulateZoneVG;

transmission = TransmissionSimulator('simulation.json');
transmission.setZoneName();
transmission.setNumberOfZones();

transmission.setZoneFileName();
transmission.setZoneSetting();
% simulateZoneVTV;