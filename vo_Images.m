function vo_Images(subjnum)
% vo_Images
%
% Make mesh images of S1, S2, S3 anatomy, field maps, and ROIs for F1000
% paper on ventral maps
%
% Make it a function rather than script so that we can call internal
% subroutines.
%
% To run: 
%   vo_Images(1); % make images for subject 1
%   vo_Images(2); % make images for subject 2
%   vo_Images(3); % make images for subject 3

% Check inputs
if nargin==0, subjnum = 1; end

% Where is the session?
homedir = fullfile(vo_RootPath, 'Data', sprintf('s%d', subjnum));

% Mesh files
msh.pth{1} = '3DAnatomy/Left/3DMeshes/lh_smoothed.mat';
msh.pth{2} = '3DAnatomy/Right/3DMeshes/rh_smoothed.mat';

% Descriptions of above files (for naming image files we will save)
msh.descriptions = {'leftSmoothed' 'rightSmoothed'};

% Which hemisphere goes with which mesh - important for polar angle images
msh.hemis = 'LR';

% Which data type has the pRF model?
dtname  = 'Averages';

% ROI name (to mask data outside area of interest)
roi = 'occ_lobe_ROI';

% Name of pRF model? (assumed to be in Gray/dtname/)
prffile = 'prfModel.mat';

% Threshold for variance explained ([0 1])
varExpThresh = 0.10;

% Stored mesh views 
msh.views = {'VO_Zoom' 'VO_WholeBrain'}; 

% We will save images for all meshes, all views, and all fields
imageTypes = {'anat' 'meanmap' 'ecc_masked' 'angle_masked' 'varexp_masked'};
        
% Where should we store all the pics?
savepth = fullfile(vo_RootPath, 'Images', sprintf('s%d', subjnum));
if ~exist(savepth,'file'), mkdir(savepth); end

%% Go

% clean up and go
mrvCleanWorkspace;
vw = voNavigate(homedir, dtname, prffile, roi);

% Loop over the different meshes
for m = 1:numel(msh.pth)
    
    vw = voOpenMesh(vw, msh, m);
    thismsh = viewGet(vw, 'current mesh');
    
    % Loop over the type of image we want to save
    for imType = 1:length(imageTypes)
        vw = voSetImageType(vw, imageTypes{imType}, msh.hemis(m), varExpThresh);
        
        % Loop over the different views
        for vwnum = 1:numel(msh.views)
            meshRetrieveSettings(thismsh, msh.views{vwnum});
            
            % save the picture!
            voSnapPicture(vw, savepth,subjnum, msh.views{vwnum}, ...
                msh.descriptions{m}, imageTypes{imType});
        end
    end
    
end


end

% ***********************************************
function vw = voNavigate(homedir, dtname, prffile, roi)

cd(homedir)

% open a gray view session
vw = mrVista('3'); %initHiddenGray;

% specify dataTYPE containing prf model solution and scan = 1
vw = viewSet(vw, 'current data type', dtname);
vw = viewSet(vw, 'current scan', 1);

% load the mask ROI
vw = loadROI(vw, roi, [], [], 0, 1);

% check that it loaded correctly
if numel(vw.ROIs) ~= 1, error('failed to load ROI'); end

% open prf file (but do not load variables until we are ready)
vw = rmSelect(vw, 2, prffile);

% set mesh preferences so images all look similar
setpref('mesh',  'overlayModulationDepth',  0)
setpref('mesh',  'dataSmoothIterations',    1)
setpref('mesh',  'roiDilateIterations',     1)
setpref('mesh',  'clusterThreshold',        0)
setpref('mesh',  'coTransparency',          0)
setpref('mesh',  'layerMapMode',            1)
setpref('mesh',  'overlayLayerMapMode', 	'mean')

end

function vw = voOpenMesh(vw, msh, m)

% close any existing meshes to keep life simple
if isfield(vw, 'mesh'), vw = meshDelete(vw, inf); end

% this is the screen size, and will be the size of the mesh window (to make
% nice, big images)
windowsize = get(0, 'screensize');

% load it
vw = meshLoad(vw, msh.pth{m}, 1);

