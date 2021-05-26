function plotStateGenOn(basecase,zone, duration, isAxisRealTime)
    arguments
        basecase
        zone
        duration
        isAxisRealTime = false
    end
    % plot for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
    if isAxisRealTime
        t = 0:zone.Sampling_time:duration;
        xlegend = 'Time [s]';
    else
        t = 1:zone.N_iteration+1;
        xlegend = 'Number of iterations';
    end
    % Layout on 2 rows or 3 if they are many subplots
    if zone.N_bus >= 9
        n_row_graph = 3;
    else
        n_row_graph = 2;
    end
    fGen = figure('Name','for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)',...
    'NumberTitle', 'off'); 
    % see for more info about figures: 
    % https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    % https://www.mathworks.com/help/matlab/ref/figure.html
    fGen.WindowState = 'maximize';
    % plot for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
    for gen = 1:zone.N_genOn
        subplot(n_row_graph, n_row_graph, gen); ...
            hold on; ...
            stairs(t, zone.PA(gen,:)); ...
            stairs(t, zone.PC(gen,:)); ...
            f1 = zone.maxPG(gen) - zone.PC(gen,:);
            stairs(t, f1);...
            stairs(t, min(zone.PA(gen,:), f1));
            % Description of the subplot
            legend({'PA', 'PC', 'MaxPG - PC' , 'min(PA, MaxPG - PC)'},'Location','Best')
            xlabel(xlegend)
            ylabel('Power [MW]')
            bus_id_of_genOn = basecase.gen(zone.GenOn_idx(gen),1);
            name = ['Gen\_idx: ', int2str(zone.GenOn_idx(gen)), ', at bus: ', int2str(bus_id_of_genOn)];
            title(name);
    end
end