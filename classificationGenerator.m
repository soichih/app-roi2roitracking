function [] = classificationGenerator()

if ~isdeployed
    disp('loading path')

    %for IU HPC
    addpath(genpath('/N/u/brlife/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/encode'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/spm'))
    addpath(genpath('/N/u/brlife/git/wma'))

    %for old VM
    addpath(genpath('/usr/local/vistasoft'))
    addpath(genpath('/usr/local/encode'))
    addpath(genpath('/usr/local/jsonlab'))
    addpath(genpath('/usr/local/spm'))
    addpath(genpath('/usr/local/wma'))
end

% Set top directory
topdir = pwd;

% Load configuration file
config = loadjson('config.json');

% Set tck file path/s
rois=dir('*.tck*');

roiPair = str2num(config.roiPair);
for ii = 1:length(rois); 
    fgPath{ii} = fullfile(topdir,rois(ii).name);
end

% Create classification structure
[mergedFG, classification]=bsc_mergeFGandClass(fgPath);

% Amend name of tract in classification structure
for ii = round((1:length(roiPair))/2)
    classification.names{ii} = strcat('ROI',num2str(roiPair((2*ii) - 1)),'_ROI',num2str(roiPair((2*ii))));
end

% Create fg_classified structure
wbFG = mergedFG;
fg_classified = bsc_makeFGsFromClassification(classification,wbFG);

% Save output
save('output.mat','classification','fg_classified','-v7.3');

% Create structure to generate colors for each tract
tracts = fg2Array(fg_classified);

mkdir('tracts');

% Make colors for the tracts
%cm = parula(length(tracts));
cm = distinguishable_colors(length(tracts));
for it = 1:length(tracts)
   tract.name   = strrep(tracts(it).name, '_', ' ');
   all_tracts(it).name = strrep(tracts(it).name, '_', ' ');
   all_tracts(it).color = cm(it,:);
   tract.color  = cm(it,:);

   %tract.coords = tracts(it).fibers;
   %pick randomly up to 1000 fibers (pick all if there are less than 1000)
   fiber_count = min(1000, numel(tracts(it).fibers));
   tract.coords = tracts(it).fibers(randperm(fiber_count)); 
   
   savejson('', tract, fullfile('tracts',sprintf('%i.json',it)));
   all_tracts(it).filename = sprintf('%i.json',it);
   clear tract
end

% Save json outputs
savejson('', all_tracts, fullfile('tracts/tracts.json'));

% Create and write output_fibercounts.txt file
for i = 1 : length(fg_classified)
    name = fg_classified(i).name;
    num_fibers = length(fg_classified(i).fibers);
    
    fibercounts(i) = num_fibers;
    tract_info{i,1} = name;
    tract_info{i,2} = num_fibers;
end

T = cell2table(tract_info);
T.Properties.VariableNames = {'Tracts', 'FiberCount'};

writetable(T, 'output_fibercounts.txt');


exit;
end



