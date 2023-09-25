%Load MCS data

%Uses McsHDF5 function to load data and store as double variable in µV

%filepath: string to data file (h5)

%time_window: Window of interest (seconds)
%varargin:
    %'Channels': double array of channel indexes (e.g. [5 15]) you would like to import
    %'ROI': Time window you would like to import (seconds, e.g. [60 120])

function [output,channels] = loadMCS(filepath, varargin)

%metadata
data = McsHDF5.McsData(filepath) ;
%sampling frequency
fs = 1/McsHDF5.TickToSec(data.Recording{1,1}.AnalogStream{1,1}.Info.Tick(1)) ; %take first value of first electrode
%length in time stamps
data_length = length(data.Recording{1,1}.AnalogStream{1,1}.ChannelDataTimeStamps) ;
data_length_sec = data_length/fs ;
ROI = [0 data_length_sec];

%Set data to µV
exponent_microv = 10^double(data.Recording{1,1}.AnalogStream{1,1}.Info.Exponent(1)) * 1000000 ;
%Electrodes
electrodes = str2double(data.Recording{1,1}.AnalogStream{1,1}.Info.Label) ;
channels = [1 length(electrodes)];

%set time window
cfg = [] ;
cfg.channel = channels;
cfg.window = ROI ;

%Varargin
while ~isempty(varargin)
    switch lower(varargin{1})
        case 'channels'
              cfg.channel = varargin{2} ;
          case 'roi'
              cfg.window = varargin{2} ;
          otherwise
              error(['Unexpected option: ' varargin{1}])
     end
     varargin(1:2) = [];
end

%get channels
partialData = data.Recording{1}.AnalogStream{1}.readPartialChannelData(cfg) ;
output = partialData.ChannelData' * exponent_microv ;

