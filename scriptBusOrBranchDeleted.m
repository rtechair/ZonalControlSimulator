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
