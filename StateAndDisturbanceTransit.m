classdef StateAndDisturbanceTransit < handle
% Wrapper class of an object STATE + a value DISTURBANCE TRANSIT
% such that the telecommunication, from the zone to the controller,
% manipulates 1 object instead 1 object + 1 value.
   properties
      stateOfZone
      disturbanceTransit
   end
    
   methods
       function obj = StateAndDisturbanceTransit(objectStateOfZone, valueDisturbanceTransit)
           obj.stateOfZone = objectStateOfZone;
           obj.disturbanceTransit = valueDisturbanceTransit;
       end
       
       function object = getStateOfZone(obj)
           object = obj.stateOfZone;
       end
       
       function value = getDisturbanceTransit(obj)
           value = obj.disturbanceTransit;
       end
   end
end