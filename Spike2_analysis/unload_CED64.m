%unload CED

%load DLL before reading/writing Spike2 data

%requires CED library on path, see doc in folder "CEDS64ML"

function unload_CED64()

%Close all, unload dll.
CEDS64CloseAll(); % close all the files
unloadlibrary ceds64int; % unload ceds64int.dll

end