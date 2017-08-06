function vo_downloadData()
% Download and unzip the data from the Open Science Framework project page
% associated with this paper:
%
%   Winawer and Witthoft (2017). Identification of the ventral occipital
%   visual field maps in the human brain. F1000Res.2017
%
% Alternatively, the data can be downloaded manually from this site:
% https://osf.io/uyhmx/
% Or from this DOI 10.17605/OSF.IO/UYHMX
%
% The code downloads a single zip file (673 MB), places it in the root
% directory of the project, and unzips it into the folder named 'Data'

url = 'https://osf.io/ty24m/?action=download';
pth = fullfile(vo_RootPath, 'VO_Data.zip');
fname = websave(pth, url);
unzip(fname);

end