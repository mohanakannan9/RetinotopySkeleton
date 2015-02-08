function CHPCwait(jobnames,jobids,userid)

% function CHPCwait(jobnames,jobids,userid)
%
% <jobnames> is a job name or a cell vector of job names
% <jobids> is a vector of job IDs
% <userid> is a string referring to the user that submitted the jobs
%
% periodically check on job status and report to the command window.
% we exit when all of the jobs are completed.  if any job errors are 
% detected, we issue an error.

% internal constants
pausetime = 60;  % seconds to wait before checking again
weirdtime = 10;  % seconds to wait if unexpected exit code

% input
if ~iscell(jobnames)
  jobnames = {jobnames};
end

% wait until jobs are done
fprintf('waiting for jobs to finish.\n');
while 1
  pause(pausetime);

  % check if jobs are done
  fprintf('checking if jobs are done (%s): ',datestr(now));
  temp = catcell(2,cellfun(@(x) [num2str(x) '|'],num2cell(jobids),'UniformOutput',0));
  str = sprintf('qstat -t -u %s | grep -E ''(%s)'' | grep -v '' C '' | wc -l',userid,temp(1:end-1));
  [s,r] = unix(str);
  while (s~=0 && s~=1)
    fprintf('STATUS WASNT 0 OR 1, WEIRD; TRY AGAIN IN A FEW SECONDS\n');
    pause(weirdtime);
    [s,r] = unix(str);
  end

  % report the number of jobs found
  fprintf('%d jobs. ',str2double(r));
  if str2double(r) ~= 0
    fprintf('qstat is not empty.\n');
  else
    fprintf('qstat is empty! checking for errors...');
    for jj=1:length(jobnames)

      strB = sprintf('cat ~/sgeoutput/job_%s.e*',jobnames{jj});
      [s,r] = unix(strB);
      while s~=0
        fprintf('STATUS WASNT 0, WEIRD; TRY AGAIN IN A FEW SECONDS\n');
        pause(weirdtime);
        [s,r] = unix(strB);
      end

      if ~isempty(r)
        error('Errors were found in the .e files for job_%s',jobnames{jj});
      end
    end
    fprintf('done!\n');
    break;
  end
end
fprintf('ok, jobs are done!.\n');
