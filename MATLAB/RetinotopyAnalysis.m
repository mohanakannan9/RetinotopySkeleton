function RetinotopyAnalysis(inputfile)

% function RetinotopyAnalysis(inputfile)
%
% <inputfile> is the location of a .txt file that can be evaluated in order
% to define the following variables:
%   <userid> is a string
%   <subject> is a positive integer
%   <outpath> is a string 
%   <dummy_file> is a string 
%   <movie_files> is a cell vector of .mat files.  there should be 5 of them.
%   <image_files> is a cell vector of minimally pre-processed CIFTI files
%   <behavior_files> is a cell vector of behavioral XML files
%   <debugmode> (optional) is
%     0 means regular full processing (involving CHPC machinery)
%     1 means super-fast processing (does not involve CHPC machinery at all)
%     2 means fast processing involving CHPC machinery, but analyzing only a few voxels
%     Default: 0.
%
% Analyze the data and write outputs to:
%   outpath/results/<subject>_XXX.dtseries.nii
% where XXX is the name of a quantity (e.g. angle).
%
% Regarding the image and behavior files, it is assumed that the number of both
% types of files is the same, that there is a one-to-one correspondence between
% the files, and that missing files are indicated by the string 'EMPTY'.
%
% If the image files have fewer than the expected number of time points, we assume
% that these missing time points occur at the end of the run.  To handle these cases,
% we just truncate the corresponding stimulus sequence before performing the actual
% analysis.
%
% history:
% - 2015/03/11 - handle the case of data truncation; flexible format for loading the
%                stimulus files; rename 'ret_summary' to 'behav_summary'.

