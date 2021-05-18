function [basecase, basecase_int] = updateGeneration(basecase, basecase_int, zone, instant)
% Update the real power generation of the zone's generators at a given instant, in both external and
% internal basecases
    arguments
        basecase struct
        basecase_int struct {mustBeInternalBasecase(basecase_int)}
        zone {mustBeA(zone, 'Zone')}
        instant (1,1) {mustBeInteger,mustBePositive}
    end
    % TODO: The following comment is not valid for a zone with no generator, yet
    %the simulation should be possible. So improvement on the function
    %required
    %{
    % to update generators On, there must be some generators On and their
    % indices must be known both for the external and internal basecases
    mustBePositive(zone.N_genOn);
    mustBePositive(zone.GenOn_idx);
    mustBePositive(zone.GenOn_int_idx);
    %}
    mustBePositive(zone.N_iteration);
    % instant <= 1 + zone.N_iteration 
    mustBeLessThanOrEqual(instant, 1 + zone.N_iteration);
    
    
    newRealPower = zone.PG(:,instant);
    %{
    if isempty(newRealPower)
        disp('ERROR: zone.PG values at the given instant have not been computed')
        return
    end
    %}
    % update the generation at the given instant, for both external and internal basecases
    basecase.gen(zone.GenOn_idx, 2) = newRealPower;
    basecase_int.gen(zone.GenOn_int_idx,2) = newRealPower;
end