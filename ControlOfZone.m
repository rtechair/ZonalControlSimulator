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
       
   end
   
end