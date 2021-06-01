function figureFlowBranch = plotFlowBranch(basecase, zone, isAxisTemporal)
    % Plot for each branch of the zone, the power flow over the period
    % if isAxisTemporal = true, then 'duration' is necessary and it displays the values over the duration
    % time. Else, displays the values over the number of iterations and 'duration' unnecessary.
    arguments
        basecase struct
        zone {mustBeA(zone,'Zone')}
        isAxisTemporal = false
    end
    %% Adapt the x axis legend: either the number of iterations or the temporal duration
    if isAxisTemporal
        t = 1:zone.SamplingTime:(zone.Duration + zone.SamplingTime);
        xlegend = 'Time [s]';
    else
        t = 1:zone.NumberIteration+1;
        xlegend = 'Number of iterations';
    end
    %% Layout of the plot
    n_row_graph = ceil(sqrt(zone.NumberBranch));
    %% Create the figure
    % see: https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
    figureFlowBranch = figure('Name', 'power flow on each branch of the zone, over the period',...
        'NumberTitle', 'off', 'WindowState', 'maximize');
    %% Plot for each branch
    for br = 1:zone.NumberBranch
        subplot(n_row_graph, n_row_graph, br);
        hold on;
        stairs(t, zone.Fij(br,:)); % plot Fij
        % Description of the subplot
        legend({'Branch Power Flow'},'Location','Best')
        xlabel(xlegend)
        ylabel('Power [MW]')
        branch_idx = zone.BranchIdx(br,1);
        fbus_and_tbus = basecase.branch(branch_idx,1:2); % return [fbus tbus]
        name = ['Branch index: ', int2str(branch_idx), ', with from bus: ', int2str(fbus_and_tbus(1)), ', and to bus: ', int2str(fbus_and_tbus(2))];
        title(name);
    end
end