zone1 = transmission.zones{1,1};
%zoneTopo = zone1.plotTopology();

PF = zone1.simulationResult.powerBranchFlow;
PG = zone1.simulationResult.powerGeneration;
PB = zone1.simulationResult.powerBattery;

%YData = [ -0.415951495227916	-0.674636148266477	0.286485719376299
%1.41248525968367	0.752762415074867	0.113871536787528	-1.29479967972957
%-1.39292669404119	-0.492659083840632	1.92376974789167	0.841320890034722	-1.05972246774296]';

% XData = [0.252419155042797	-0.479647290011193	-0.165850421477164
% 1.15010842131387	0.607520501000233	0.710935814370589	-0.123824234540511
% -0.678453363807735	-1.15529215516829	1.57285441642177	-0.571832469130772	-1.11893837401359]';

busId = [1445
               2076
            2135
            2745
            4720
            10000];
busString = string(busId);
duration = 1200;
window = 5;
n_steps = duration/window;

G = zone1.topology.staticGraph;
G.Edges.Weight = zeros(16,1);
figure('Name','Dynamical evolution', 'WindowState', 'maximize')
P = plot(G, "Layout","force");

P.NodeColor = 'k'; % k = black
P.NodeFontSize = 16;
P.MarkerSize = 12; % node size
% Edge
P.EdgeColor = 'k';
P.LineWidth = 3;
P.EdgeLabelColor = 'k';
P.ArrowSize = 10;
highlight(P, busString, 'NodeColor', 'r')
%layout(P, 'force');
%plot(graph1, 'XData', zoneTopo.XData, 'YData',zoneTopo.YData);

isDynamical = true;
threshold = 45;
if isDynamical
    for k = 1:n_steps
        if rem(k, 2) == 0
            arrowPos = 0.4;
        else
            arrowPos = 0.7;
        end
        %currentPF = [PF(:,k); zeros(9,1)] ;
        %currentPF = [ PF(1, k); PF(3,k) ; PF(6,k) ; zeros(2,1) ; PF(2, k); PF(5,k) ; 0 ; PF(4, k) ; PF(7,k) ; zeros(6,1)];
        currentPF = [ PF(1, k); PF(3,k) ; PF(6,k) ; NaN(2,1) ; PF(2, k); PF(5,k) ; NaN ; PF(4, k) ; PF(7,k) ; NaN(6,1)];
        G.Edges.Weight = currentPF;
        %currentPG = [PG(2,k); 0; PG(3,k); 0; PG(1,k); PG(4,k); zeros(6,1) ];
        %G.Nodes.Name = string(currentPG);
        %
        P = plot(G, 'EdgeLabel', G.Edges.Weight,'Layout', 'force' ,'ArrowPosition',arrowPos);
        % Gen
        labelnode(P, '2745', string(PG(2,k)));
        labelnode(P, '4720', string(PG(3,k)));
        labelnode(P, '2076', string(PG(1,k)));

        %cc = [num2str(aa,3), '   ', num2str(bb,3)]
        gen_batt = [num2str(PG(4,k),3), '       ', num2str(PB(1,k),3)];
        %labelnode(P, '10000', string(PG(4,k)));
        labelnode(P, '10000', string(gen_batt));
        % 
        labelnode(P, '1445', "");
        labelnode(P, '2135', "");
        %
        labelnode(P, '2504', "");
        labelnode(P, '4231', "");
        labelnode(P, '5313', "");
        labelnode(P, '5411', "");
        labelnode(P, '2694', "");
        labelnode(P, '1446', "");
        
        % Bus
        P.NodeColor = 'k'; % k = black
        P.NodeFontSize = 16;
        P.MarkerSize = 12; % node size
        highlight(P, busString, 'NodeColor', 'r')
        % Edge
        P.EdgeColor = 'k';
        P.LineWidth = 3;
        P.EdgeLabelColor = 'k';
        P.ArrowSize = 10;
        P.EdgeFontSize = 16;

        if abs(PF(1,k)) > threshold
            highlight(P, 'Edges', 1, 'EdgeColor', 'red');
        end
        if abs(PF(3,k)) > threshold
            highlight(P, 'Edges', 2, 'EdgeColor', 'red');
        end
        if abs(PF(6,k)) > threshold
            highlight(P, 'Edges', 3, 'EdgeColor', 'red');
        end
        if abs(PF(2,k)) > threshold
            highlight(P, 'Edges', 6, 'EdgeColor', 'red');
        end
        if abs(PF(5,k)) > threshold
            highlight(P, 'Edges', 7, 'EdgeColor', 'red');
        end
        if abs(PF(4,k)) > threshold
            highlight(P, 'Edges', 9, 'EdgeColor', 'red');
        end
        if abs(PF(7,k)) > threshold
            highlight(P, 'Edges', 10, 'EdgeColor', 'red');
        end


        pause(0.001);
    end

end


isSubplot = false;
if isSubplot
    figure('Units', 'normalized', 'Position', [0 0 1 1])
    subplot(1,3,1)
    zone1.plotTopology();
    %zoneDynGraph = ;
end