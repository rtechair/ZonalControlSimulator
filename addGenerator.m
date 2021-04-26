function [mpc] = addGenerator(mpc, bus_id, Pg_max, Pg_min, num, startup, shutdown, c3, c2, c1, c0)
% addGenerator adds a generator to an existing MATPOWER file 'mpc' at the bottom
% of the list
%% Input
% All the needed values describing a branch according to MATPOWER manual:
% or a subset not including the data for gencost
% see section Generator Data Format and Generator Cost Data of CASEFORMAT, type "help caseformat"
% or Matpower manual: Table B-2 Generator Data and Table B-4 Generator Cost data.
%% Output
% The updated MATPOWER file 'mpc'
    arguments
        mpc struct
        bus_id (1,1) double {mustBeInteger, mustBePositive}
        Pg_max (1,1) double {mustBeNonNegative}
        Pg_min (1,1) double
        num (1,1) double = 2
        startup (1,1) double = 0
        shutdown (1,1) double = 0
        c3 (1,1) double = 0
        c2 (1,1) double = 0
        c1 (1,1) double = 0
        c0 (1,1) double = 0
    end
    
    %CAUTIOUS! nr = number of rows in mpc.gen. gencost can either have nr rows or
    %2*nr, see Generator Cost Data Format
    %TODO: handling both cases
    
    mpc.gencost(end+1,:) = [num startup shutdown c3 c2 c1 c0];
    mpc.gen(end+1,:) = [bus_id 0 0 300 -300 1.025 100 1 Pg_max Pg_min zeros(1,11)];
end

