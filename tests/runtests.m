% Runs tests for the Multi-TE package.
%
% Written by Alex Cochran, 2018.


import matlab.unittest.TestSuite;

suiteFolder = TestSuite.fromFolder(pwd);
result = run(suiteFolder);
disp(result);
