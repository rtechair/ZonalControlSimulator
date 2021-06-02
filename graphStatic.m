function G = graphStatic(basecase,branchIdx)
% plot the static graph of a zone defined by its branch indices in the
% basecase. The buses are branch's node ends.
    arguments
        basecase struct
        branchIdx (:,1) {mustBeInteger}
    end

    fbus= basecase.branch(branchIdx,1); 
    tbus = basecase.branch(branchIdx,2);

    %{
    Matlab's Graph object cares about the value / id of nodes, it will print as many nodes as
     the max id of nodes; e.g. if a node's number is 1000,
    then Matlab assumes this is the 1000th node and will plot 1000 nodes, even
    if it is the only node of the graph. Therefore, node's numbers are
    converted into strings to avoid this strange behavior.
    %}
    G = graph(string(fbus), string(tbus)); 
end