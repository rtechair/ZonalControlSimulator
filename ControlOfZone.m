classdef ControlOfZone < handle
    
   properties
       controlCurtailment
       controlBattery
   end
   
   properties (SetAccess = immutable)
       numberOfGen
       numberOfBatt
   end
   
   methods 
       
       function obj = ControlOfZone(numberOfGenerators, numberOfBatteries)
           obj.numberOfGen = numberOfGenerators;
           obj.numberOfBatt = numberOfBatteries;
           
           obj.controlCurtailment = zeros(numberOfGenerators,1);
           obj.controlBattery = zeros(numberOfBatteries,1);
       end
       
       function modifyControl(obj, valueToAdd)
           obj.modifyControlCurtailment(valueToAdd);
           obj.modifyControlBattery(valueToAdd);
       end
       
       function setControlCurtailment(obj, value)
           obj.controlCurtailment = value;
       end
       
       function setControlBattery(obj, value)
           obj.controlBattery = value;
       end
       
   end
   
   methods (Access = protected)
       function modifyControlCurtailment(obj, valueToAdd)
           obj.controlCurtailment = obj.controlCurtailment + valueToAdd;
       end
       
       function modifyControlBattery(obj, valueToAdd)
           obj.controlBattery = obj.controlBattery + valueToAdd;
       end
   end
    
end