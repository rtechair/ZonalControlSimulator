classdef Zone < handle
   
    properties
       name
       setting
       topology
       zoneEvolution
       
       telecomZone2Controller
       telecomController2Zone
       telecomTimeSeries2Zone
       
       controller
       timeSeries
    end
    
    methods
        function obj = Zone(name, electricalGrid)
            obj.name = name;
            obj.setSetting();
            obj.setTopology(electricalGrid);
        end
        
        function setSetting(obj)
            filename = obj.getFilename();
            obj.setting = decodeJsonFile(filename);
        end
        
        function zoneFilename = getFilename(obj)
            zoneFilename = ['zone' obj.name '.json'];
        end
        
        function setTopology(obj, electricalGrid)
           busId = obj.setting.busId;
           obj.topology = ZoneTopology(obj.name, busId, electricalGrid);
        end
    end
end