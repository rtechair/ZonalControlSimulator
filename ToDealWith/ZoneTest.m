%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

classdef ZoneTest < matlab.unittest.TestCase
    methods (Test)
        function errorBusNotInBasecase(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [ 2 4 6]'; % bus_id = 6 does not exist in reality
            testCase.verifyError(@()Zone(bus_id_wrong, basecase),'mustBusBeFromBasecase:busNotFromBasecase')
        end
        
        function noErrorBusInBasecase(testCase)
            basecase = loadcase('case5');
            bus_id = [ 2 4 5]'; % all buses exist
            testCase.verifyWarningFree(@()Zone(bus_id, basecase))
        end
    end
    
end
            

    
%{
% basecase
basecase_VG_VTV = loadcase('case6468rte_zone1and2');
basecase_VG_VTV_int = ext2int(basecase_VG_VTV);

% bus map
[mapBus_id2idx, mapBus_idx2id] = getMapBus_id2idx_idx2id(basecase_VG_VTV);
mapBus_id_e2i = basecase_VG_VTV_int.order.bus.e2i; % sparse matrix
mapBus_id_i2e = basecase_VG_VTV_int.order.bus.i2e; % continuous indexing matrix

% online gen map, this include batteries
[mapGenOn_idx_e2i, mapGenOn_idx_i2e] = getMapGenOn_idx_e2i_i2e(basecase_VG_VTV_int);

% zone VG
VG_bus_id = [1445 2076 2135 2745 4720 10000]';


% zone VTV
VTV_bus_id= [2506 4169 4546 4710 4875 4915]';

VG_zone = Zone(VG_bus_id, basecase_VG_VTV_int);
VG_zone = SetInteriorProperties(VG_zone, mapBus_id_e2i, mapGenOn_idx_e2i);

VTV_zone = Zone(VTV_bus_id, basecase_VG_VTV_int);
VTV_zone = SetInteriorProperties(VTV_zone, mapBus_id_e2i, mapGenOn_idx_e2i);

%% Test 1: zone VG - Inner

Bus_int_id_ref = [1445;2076;2135;2743;4717;6469];
Branch_idx_ref = [2854;2856;2859;3881;3882;9000;9001];
assert( isEqual( VG_zone.Bus_int_id, Bus_int_id_ref), 'incorrect VG_zone.Bus_int_id')
assert( isEqual( VG_zone.Branch_idx, Branch_idx_ref), 'incorrect VG_zone.Branch_idx')

%% Test 2: zone VG - Border
Bus_border_id_ref = [1446;2504;2694;4231;5313;5411];
Bus_border_int_id_ref = [1446;2503;2692;4229;5310;5408];
Branch_border_idx_ref = [2853;2855;2857;2858;2860;3974;4764;7703;7704];
assert( isEqual( VG_zone.Bus_border_id, Bus_border_id_ref), 'incorrect VG_zone.Bus_border_id')
assert( isEqual( VG_zone.Bus_border_int_id, Bus_border_int_id_ref), 'incorrect VG_zone.Bus_border_int_id')
assert( isEqual( VG_zone.Branch_border_idx, Branch_border_idx_ref), 'incorrect VG_zone.Branch_border_idx')

%% Test 3: zone VG - Generator
Gen_idx_ref = [1297;1299;1300;1301];
Gen_int_idx_ref = [1297;1299;1300;1301];

%% Test 4: zone VG - Battery
Batt_idx_ref = 1298;
Batt_int_idx_ref = 402; 


%% Test 5: zone VTV - Inner

Bus_int_id_ref = [2505;4167;4543;4707;4872;4912];
Branch_idx_ref = [4494;6281;6548;6646;6714];

%% Test 6: zone VTV - Border
Bus_border_id_ref = [347;1614;2093;4170;4236;4548];
Bus_border_int_id_ref = [347;1614;2093;4168;4234;4545];
Branch_border_idx_ref = [767;3194;3904;6280;8479;8480;8567];

%% Test 7: zone VTV - Generator
Gen_idx_ref = [1302;1303;1304]; % notice gen_idx = 466 is in the zone but not ON so not considered
Gen_int_idx_ref = [406;407;408];

%% Test 8: zone VTV - Battery
Batt_idx_ref = 1305;
Batt_int_idx_ref = 409;

%}