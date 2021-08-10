classdef TransmissionSimulation < handle
   
    %{
Abstract:

INITIALIZATION PRIOR TO THE SIMULATION

- define the basecase used
- define the duration of simulation
- build the basecase as an 'ElectricalGrid' object, which is used during
the simulation
- load the zone setting 
- define the topology of the zone as a 'ZoneTopology' object
- define the time series used for the simulation as a 'TimeSeries' object
- define the simulated zone which is used during the simulation
- load the limiter setting
- define the limiter as a 'Limiter' object

- define the 3 telecommunications used during the simulation
    - TelecomTimeSeries2Zone
    - TelecomController2Zone
    - TelecomZone2Controller

- define the memory to save results of the simulation


INITIALIZATION / FIRST ITERATION OF THE SIMULATION

ITERATIONS OF THE SIMULATION

DISPLAY RESULTS


In this project, column vectors are used instead of row vectors, e.g.
busId, branchIdx, zoneEvolution's properties, etc.
The reason is for consistency with column vectors obtained from Matpower
functions [1].
Hence, rows corresponds to elements, such as buses, branches, generators and
batteries, while columns corresponds to time steps.
 
[1] https://matpower.org/docs/ref/
%}
    properties
       grid
       simulationSetting
       zoneName
       numberOfZones
       zones
       
       duration
       start
       step
       currentTime
    end
   
    methods
        function obj = TransmissionSimulation(filenameSimulation)
            %% set elements
            obj.simulationSetting = decodeJsonFile(filenameSimulation);
            obj.duration = obj.simulationSetting.durationInSeconds;
            obj.step = obj.simulationSetting.windowInSeconds;
            obj.start = obj.step;
            
            obj.setZoneName();
            obj.setNumberOfZones();
            obj.setGrid();
            obj.setZones();
            
            obj.initialize();
            
            obj.runSimulation();
            
            obj.plotZonesTopology();
            obj.plotZonesResult();
        end
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.zoneName = struct2cell(obj.simulationSetting.Zone);
        end
        
        function setNumberOfZones(obj)
            obj.numberOfZones = size(obj.zoneName,1);
        end
        
        function setGrid(obj)
            obj.grid = ElectricalGrid(obj.simulationSetting.basecase);
        end
        
        function setZones(obj)
            obj.zones = cell(obj.numberOfZones,1);
            for i = 1:obj.numberOfZones
                name = obj.zoneName{i};
                obj.zones{i} = Zone(name, obj.grid, obj.duration);
            end
        end
        
        function initialize(obj)
            obj.initializeZonesPowerAvailable();
            obj.initializeZonesPowerGeneration();
            
            obj.updateGridGeneration();
            obj.updateGridBatteryInjection();
            
            obj.grid.runPowerFlow();
            
            obj.updateZonesPowerFlow();
            obj.updateZonesPowerTransit();
            
            % do not compute disturbance transit initially, as there is not enough data
            obj.transmitDataZone2Controller();
            obj.saveZonesState();
            
            obj.dropZonesOldestPowerTransit();
            obj.prepareZonesForNextStep();
        end
        
        function runSimulation(obj)
            for time = obj.start:obj.step:obj.duration
                for i = 1:obj.numberOfZones
                    if obj.zones{i}.isToBeSimulated(time)
                        obj.zones{i}.simulate();
                        obj.zones{i}.updateGrid(obj.grid);
                    end
                end
                
                obj.grid.runPowerFlow()
                
                for i = 1:obj.numberOfZones
                    if obj.zones{i}.isToBeSimulated(time)
                        obj.zones{i}.update(obj.grid);
                        obj.zones{i}.saveResult();
                        obj.zones{i}.prepareForNextStep()
                    end
                end
            end
        end
        
        function initializeZonesPowerAvailable(obj)
            for i = 1:obj.numberOfZones
               obj.zones{i}.initializePowerAvailable();
            end
        end
        
        function initializeZonesPowerGeneration(obj)
           for i = 1:obj.numberOfZones
              obj.zones{i}.initializePowerGeneration();
           end
        end
        
        function updateGridGeneration(obj)
            for i = 1:obj.numberOfZones
               obj.zones{i}.updateGridGeneration(obj.grid);
            end
        end
        
        function updateGridBatteryInjection(obj)
           for i = 1:obj.numberOfZones
              obj.zones{i}.updateGridBattInjection(obj.grid);
           end
        end
        
        function updateZonesPowerFlow(obj)
           for i = 1:obj.numberOfZones
               obj.zones{i}.updatePowerFlow(obj.grid);
           end
        end
        
        function updateZonesPowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.updatePowerTransit(obj.grid);
            end
        end
        
        function dropZonesOldestPowerTransit(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.dropOldestPowerTransit();
            end
        end
        
        function saveZonesState(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.saveState();
            end
        end
        
        function transmitDataZone2Controller(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zones{i}.transmitDataZone2Controller();
            end
        end
        
        function prepareZonesForNextStep(obj)
            % Warning, this method transmits data for all zones, regardless
            % of their control cycles. Thus, be cautious
            for i = 1:obj.numberOfZones
                obj.zones{i}.prepareForNextStep();
            end
        end
        
        function plotZonesTopology(obj)
            for i = 1:obj.numberOfZones
                obj.zones{i}.plotTopology(obj.grid);
            end
        end
        
        function plotZonesResult(obj)
            for i = 1 : obj.numberOfZones
                obj.zones{i}.plotResult(obj.grid);
            end
        end
    end
end