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
        function obj = Zone(name)
            obj.name = name;
        end
    end
end