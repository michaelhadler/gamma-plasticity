%Filter CED file

%Arguments
%input: filepath to .smr file
%channels: Channels to filter (double array)
%varags:
    % '50hz' = filter design for 50 Hz bandstop filter
    % '50hz' = filter design for 100 Hz bandstop filter
    % 'Bandpass' = filter design for bandpass filter
%output: filepath to output file

%Important: Load CED lib before running! See load_CED64.m and/or doc in
%s64mat.pdf

function filter_CED(input,output,channels,varargin)

if_50 = 0;
if_100 = 0;
if_bp = 0;

while ~isempty(varargin)
    switch lower(varargin{1})
        case '50hz'
            if_50 = 1;
            var_50 = varargin{2} ;
        case '100hz'
            if_100 = 1;
            var_100 = varargin{2};
        case 'bandpass'
            if_bp = 1;
            var_bp = varargin{2};
          otherwise
              error(['Unexpected option: ' varargin{1}])
     end
     varargin(1:2) = [];
end

%Get file information
ch_idx = channels;
% get waveform data from first selected channel
% +1 so the read gets the last point
fhand1 = CEDS64Open(input);
maxTimeTicks = CEDS64ChanMaxTime( fhand1, ch_idx(1) )+1;
% Get time rates in old file
tbase = CEDS64TimeBase( fhand1 );
chandiv = CEDS64ChanDiv( fhand1, ch_idx(1) );
fs = 1 / (chandiv * tbase) ; %actual sampling frequency

%Create new file
fhand2 = CEDS64Create( output, 32, 1 );
if (fhand2 <= 0)
    disp('Error creating file.')
end
%set time base as in old file
CEDS64TimeBase( fhand2, tbase );

for i = 1:length(ch_idx)
    % create new channel
    CEDS64SetWaveChan( fhand2, ch_idx(i), chandiv, 9, fs );
    CEDS64ChanTitle( fhand2, ch_idx(i), ['Ch ' num2str(ch_idx(i))]) ;
    CEDS64ChanUnits(fhand2, ch_idx(i),'µV') ;

    % get old channel
    [ ~ , fVals, ~ ] = CEDS64ReadWaveF( fhand1, ch_idx(i), 200000000, 0, maxTimeTicks );
    % filter 50 Hz if necessary
    if if_50 == 1
        Vals_50 = filtfilt(var_50,double(fVals));
    else
        Vals_50 = fVals;
    end
    clearvars fVals
    %filter 100 Hz if necessary
    if if_100 == 1
        Vals_100 = filtfilt(var_100,double(Vals_50));
    else
        Vals_100 = Vals_50;
    end
    clearvars Vals_50
    %bandpass if necessary
    if if_bp == 1
        NewVals = filtfilt(var_bp,double(Vals_100));
    else
        NewVals = Vals_100;
    end
    clearvars Vals_100
    %Write data to channel.
    CEDS64WriteWave( fhand2, ch_idx(i), NewVals, 0 );

end