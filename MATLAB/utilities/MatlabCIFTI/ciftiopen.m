function [ cifti ] = ciftiopen(filename,caret7command)
%Open a CIFTI file by converting to GIFTI external binary first and then
%using the GIFTI toolbox

rng shuffle
RANDOM = randi(1000000,1);
tic
unix([caret7command ' -cifti-convert -to-gifti-ext ' filename ' ' filename num2str(RANDOM) '.gii']);
toc

%unix(['/media/1TB/matlabsharedcode/cifticlean.sh ' filename num2str(RANDOM) '.gii ' filename num2str(RANDOM) '_.gii']);

tic
%cifti = gifti([filename num2str(RANDOM) '_.gii']);
cifti = gifti([filename num2str(RANDOM) '.gii']);
toc

%unix([' rm ' filename num2str(RANDOM) '.gii ' filename num2str(RANDOM) '.gii.data ' filename num2str(RANDOM) '_.gii']);
unix([' rm ' filename num2str(RANDOM) '.gii ' filename num2str(RANDOM) '.gii.data ']);


end

