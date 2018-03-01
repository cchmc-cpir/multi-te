function [ output_args ] = readbrukerconfigs(acpqPath, methPath)
    %READBRUKERCONFIGS Read information from Bruker ACQP and method.
    %   Detailed explanation goes here
    
    fileID = fopen(acqpPath);
    acqpData = textscan(fileID, '%c', 'delimiter', '\n');
    acqpData = acqpData{1};
    
    for idx = 1:size(acqpRead, 1)
        testStr = char(acqp
    
end

