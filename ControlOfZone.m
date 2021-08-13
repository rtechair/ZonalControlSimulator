classdef ControlOfZone < handle
% Wrapper class of the 2 controls defined by the controller:
% the control of the generator curtailments
% the control of the battery injections
   properties
       controlCurtailment
       controlBattery
   end
   
   methods
       function obj = ControlOfZone(controlCurtailment, controlBattery)
           obj.controlCurtailment = controlCurtailment;
           obj.controlBattery = controlBattery;
       end
       
       function modifyControl(obj, valueToAdd)
           % The telecommunication from the controller to the zone can modify the values
           obj.modifyControlCurtailment(valueToAdd);
           obj.modifyControlBattery(valueToAdd);
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