vertex = [1,2,3,4,5];
fromBus = [1,2,3,3];
toBus = [3,3,4,5];

weightBr = [];
weightNode = [];
bound = 5;
for k = bound:-1:-bound
    weightBr = [weightBr;
                       k , k , k , k];
    weightNode = [weightNode;
                            2*k, 2*k+1, 2*k+2, 2*k+3, 2*k+3];
end

g2 = digraph(fromBus, toBus, weightBr(1,:));
p = plot(g2, 'EdgeLabel', g2.Edges.Weight, 'ArrowPosition', 0.4);
%hold on

testBoolean = true;
if testBoolean
for k = 2:2:2*bound
    g2.Edges.Weight = weightBr(k,:)';
    weightN = weightNode(k,:);
    %g2.Nodes.Name = string(weightN);
    pause(0.5);
    %p = plot(g2, 'EdgeLabel', g2.Edges.Weight, 'ArrowPosition', 0.7);
    p = plot(g2, 'EdgeLabel', g2.Edges.Weight, 'ArrowPosition', 0.7);
    pause(0.5);
    g2.Edges.Weight = weightBr(k+1,:)';
    p = plot(g2, 'EdgeLabel', g2.Edges.Weight, 'ArrowPosition', 0.4);
end

end