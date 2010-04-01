function []=compileAndRunForCluster(nameOfFunction, user, path,M, mem,libraries)

%==============================================================================
% Test the arguments
if ~strcmp('.m',nameOfFunction(end-1:end)),
   error('nameOfFunction must be a *.m file')
end

if strcmp('/',path(end)),
   path = path(1:end-1);
end

if (nargin==6) && strcmp('/',libraries(end)),
      libraries = libraries(1:end-1);
end

if ~exist( path ),
   error('The path to the src does not exist');
end

if (nargin==6) && ~exist( libraries  ),
      error('The path to the lib does not exist');
end

%==============================================================================

cd(path);

execPath=[path '/exec' nameOfFunction(1:end-2)];

[status,message,messageid] = mkdir(execPath);

if nargin<6
    libraries='';
end

numThreads=1;

numThreads=num2str(numThreads);

defaultLibraries='/data/warith/lib64';

logPath=[execPath '/logs'];

[status,message,messageid] = mkdir(logPath);

defaultMCRpath='/data/warith/MATLAB_Compiler_Runtime/v710';
mcrPath=defaultMCRpath;

jobsFile=[execPath '/jobsSentToQSubFor_' nameOfFunction(1:end-2) '.txt'];

if exist(fullfile(execPath, nameOfFunction), 'file') ~= 2
	eval(['mcc -m ' nameOfFunction ' -d ' execPath ' -a ./']);
end

[n,p]=size(M);

if ~iscell(M)
    M={M};
end

fid=fopen(jobsFile,'w');

for i=1:n
    
    args='';
    
    for j=1:p
        args=[args num2str(M{i,j}) ' '];
    end
    
    
    fprintf(fid,['sh ' execPath '/run_' nameOfFunction(1:end-2) '_generatedByCompileForCluster.sh ' args '\n']);
    
end
fclose(fid);


fid=fopen([execPath '/run_' nameOfFunction(1:end-2) '_generatedByCompileForCluster.sh'],'w');

fprintf(fid,'#!/bin/sh \n');
fprintf(fid,'exe_name=$0 \n');
fprintf(fid,'exe_dir=`dirname $0` \n');
fprintf(fid,'echo "------------------------------------------" \n');
fprintf(fid,'if [ "x$1" = "x" ]; then \n');
fprintf(fid,'  echo Usage: \n');
fprintf(fid,'  echo    $0 \\<deployedMCRroot\\> args \n');
fprintf(fid,'else \n');
fprintf(fid,'  echo Setting up environment variables \n');
fprintf(fid,['  MCRROOT=' mcrPath ' \n']);
fprintf(fid,'  echo --- \n');
fprintf(fid,'  MWE_ARCH="glnxa64" ; \n');
fprintf(fid,'  if [ "$MWE_ARCH" = "sol64" ] ; then \n');
fprintf(fid,'	LD_LIBRARY_PATH=.:/usr/lib/lwp:${MCRROOT}/runtime/glnxa64 ;  \n');
fprintf(fid,'  else \n');
fprintf(fid,'  	LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ; \n');
fprintf(fid,'  fi \n');
fprintf(fid,'  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ; \n');
fprintf(fid,'  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64; \n');
fprintf(fid,'  if [ "$MWE_ARCH" = "maci" -o "$MWE_ARCH" = "maci64" ]; then \n');
fprintf(fid,'	DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:/System/Library/Frameworks/JavaVM.framework/JavaVM:/System/Library/Frameworks/JavaVM.framework/Libraries; \n');
fprintf(fid,'  else \n');
fprintf(fid,'	MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64 ; \n');
fprintf(fid,'	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ;  \n');
fprintf(fid,'	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ; \n');
fprintf(fid,'	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ; \n');
fprintf(fid,'	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;   \n');
fprintf(fid,'  fi \n');
fprintf(fid,'  XAPPLRESDIR=${MCRROOT}/X11/app-defaults ; \n');
fprintf(fid,['	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:' defaultLibraries ':' libraries ' ;   \n']);
fprintf(fid,'  export LD_LIBRARY_PATH; \n');
fprintf(fid,'  export XAPPLRESDIR; \n');
fprintf(fid,'  echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH}; \n');
fprintf(fid,[ execPath '/' nameOfFunction(1:end-2) ' $* \n']);
fprintf(fid,'fi \n');
fprintf(fid,'exit \n');



