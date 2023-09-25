%load CED

%load DLL before reading/writing Spike2 data

%requires CED library on path, see doc in folder "CEDS64ML"

function load_CED64()

cedpath = getenv('CEDS64ML'); % should hold the path to the CEDS64ML folder
addpath( cedpath );
CEDS64LoadLib( cedpath );

end