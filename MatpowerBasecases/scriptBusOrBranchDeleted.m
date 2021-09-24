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

filename = 'caseInstanceName.dat';
fileID = fopen(filename);
C = textscan(fileID, '%s');
fclose(fileID);
for r = 1:size(C{1},1)
	namecase = C{1}{r};
	basecase = loadcase(namecase);
	basecase_int = ext2int(basecase);
[isBusDeleted, isBranchDeleted] = isBusOrBranchDeleted(basecase_int);
disp(['Case: ', namecase ', Bus: ',num2str(isBusDeleted), ' branch: ', num2str(isBranchDeleted)])
end
disp('end')
