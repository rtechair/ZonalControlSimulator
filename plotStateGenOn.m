function figStateGenOn = plotStateGenOn(basecase,zone, isAxisTemporal, duration, visible)
    % plot for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
    % if isAxisTemporal = true, then 'duration' is necessary and it displays the values over the duration
    % time. Else, displays the values over the number of iterations and
    % 'duration' unnecessary.
    
    arguments
        basecase struct
        zone {mustBeA(zone, 'Zone')}
        isAxisTemporal = false
        duration = -1
        visible = true
    end 
    %% Adapt the x axis legend: either the number of iterations or the temporal duration
    if isAxisTemporal
        if duration == -1
            error(['to display the x axis as a temporal unit', ...
            'provide the duration of the simulation as the 4th attribute of the function'])
        else
            t = 1:zone.Sampling_time:(duration + zone.Sampling_time);
            xlegend = 'Time [s]';
        end
    else
        t = 1:zone.N_iteration+1;
        xlegend = 'Number of iterations';
    end    
    %% Layout of the plot
    n_row_graph = ceil(sqrt(zone.N_bus));
    %% Create the figure
    % see:  https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    figStateGenOn = figure('Name','for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)',...
    'NumberTitle', 'off', 'Visible',visible, 'WindowState', 'maximize'); 
    %% plot for each generator On: PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
    for gen = 1:zone.N_genOn
        % decompose the plot into a n_row_graph x n_row_graph grid, gen is the linear index in the grid
        subplot(n_row_graph, n_row_graph, gen);
        hold on;
        stairs(t, zone.PA(gen,:), ':'); % plot PA
        stairs(t, zone.PC(gen,:), '-.'); % plot PC
        f1 = zone.maxPG(gen) - zone.PC(gen,:);
        stairs(t, f1, '--'); % plot MaxPG - PC
        stairs(t, min(zone.PA(gen,:), f1)); % plot min(PA, MaxPG - PC)
        
        % Description of the subplot
        legend({'PA', 'PC', 'MaxPG - PC' , 'min(PA, MaxPG - PC)'},'Location','Best')
        xlabel(xlegend)
        ylabel('Power [MW]')
        bus_id_of_genOn = basecase.gen(zone.GenOn_idx(gen),1);
        name = ['Gen\_idx: ', int2str(zone.GenOn_idx(gen)), ', at bus: ', int2str(bus_id_of_genOn)];
        title(name);
    end
end