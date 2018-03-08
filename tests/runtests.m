% Runs tests for the Multi-TE package.
%
% Written by Alex Cochran, 2018.


import matlab.unittest.TestSuite;

suiteClass = TestSuite.fromFolder(pwd);
result = run(suiteClass);
disp(result);
