classdef StateAndDisturbanceTransit < handle
    
   properties
      StateOfZone
      DisturbancePowerInTransit
   end
    
   methods
       function obj = StateAndDisturbanceTransit(stateOfZone, disturbancePowerInTransit)
           obj.StateOfZone = stateOfZone;
           obj.DisturbancePowerInTransit = disturbancePowerInTransit;
                       
       end
       
       function state = getStateOfZone(obj)
           state = obj.StateOfZone;
       end
       
       function distTransit = getDisturbanceTransit(obj)
           distTransit = obj.DisturbancePowerInTransit;
       end
   end
end