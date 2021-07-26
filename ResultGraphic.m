classdef ResultGraphic < Result
    
    methods
       
        function obj = ResultGraphic(durationSimulation, samplingTime, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, busId, branchIdx, genOnIdx, delayCurt, delayBatt)
            
           obj@Result(durationSimulation, samplingTime, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, busId, branchIdx, genOnIdx, delayCurt, delayBatt); 
        end
        
        function figStateGenOn = plotStateGen(obj, electricalGrid)
            % plot for each generator On: PA, PC, maxPG - PC, min(PA, maxPG - PC)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            %layout of the plot
            numberOfRowsOfGraph = ceil(sqrt(obj.NumberOfBuses));
            %% Create the figure
            % see:  https://www.mathworks.com/help/matlab/ref/matlab.ui.figure-properties.html
            figStateGenOn = figure('Name','for each generator On : PA, PC, MaxPG - PC, min(PA, MaxPG - PC)',...
            'NumberTitle', 'off', 'WindowState', 'maximize'); 
            %% plot for each generator On: PA, PC, MaxPG - PC, min(PA, MaxPG - PC)
            for gen = 1:obj.NumberOfGen
                % decompose the plot into a square of subplots
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.PowerAvailable(gen,:), ':'); % PA
                stairs(time, obj.PowerCurtailment(gen, :), '-.'); % PC
                f1 = obj.MaxPowerGeneration(gen) - obj.PowerCurtailment(gen,:);
                stairs(time, f1, '--'); % MaxPG - PC
                stairs(time, min(obj.PowerAvailable(gen, :), f1)); % min(PA, MaxPG - PC)
                
                legend({'PA', 'PC', 'MaxPG - PC', 'min(PA, MaxPG-PC)'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.GenOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ', at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figDeltaGenOn = plotControlAndDisturbanceGen(obj, electricalGrid)
            time = 1: obj.NumberOfIterations;
            xlegend = 'Number of iterations';
            
            numberOfRowsOfGraph = ceil(sqrt(obj.NumberOfBuses));
            figDeltaGenOn = figure('Name',['for each generator On : DeltaPA,' ...
                 'DeltaPG, DeltaPC, DeltaPC(step - delay_curt + 1)'],...
            'NumberTitle', 'off', 'WindowState', 'maximize');
            for gen = 1:obj.NumberOfGen
                subplot(numberOfRowsOfGraph, numberOfRowsOfGraph, gen);
                hold on;
                stairs(time, obj.DisturbanceAvailable(gen, :), ':'); % DeltaPA
                stairs(time, obj.DisturbanceGeneration(gen, :)); % DeltaPG
                stairs(time, obj.ControlCurtailment(gen, :), '--'); % DeltaPC: control taken
                f1 = [zeros(1, obj.DelayCurt +1) ...
                    obj.ControlCurtailment(gen, 1: obj.NumberOfIterations-obj.DelayCurt-1)];
                stairs(time, f1, '-.'); % DeltaPC: control applied
                        
                legend({'DeltaPA', 'DeltaPG', 'DeltaPC: control taken', ...
                    'DeltaPC(step+delay\_curt+1): control applied'}, 'Location', 'Best');
                xlabel(xlegend)
                ylabel('Power [MW]')
                genIdx = obj.GenOnIdx(gen);
                busIdOfGen = electricalGrid.getBuses(genIdx);
                name = ['Gen ', int2str(genIdx), ' at ', int2str(busIdOfGen)];
                title(name);
            end
        end
        
        function figFlowBranch = plotFlowBranch(obj, electricalGrid)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.NumberOfBranches));
            figFlowBranch = figure('Name', 'power flow on each branch of the zone, over the period',...
            'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.NumberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, obj.PowerBranchFlow(br,:)); % Fij
                legend({'Branch Power Flow'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.BranchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figAbsFlowBranch = plotAbsoluteFlowBranch(obj, electricalGrid)
            time = 1: obj.NumberOfIterations+1;
            xlegend = 'Number of iterations';
            numberOfRowsOfPlot = ceil(sqrt(obj.NumberOfBranches));
            figAbsFlowBranch = figure('Name', 'absolute power flow on each branch of the zone, over the period',...
            'NumberTitle', 'off', 'WindowState', 'maximize');
            for br = 1:obj.NumberOfBranches
                subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, br);
                hold on;
                stairs(time, abs(obj.PowerBranchFlow(br,:)));  % abs(Fij)
                legend({'Absolute Branch Power Flow'},'Location','Best')
                xlabel(xlegend)
                ylabel('Power [MW]')
                branchIdx = obj.BranchIdx(br);
                [fromBus, toBus] = electricalGrid.getEndBuses(branchIdx);
                name = ['Branch ', int2str(branchIdx), ...
                    ' from ', int2str(fromBus), ' to ', int2str(toBus)]; 
                title(name);
            end
        end
        
        function figDisturbTransit = plotDisturbanceTransit(obj)
           time = 1:obj.NumberOfIterations;
           xlegend = 'Number of iterations';
           numberOfRowsOfPlot = ceil(sqrt( obj.NumberOfBuses));
           figDisturbTransit = figure('Name', 'Disturbance of power flow on each bus of the zone, over the period',...
            'NumberTitle', 'off', 'WindowState', 'maximize');
           for bus = 1:obj.NumberOfBuses
               subplot(numberOfRowsOfPlot, numberOfRowsOfPlot, bus);
               hold on;
               stairs(time, obj.DisturbanceTransit(bus,:)); % DeltaPT
               legend({'Disturbance transit'}, 'Location','Best')
               xlabel(xlegend)
               ylabel('Power [MW]')
               busId = obj.BusId(bus);
               name = ['Bus ' int2str(busId)];
               title(name);        
           end
        end
        
        function plotAllFigures(obj, electricalGrid)
            obj.plotStateGen(electricalGrid);
            obj.plotControlAndDisturbanceGen();
            obj.plotAbsoluteFlowBranch();
            obj.plotDisturbanceTransit();
        end
        
    end
    
end