function mustBeInternalBasecase(basecase_int)
% Check the provided basecase is an internal basecase obtained using the
% ext2int function from matpower

    % an internal basecase has an 'order' field, while standard ones do not
    if ~isfield(basecase_int, 'order')
        eidType = 'mustBeInternalBasecase:NotInternalBasecase';
        msgType = ['the basecase provided is not an internal basecase.'...
            'Using a standard basecase, obtain the internal basecase with the ext2int function from matpower'];
        throwAsCaller(MException(eidType, msgType))
    end
end