fclose(fid);

code=[execPath '/' nameOfFunction(1:end-2) '_' user '_jobLauncher.sh'];
fid=fopen(code,'w');


fprintf(fid,'#!/bin/bash \n');
fprintf(fid,'QSTAT="/cvos/shared/apps/torque/2.1.8/bin/qstat"\n');
fprintf(fid,'QSUB="/cvos/shared/apps/torque/2.1.8/bin/qsub"\n');
fprintf(fid,['USER=' user ' \n']);
fprintf(fid,['CODESH=' jobsFile ' \n']);
fprintf(fid,['FOLDER=' path ' \n']);
fprintf(fid,'cd $FOLDER \n');
fprintf(fid,'SUFF=withoutSpaces.txt \n');
fprintf(fid,['MEM=' mem ' \n']);
fprintf(fid,'CODESH2=$CODESH$SUFF \n'); 
fprintf(fid,'echo $CODESH2 \n');
% fprintf(fid,'cat $CODESH > $CODESH2 \n');
fprintf(fid,'sed ''/^$/d'' $CODESH > $CODESH2 \n');
fprintf(fid,'COUNT=0 \n');
fprintf(fid,'COUNTMIN=0 \n');
fprintf(fid,'COUNTMAX=1000000 \n');
fprintf(fid,'COUNTERJOBS=`$QSTAT | grep $USER | wc -l` \n');
fprintf(fid,'while read LINECOMMAND \n');
fprintf(fid,'do \n');
fprintf(fid,'	COUNT=$(($COUNT+1)); \n');
fprintf(fid,'	if [ "$COUNT" -ge "$COUNTMIN" ] \n');
fprintf(fid,'            then \n');
fprintf(fid,'               if [ "$COUNT" -le "$COUNTMAX" ] \n');
fprintf(fid,'               then \n');
fprintf(fid,'                  while [ "$COUNTERJOBS" -ge "30" ]; do \n');
fprintf(fid,'                     echo $COUNTERJOBS \n');
fprintf(fid,'                     sleep 20 \n');
fprintf(fid,'                     COUNTERJOBS=`$QSTAT | grep $USER | wc -l` \n');
fprintf(fid,'                  done \n');
% fprintf(fid,'		COMMANDWITHOUTSPACES=$(echo $LINECOMMAND|sed ''s/ /_/g'') \n');
% fprintf(fid,'		JOBNAME=job_$USER$COUNT$COMMANDWITHOUTSPACES; \n');
fprintf(fid,['		JOBNAME=job_' nameOfFunction(1:end-2) '_$COUNT; \n']);
fprintf(fid,['                  echo "#PBS -l nodes=1:ppn=' numThreads ' \n']);
fprintf(fid,'		#PBS -l walltime=399:00:00 \n');
fprintf(fid,'		#PBS -l mem=$MEM \n');
fprintf(fid,['		#PBS -e ' logPath ' \n']);
fprintf(fid,['		#PBS -o ' logPath ' \n']);
fprintf(fid,'		#PBS -N $JOBNAME \n');
fprintf(fid,'		echo $LINECOMMAND ; \n');
fprintf(fid,['		cd ' path '; mkdir ' logPath '; $LINECOMMAND > ' logPath '/report_$JOBNAME.txt \n']);
fprintf(fid,['                  " > ' logPath '/$JOBNAME.pbs \n']);
fprintf(fid,['                  $QSUB ' logPath '/$JOBNAME.pbs \n']);
fprintf(fid,'                  sleep 0.1 \n');
fprintf(fid,'                  COUNTERJOBS=`$QSTAT | grep $USER | wc -l` \n');
fprintf(fid,'               fi \n');
fprintf(fid,'            fi \n');
fprintf(fid,'done < $CODESH2 \n');


fclose(fid);

tmp=[path '/tmp_' nameOfFunction(1:end-2) '.txt'];
fid=fopen(tmp,'w');
fprintf(fid,['cd ' path ' ; sh ' code ' ;']);
fclose(fid);

system(['chmod 777 ' tmp]);

system(['ssh meleze.inria.fr ' tmp]);

disp(['If you want to run your code without compiling it again do : ssh meleze.inria.fr ' tmp]);