% wrap everything in a try-catch to ensure that MATLAB will exit
try

  %%%%% GET INPUTS

  % evaluate the text file
  inputload = loadtext(inputfile);
  for p=1:length(inputload)
    eval(inputload{p});
  end
  
  % deal with inputs
  if ~exist('debugmode','var') || isempty(debugmode)
    debugmode = 0;
  end

  %%%%% SETUP
  
  % internal constants
  viewingdistance = 39;  % inches
  widthofstim = 15;      % inches
  wbcmd = 'wb_command';  % workbench command
  tr = 1;                % seconds
  stimres = 200;         % number of pixels along each dimension of the stimulus
  maxiter = 100;         % maximum number of iterations
  dummycifti = dummy_file;   % dummy CIFTI file

  % calc
  stimdeg = atan(widthofstim/2/viewingdistance)/pi*180*2;  % stimulus diameter in degrees 
  pxtodeg = stimdeg/stimres;  % this converts pixels to degrees
  
  % debug speed ups
  switch debugmode
  case 0
    vxs = [];
    seedmode = [];
    numperjob = 50;
  case 1
    vxs = [];
    seedmode = [-2];   % super fast seed mode
    numperjob = [];
  case 2
    vxs = [25138 24995 24818 23601 23862 24994 23160 24987];  % eight voxels only
    seedmode = [0];   % only one seed
    numperjob = 2;    % two voxels in each job
  end

  % prepare writecifti function
  gifti0 = ciftiopen(dummycifti,wbcmd);
    % data is a column vector; loc is a location to write to
  writecifti = @(data,loc) ciftisave(setfield(gifti0,'cdata',data),loc,wbcmd);

  %%%%% LOAD STIMULI

  % load stimuli
  stimulus = {};  % each element is 200 x 200 x 300, single format
  for p=1:length(movie_files)
    [~,~,ext] = fileparts(movie_files{p});
    switch lower(ext)
    case '.mat'
      a1 = load(movie_files{p});
      stimulus{p} = a1.stim;
      clear a1;
    case '.hdf5'
      stimulus{p} = h5read(movie_files{p},'/stim');
    case '.mov'
      mobj = VideoReader(movie_files{p});
      stim0 = read(mobj);
      stimulus{p} = permute(single(stim0(:,:,1,:)),[1 2 4 3]);
      clear mobj stim0;
    otherwise
      error('Unknown movie file type: %s\n',movie_files{p});
    end
  end

  % sanity check
  assert(length(stimulus)==5);
  if debugmode
    stimulus
  end

  %%%%% LOAD BEHAVIORAL FILES
  
  % load behavior files
  behaviors = {};
  for p=1:length(behavior_files)
    if isequal(behavior_files{p},'EMPTY')
      behaviors{p} = [];
    else
      a1 = xml2struct(behavior_files{p});  % relevant fields: expttype (1-5), ttlStamps
      behaviors{p} = a1.behav_summary;
    end
  end
  clear a1;
  
  % sanity check
  if debugmode
    behaviors
  end

  %%%%% LOAD DATA
  
  % load fMRI data
  data = {};  % each element is ~90000 x 300, single format
  for p=1:length(image_files)
    if isequal(image_files{p},'EMPTY')
      data{p} = [];
    else
      data{p} = single(getfield(ciftiopen(image_files{p},wbcmd),'cdata'));
    end
  end
  
  % sanity check
  if debugmode
    data
  end

  %%%%% DEAL WITH MISSING DATA
  
  % if any data is EMPTY, kill it all
  ok = cellfun(@(x) ~isempty(x),data);
  data = data(ok);
  behaviors = behaviors(ok);
  
  %%%%% SANITY CHECK THE BEHAVIORAL DATA AND CONSTRUCT FINAL STIMULUS

  % go through the behavioral files and check the timing.
  % as we go, we construct the final stimulus specification.
  % we crash if any sanity check fails (see below).
  finalstimulus = {};
  for p=1:length(behaviors)

    % if we lack a behavioral file, we crash
    if isempty(behaviors{p})
      error('Found an empty behavioral file (subject=%d, filenumber=%d).\n',subject,p);
    else

      % pull out the correct stimulus type
      fprintf('stimulus type detected: %d\n',behaviors{p}.expttype);
      finalstimulus{p} = stimulus{behaviors{p}.expttype};
      
      % strict check of the TTL stamps:
      % (1) we must have TTL stamps
      % (2) the difference between first and last must be in (298.5,299.5)
      % (3) the first TTL must have occurred within 100 ms before the stimulus started
      ok = ~isempty(behaviors{p}.ttlStamps) && ...
           abs(diff(behaviors{p}.ttlStamps([1 end])) - 299) < .5 && ...
           behaviors{p}.ttlStamps(1) > -.1 && ...
           behaviors{p}.ttlStamps(1) < 0;
      if ~ok
        error('TTL pulses in behavioral file did not pass sanity checks (subject=%d, filenumber=%d).\n',subject,p);
      end

    end

  end

  %%%%% DEAL WITH TRUNCATED DATA
  
  % we might be missing some data points at the end of a given run.
  % in such cases, just truncate the stimulus sequence to match the data.
  for p=1:length(data)
    if size(data{p},2) < size(finalstimulus{p},3)
      finalstimulus{p} = finalstimulus{p}(:,:,1:size(data{p},2));
    end
  end

  %%%%% FINALLY, ANALYZE THE DATA

  % analyze the data
  results = analyzePRF_chpc(userid,subject,finalstimulus,data,tr, ...
                            struct('vxs',vxs,'seedmode',seedmode, ...
                                   'numperjob',numperjob,'maxiter',maxiter,'display','off'));

  %%%%% MASSAGE THE OUTPUTS AND WRITE TO DISK

  % make the output directory
  mkdirquiet([outpath '/results']);

  % write out results
  writecifti(results.ang,                               sprintf('%s/results/%d_angle.dtseries.nii',outpath,subject));
  writecifti(results.ecc*pxtodeg,                       sprintf('%s/results/%d_eccentricity.dtseries.nii',outpath,subject));
  writecifti(results.rfsize*pxtodeg,                    sprintf('%s/results/%d_size.dtseries.nii',outpath,subject));
  writecifti(results.expt,                              sprintf('%s/results/%d_exponent.dtseries.nii',outpath,subject));
  writecifti(results.gain./results.meanvol*100,         sprintf('%s/results/%d_gain.dtseries.nii',outpath,subject));
  writecifti(results.R2,                                sprintf('%s/results/%d_varianceexplained.dtseries.nii',outpath,subject));
  writecifti(results.meanvol,                           sprintf('%s/results/%d_mean.dtseries.nii',outpath,subject));

catch me

  fprintf('Error: %s\n',me.message);
  if length(me.stack) > 0
    me.stack(1)
  end

end

% make sure we get out
fprintf('RetinotopyAnalysis.m complete.\n');
quit;
