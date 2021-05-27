function figureFlowBranch = plotFlowBranch(basecase, zone, isAxisTemporal, duration)
    % Plot for each branch of the zone, the power flow over the period
    % if isAxisTemporal = true, then 'duration' is necessary and it displays the values over the duration
    % time. Else, displays the values over the number of iterations and 'duration' unnecessary.
    arguments
        basecase struct
        zone {mustBeA(zone,'Zone')}
        isAxisTemporal = false
        duration = -1
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
    n_row_graph = ceil(sqrt(zone.N_branch));
    %% Create the figure
    % see: https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    figureFlowBranch = figure('Name', 'power flow on each branch of the zone, over the period',...
        'NumberTitle', 'off', 'WindowState', 'maximize');
    %% Plot for each branch
    for br = 1:zone.N_branch
        subplot(n_row_graph, n_row_graph, br);
        hold on;
        stairs(t, zone.Fij(br,:)); % plot Fij
        % Description of the subplot
        legend({'Branch Power Flow'},'Location','Best')
        xlabel(xlegend)
        ylabel('Power [MW]')
        branch_idx = zone.Branch_idx(br,1);
        fbus_and_tbus = basecase.branch(branch_idx,1:2); % return [fbus tbus]
        name = ['Branch index: ', int2str(branch_idx), ', with from bus: ', int2str(fbus_and_tbus(1)), ', and to bus: ', int2str(fbus_and_tbus(2))];
        title(name);
    end
end