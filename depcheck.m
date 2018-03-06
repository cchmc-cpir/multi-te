function depList = depcheck(scriptName)
    % DEPCHECK  Display the dependencies of the current script.
    %   Augmentation of matlab.codetools.requiredFilesAndProducts('scriptName').
    %
    %   depList = DEPCHECK(scriptName) outputs the MATLAB files used by the script specified.
    
    if nargin > 1
        error('Too many inputs.');
    end
    
    [fList, ~] = matlab.codetools.requiredFilesAndProducts(scriptName);
    depList = cell(length(fList));
    for idx = 1:length(fList)
        C = strsplit(char(fList(idx)), '\');
        depList(idx) = C(length(C));
    end
end