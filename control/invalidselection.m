function quitStatus = invalidselection(var, typeString)
    %CHECKSELECTION Checks a variable for a specified type
    %   Detailed explanation goes here
    
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

