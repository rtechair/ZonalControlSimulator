classdef ControlOfZone < handle
    
   properties
       ControlCurtailment
       ControlBattery
   end
   
   properties (SetAccess = immutable)
       NumberOfGen
       NumberOfBatt
   end
   
   methods 
       
       function obj = ControlOfZone(numberOfGenerators, numberOfBatteries)
           obj.NumberOfGen = numberOfGenerators;
           obj.NumberOfBatt = numberOfBatteries;
           
           obj.ControlCurtailment = zeros(numberOfGenerators,1);
           obj.ControlBattery = zeros(numberOfBatteries,1);
       end
       
       
       function modifyControl(obj, valueToAdd)
           obj.modifyControlCurtailment(valueToAdd);
           obj.modifyControlBattery(valueToAdd);
       end
       
       function setControlCurtailment(obj, value)
           obj.ControlCurtailment = value;
       end
       
       
       function setControlBattery(obj, value)
           obj.ControlBattery = value;
       end
       
   end
   
   methods (Access = protected)
       function modifyControlCurtailment(obj, valueToAdd)
           obj.ControlCurtailment = obj.ControlCurtailment + valueToAdd;
       end
       
       function modifyControlBattery(obj, valueToAdd)
           obj.ControlBattery = obj.ControlBattery + valueToAdd;
       end
   end
    
end