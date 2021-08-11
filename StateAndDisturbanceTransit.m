classdef StateAndDisturbanceTransit < handle
    
   properties
      stateOfZone
      disturbanceTransit
   end
    
   methods
       function obj = StateAndDisturbanceTransit(stateOfZone, disturbanceTransit)
           obj.stateOfZone = stateOfZone;
           obj.disturbanceTransit = disturbanceTransit;
                       
       end
       
       function state = getStateOfZone(obj)
           state = obj.stateOfZone;
       end
       
       function distTransit = getDisturbanceTransit(obj)
           distTransit = obj.disturbanceTransit;
       end
   end
end