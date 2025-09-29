function [ptdf_G, ptdf_B] = leastSquaresMethod(funcHandle, window, deltaPF, deltaPG, deltaPB)
    nGen = height(deltaPG);
    nBatt = height(deltaPB);
    nLine = height(deltaPF);
    nStep = width(deltaPF);

    ptdf_B = NaN(nLine, nBatt, nStep);
    ptdf_G = NaN(nLine, nGen, nStep);
    for t = 1: nStep
         t_ini = max(1, t-window);
        deltaPF_used = deltaPF(:, t_ini:t);
        deltaPG_used = deltaPG(:, t_ini:t);
        deltaPB_used = deltaPB(:, t_ini:t);
        [ptdf_G_step , ptdf_B_step] = funcHandle(deltaPF_used, deltaPG_used, deltaPB_used);
        ptdf_G(:,:, t) = ptdf_G_step;
        ptdf_B(:,:,t) = ptdf_B_step;
    end
end

% https://stackoverflow.com/questions/2730029/passing-functions-as-arguments-in-matlab?rq=3