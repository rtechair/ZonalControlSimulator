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
                filename = obj.getZoneFilename(zoneNumber);
               obj.ZoneSetting{zoneNumber} = decodeJsonFile(filename);
            end
        end
        
        function setGrid(obj)
           obj.Grid = ElectricalGrid(obj.SimulationSetting.basecase);
        end
        
        function setTopology(obj)
           obj.Topology = cell(obj.NumberOfZones, 1);
           for zoneNumber = 1:obj.NumberOfZones
               name = obj.ZoneName{zoneNumber};
               busId = obj.ZoneSetting{zoneNumber}.busId;
              obj.Topology{zoneNumber} = ZoneTopology(name, busId, obj.Grid); 
           end
        end
            
    end
end