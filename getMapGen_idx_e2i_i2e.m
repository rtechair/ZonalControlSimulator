function [mapGen_idx_e2i, mapGen_idx_i2e] = getMapGen_idx_e2i_i2e(basecase_int)
    genOn_idx_ext = basecase_int.order.gen.status.on;
    genOn_idx_int = 1:size(genOn_int2ext);
    
    mapGen_idx_e2i = containers.Map(genOn_idx_ext, genOn_idx_int);
    mapGen_idx_i2e = containers.Map(genOn_idx_int, genOn_idx_ext);
end