% % recomputed vertex=>gray map
thismsh = viewGet(vw, 'Mesh');
% vertexGrayMap = mrmMapVerticesToGray(...
%     meshGet(thismsh, 'initialvertices'), ...
%     viewGet(vw, 'nodes'), ...
%     viewGet(vw, 'mmPerVox'), ...
%     viewGet(vw, 'edges') );
% thismsh = meshSet(thismsh, 'vertexgraymap', vertexGrayMap);

% make the mesh as large as the screen
thismsh = mrmSet(thismsh, 'window size', windowsize(4), windowsize(3));

% add the fixed mesh back to the view structure
vw = viewSet(vw, 'Mesh', thismsh);

end

% ***********************************************
function vw = voSetImageType(vw, imtype, hemi, varExpThresh)

vw = viewSet(vw, 'show ROIs',false); % don't show ROIs on mesh unless requested
vw = viewSet(vw, 'mask ROIs',false); % don't mask data outside ROIs unless requested

switch lower(imtype)
    case 'anat'
        vw = viewSet(vw, 'display mode' ,'anat');
        
    case 'meanmap'
        vw = voRestrict(vw); % no ph, co restriction
        vw = loadMeanMap(vw, true);  % true means normalized to [0 1]
        vw = viewSet(vw, 'display mode','map');
        vw = viewSet(vw, 'color map mode', 'hotCmap');
    case 'ecc'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw); % no ph, co restriction
        vw = viewSet(vw, 'display mode','map');
        
    case 'ecc_threshed'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, varExpThresh); % restirct ve but not angle
        vw = viewSet(vw, 'display mode','map');
        
    case 'ecc_masked'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, varExpThresh); % restirct ve but not angle
        vw = viewSet(vw, 'display mode','map');
        vw = viewSet(vw, 'show ROIs',-2); % show mask ROI
        vw = viewSet(vw, 'mask ROIs',true); % mask data outside the ROI
        
    case 'angle'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, []); % restrict angle for this hemisphere
        if strcmpi(hemi, 'l')
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapLeft_pRF.mat');
        else
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapRight_pRF.mat');
        end
        vw = viewSet(vw, 'display mode','ph');
        
    case 'angle_threshed'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, varExpThresh); % restrict ve and angle for this hemisphere
        if strcmpi(hemi, 'l')
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapLeft_pRF.mat');
        else
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapRight_pRF.mat');
        end
        vw = viewSet(vw, 'display mode','ph');
        
    case 'angle_masked'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, varExpThresh); % restrict ve and angle
        if strcmpi(hemi, 'l')
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapLeft_pRF.mat');
        else
            vw = cmapImportModeInformation(vw, 'phMode', 'WedgeMapRight_pRF.mat');
        end
        vw = viewSet(vw, 'display mode','ph');
        vw = viewSet(vw, 'show ROIs',-2); % show mask ROI
        vw = viewSet(vw, 'mask ROIs',true); % mask data outside the ROI
        
    case 'varexp'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw); % no ph, co restriction
        vw = viewSet(vw, 'display mode','co');
        
    case 'varexp_threshed'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, varExpThresh); % restrict by varExp
        vw = viewSet(vw, 'display mode','co');
        
    case 'varexp_masked'
        vw = rmLoadDefault(vw); % load prf angle, ecc, ve => ph, map, co
        vw = voRestrict(vw, 0); % varExpThresh); % restrict by varExp
        vw = viewSet(vw, 'display mode','co');
        vw = viewSet(vw, 'show ROIs',-2); % show mask ROI
        vw = viewSet(vw, 'mask ROIs',true); % mask data outside the ROI
        
    otherwise, error('Unknown map type %s', imType)
end
end

% ***********************************************
function vw = voRestrict(vw, varExpThresh)

if notDefined('varExpThresh'), varExpThresh = 0; end

% set coherence threshold and phase window
vw = viewSet(vw, 'co thresh', varExpThresh);

end

% ***********************************************
function voSnapPicture(vw, savepth, subj, meshView, meshtype, mapType)

% update the mesh
vw = meshColorOverlay(vw);

fname = sprintf('s%d_%s_%s_%s.png', ...
    subj, meshView, meshtype, mapType);


img = mrmGet( viewGet(vw, 'Mesh'), 'screenshot' )/255;

imwrite(img, fullfile(savepth, fname));

fprintf('Saving image to %s\n', fullfile(savepth, fname)); drawnow;
end