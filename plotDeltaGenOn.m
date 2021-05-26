function fGen = plotdeltaGenOn(basecase, zone, isAxisTemporal, duration)
    % plot for each generator On: DeltaPA, DeltaPG, DeltaPC, DeltaPC(step-zone.Delay_curt).
    % if isAxisTemporal = true, then 'duration' is necessary and it displays the values over the duration
    % time. Else, displays the values over the number of iterations and
    % 'duration' unnecessary.
    
    arguments
        basecase struct
        zone {mustBeA(zone, 'Zone')}
        isAxisTemporal = false
        duration = -1
    end
    
    %% Adapt the x axis legend: either the number of iterations or the temporal duration
    if isAxisTemporal
        if duration == -1
            error(['to display the x axis as a temporal unit', ...
            'provide the duration of the simulation as the 4th attribute of the function'])
        else
            t = 1:zone.Sampling_time:duration;
            xlegend = 'Time [s]';
        end
    else
        t = 1:zone.N_iteration;
        xlegend = 'Number of iterations';
    end
    
    %% Layout on 2 rows or 3 if they are many subplots
    if zone.N_bus >= 9
        n_row_graph = 3;
    else
        n_row_graph = 2;
    end
    fGen = figure('Name','for each generator On : DeltaPA, DeltaPG, DeltaPC, DeltaPC(step - delay_curt + 1)',...
    'NumberTitle', 'off'); 
    % see for more info about figures: 
    % https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    % https://www.mathworks.com/help/matlab/ref/figure.html
    fGen.WindowState = 'maximize';
    
    %% plot for each generator On: DeltaPA, DeltaPG, DeltaPC, DeltaPC(step - zone.Delay_curt)
    for gen = 1:zone.N_genOn
        % decompose the plot into a n_row_graph x n_row_graph grid, gen is
        % the linear index in the grid
        subplot(n_row_graph, n_row_graph, gen);
        hold on;
        stairs(t, zone.DeltaPA(gen,:)); % plot DeltaPA
        stairs(t, zone.DeltaPG(gen,:)); % plot DeltaPG
        stairs(t, zone.DeltaPC(gen,:)); % plot DeltaPC: control taken
        
        f1 = [ zeros(1, zone.Delay_curt+1) zone.DeltaPC(gen, 1 : zone.N_iteration - zone.Delay_curt -1)];
        stairs(t, f1); % plot DeltaPC(step + delay_curt): control applied
        
        % Description of the subplot
        legend({'DeltaPA', 'DeltaPG', 'DeltaPC: control taken', 'DeltaPC(step+delay\_curt+1): control applied'},'Location','Best')
%         legend({'DeltaPA', 'DeltaPG', 'DeltaPC: control taken'},'Location','Best')
        xlabel(xlegend)
        ylabel('Power [MW]')
        bus_id_of_genOn = basecase.gen(zone.GenOn_idx(gen),1);
        name = ['Gen\_idx: ', int2str(zone.GenOn_idx(gen)), ', at bus: ', int2str(bus_id_of_genOn)];
        title(name);
    end
end
        
            
    