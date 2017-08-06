function rootPath=vo_RootPath()
%
%        rootPath =vo_RootPath;
%
% Determine path to root of the vo directory
%
% This function MUST reside in the directory at the base of the ebs directory structure
%

rootPath=which('vo_RootPath');

rootPath=fileparts(rootPath);

return
