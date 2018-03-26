function multitehelp( varargin )
    %MULTITEHELP Displays help text for the Multi-TE package.
    %   Help text for the entire Multi-TE package or specific portions of its functionality are
    %   available by executing this function. The user may provide an optional argument (or
    %   multiple) corresponding to the particular part of the program that they wish to receive
    %   help text for.
    %
    %   Usage:
    %       MULTITEHELP (no argument) displays all available help text on the command line
    %       MULTITEHELP(ARG1, ARG2, ...) displays help text for each portion of functionality
    %           specified by the input arguments.
    %           
    %       Available optional arguments:
    %           'gating'
    %           'reconstruction'
    %           'mapping'
    %           
    %   Incorrect arguments will throw an error. Please feel free to make suggestions on the
    %   CCHMC-CPIR GitHub page (https://github.com/cchmc-cpir/multi-te for improvements to the help
    %   text.
    
    if nargin == 0
        type('gating.txt');
        type('reconstruction.txt');
        type('mapping.txt');
    else
        for idx = 1:length(varargin)
            try
                type(strcat(char(varargin(idx)), '.txt'));
            catch
                error('Invalid arguments. Help text is only available for valid arguments.');
            end
        end
    end
end

