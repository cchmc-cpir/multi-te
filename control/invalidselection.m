function quitStatus = invalidselection(var, typeString)
    %CHECKSELECTION Checks a variable for a specified type.
    %   If the variable is not of the specified type, the user is prompted to choose whether to
    %   continue execution or to quit. Return parameter QUITSTATUS is a bool.
    
    if ~isa(var, typeString)
        QUIT = questdlg('No file selected. Quit or continue?', 'No files selected', ...
            'Continue', 'Quit', 'Continue');
        switch QUIT
            case 'Quit'
                quitStatus = true;
            case 'Continue'
                quitStatus = false;
        end
    else
        quitStatus = false;
    end
end

