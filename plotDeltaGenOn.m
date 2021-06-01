function figDeltaGenOn = plotdeltaGenOn(basecase, zone, isAxisTemporal)
    % plot for each generator On: DeltaPA, DeltaPG, DeltaPC, DeltaPC(step-zone.Delay_curt).
    % if isAxisTemporal = true, then 'duration' is necessary and it displays the values over the duration
    % time. Else, displays the values over the number of iterations and 'duration' unnecessary.
    
    arguments
        basecase struct
        zone {mustBeA(zone, 'Zone')}
        isAxisTemporal = false
    end  
    %% Adapt the x axis legend: either the number of iterations or the temporal duration
    if isAxisTemporal
        t = 1:zone.SamplingTime:zone.Duration;
        xlegend = 'Time [s]';
    else
        t = 1:zone.NumberIteration;
        xlegend = 'Number of iterations';
    end   
    %% Layout of the plot
    n_row_graph = ceil(sqrt(zone.NumberBus));
    %% Create the figure
    % see: https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    figDeltaGenOn = figure('Name','for each generator On : DeltaPA, DeltaPG, DeltaPC, DeltaPC(step - delay_curt + 1)',...
    'NumberTitle', 'off', 'WindowState', 'maximize'); 
    %% plot for each generator On: DeltaPA, DeltaPG, DeltaPC, DeltaPC(step - zone.Delay_curt)
    for gen = 1:zone.NumberGenOn
        % decompose the plot into a n_row_graph x n_row_graph grid, gen is
        % the linear index in the grid
        subplot(n_row_graph, n_row_graph, gen);
        hold on;
        stairs(t, zone.DeltaPA(gen,:), ':'); % plot DeltaPA
        stairs(t, zone.DeltaPG(gen,:), '-.'); % plot DeltaPG
        stairs(t, zone.DeltaPC(gen,:), '--'); % plot DeltaPC: control taken
        f1 = [ zeros(1, zone.DelayCurt+1) zone.DeltaPC(gen, 1 : zone.NumberIteration - zone.DelayCurt -1)];
        stairs(t, f1); % plot DeltaPC(step + delay_curt): control applied
        
        % Description of the subplot
        legend({'DeltaPA', 'DeltaPG', 'DeltaPC: control taken', 'DeltaPC(step+delay\_curt+1): control applied'},'Location','Best')
        xlabel(xlegend)
        ylabel('Power [MW]')
        bus_id_of_genOn = basecase.gen(zone.GenOnIdx(gen),1);
        name = ['Gen\_idx: ', int2str(zone.GenOnIdx(gen)), ', at bus: ', int2str(bus_id_of_genOn)];
        title(name);
    end
end
        
            
    