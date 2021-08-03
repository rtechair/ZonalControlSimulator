classdef TransmissionSimulator < handle
    
    properties
        SimulationSetting % struct
        ZoneName % cell
        NumberOfZones % number
        ZoneSetting % cell
        
        Grid
        Topology
        TimeSeries
        Zone
    end
    
    
    methods
        function obj = TransmissionSimulator(filenameSimulation)
            obj.SimulationSetting = decodeJsonFile(filenameSimulation);
            
            obj.setZoneName();
            obj.setNumberOfZones();
            obj.setZoneSetting();
            
            obj.setGrid();
            obj.setTopology();
            obj.setTimeSeries();
        end
        
        
        function setZoneName(obj)
            % the 'cell' data structure is used instead of 'matrix'.
            % A matrix merges char arrays into a single char array, which
            % would concatenate the zone names, which is not the desired behavior.
           obj.ZoneName = struct2cell(obj.SimulationSetting.Zone); 
        end
        
        function setNumberOfZones(obj)
            obj.NumberOfZones = size(obj.ZoneName,1);
        end
        
        function zoneFilename = getZoneFilename(obj, zoneNumber)
            zoneFilename = ['zone' obj.ZoneName{zoneNumber} '.json'];
        end
        
        function setZoneSetting(obj)
            obj.ZoneSetting = cell(obj.NumberOfZones,1);
            for zoneNumber = 1:obj.NumberOfZones
                obj.setOneZoneSetting(zoneNumber);
            end
        end
        
        function setOneZoneSetting(obj, zoneNumber)
            filename = obj.getZoneFilename(zoneNumber);
            obj.ZoneSetting{zoneNumber} = decodeJsonFile(filename);
        end
        
        function setGrid(obj)
           obj.Grid = ElectricalGrid(obj.SimulationSetting.basecase);
        end
        
        function setTopology(obj)
           obj.Topology = cell(obj.NumberOfZones, 1);
           for zoneNumber = 1:obj.NumberOfZones
               obj.setOneTopology(zoneNumber);
           end
        end
        
        function setOneTopology(obj, zoneNumber)
            name = obj.ZoneName(zoneNumber);
            busId = obj.ZoneSetting{zoneNumber}.busId;
            obj.Topology{zoneNumber} = ZoneTopology(name, busId, obj.Grid);
        end
        
        function setTimeSeries(obj)
            obj.TimeSeries = cell(obj.NumberOfZones,1);
            for zoneNumber = 1: obj.NumberOfZones
                obj.setOneTimeSeries(zoneNumber);
            end
        end
        
        function setOneTimeSeries(obj, zoneNumber)
            filename = obj.ZoneSetting{zoneNumber}.TimeSeries.filename;
            timeSeriesSetting = obj.ZoneSetting{zoneNumber}.TimeSeries;

            startPossibility = struct2cell(timeSeriesSetting.StartPossibilityForGeneratorInSeconds);
            startSelected = timeSeriesSetting.startSelected;
            start = startPossibility{startSelected};
            controlCycle = obj.ZoneSetting{zoneNumber}.controlCycle;
            duration = obj.SimulationSetting.durationInSeconds;
            maxPowerGeneration = obj.Topology{zoneNumber}.MaxPowerGeneration;
            numberOfGenOn = obj.Topology{zoneNumber}.NumberOfGen;
            obj.TimeSeries{zoneNumber} = TimeSeriesRenewableEnergy(filename, start, controlCycle, duration, maxPowerGeneration, numberOfGenOn);
                        
        end
            
    end
end