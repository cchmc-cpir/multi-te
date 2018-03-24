classdef YamlFileTest < matlab.unittest.TestCase
    %YAMLFILETEST Tests setup conditions for Multi-TE processing code.
    %   Checks that the information contained in the input.yml (YAML) file is complete and correctly
    %   typed/formatted.
    %
    %   Written by Alex Cochran, 2018.
    
    
    methods (Test)
        function testYamlLoad(testCase)
            addpath('../tools/yaml-matlab');
            
            % exist(name) returns 2 if the file specified by 'name' exists.
            configFileExists = exist('../input.yml', 'file');
            
            % verify file exists at the correct place on the tree
            testCase.verifyEqual(configFileExists, 2)
        end
            
        
        function testYamlInputs(testCase)
            addpath('../tools/yaml-matlab');
            configStruct = ReadYaml('../input.yml');
            
            % mode
            testCase.verifyEqual(class(configStruct.mode.gate), 'logical');
            testCase.verifyEqual(class(configStruct.mode.reconstruct), 'logical');
            testCase.verifyEqual(class(configStruct.mode.map), 'logical');
            testCase.verifyEqual(class(configStruct.mode.log), 'logical');
            
            % settings
            testCase.verifyEqual(class(configStruct.settings.recon_mode), 'char');
            testCase.verifyEqual(class(configStruct.settings.zero_filling), 'char');
            testCase.verifyEqual(class(configStruct.settings.num_projections), 'double');
            testCase.verifyEqual(class(configStruct.settings.num_cut_projections), 'double');
            testCase.verifyEqual(class(configStruct.settings.num_points), 'double');
            testCase.verifyEqual(class(configStruct.settings.num_points_shift), 'double');
            testCase.verifyEqual(class(configStruct.settings.ram_points), 'double');
            testCase.verifyEqual(class(configStruct.settings.fid_points), 'double');
            testCase.verifyEqual(class(configStruct.settings.num_sep), 'double');
            testCase.verifyEqual(class(configStruct.settings.exp_threshold), 'double');
            testCase.verifyEqual(class(configStruct.settings.insp_threshold), 'double');
            testCase.verifyEqual(class(configStruct.settings.echo_times), 'cell');
            testCase.verifyEqual(class(configStruct.settings.interleaves), 'double');
            testCase.verifyEqual(class(configStruct.settings.phi), 'cell');
            testCase.verifyEqual(class(configStruct.settings.resp_mode), 'char');
            testCase.verifyEqual(class(configStruct.settings.alpha), 'double');
            testCase.verifyEqual(class(configStruct.settings.beta), 'double');
        end
    end
end

