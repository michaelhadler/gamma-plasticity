%Filter multiple files MCS
%This function will filter all files chosen by both a low- and high-pass
%filter and write them to h5-files in the same folder. Requires filtfilt,
%h5create/write and DataManager Tool of Multichannel Systems

%file: Name(s) of h5-file(s) to be filtered entered as string array. If left empty, will prompt uigetfile
%with MultiSelect. h5 files are created by DataManager Tool (https://www.multichannelsystems.com/downloads/software)
%low_pass: Two value vector bordering the edges of low-pass filter, e.g. [1 80]
%high_pass: Two value vector bordering the edges of high-pass filter, e.g.
%[100 300]
%order: Order of filter
%channel_num: number of channels to be filtered at once (values: 10, 20, 30, 60)

function multi_filter_MCS(file,low_pass,high_pass,order,channel_num)

    if isempty(file)
        [name, path] = uigetfile('*.h5','MultiSelect','on') ;
        name = string(name) ;
        for i = 1:length(string(name))
            filepath(i,:) = append(path,name(i)) ;
        end
        number_of_files = size(filepath,1) ;
    else
        filepath = file ;
        number_of_files = size(file,1) ;
    end
    
    %Filter data
    for m = 1:number_of_files
    
        %metadata first file
        data = McsHDF5.McsData(filepath(m,:)) ;
        %sampling frequency
        fs = 1/McsHDF5.TickToSec(data.Recording{1,1}.AnalogStream{1,1}.Info.Tick(1)) ; %take first value of first electrode
        %number of channels, electrode names
        channel_length = length(data.Recording{1,1}.AnalogStream{1,1}.Info.ChannelID) ;
        
        %Check if filtered data exist in filepath
        %Get new filename
        [folder, basename(m,:)] = fileparts(filepath(m,:)) ;
        new_name = basename(m,:) ;
        new_name_low = append(new_name,'_Lowpass_',num2str(low_pass(1)),'-',num2str(low_pass(2)),'_',num2str(order),'.h5') ;
        filepath_low(m,:) = append(folder,'\',new_name_low) ;
        new_name_high = append(new_name,'_Highpass_',num2str(high_pass(1)),'-',num2str(high_pass(2)),'_',num2str(order),'.h5') ;
        filepath_high(m,:) = append(folder,'\',new_name_high) ;
        clear folder
        
        is_low = isfile(filepath_low(m,:)) ;
        is_high = isfile(filepath_high(m,:)) ;
        
        %If they don't exist, create files
        if is_low == 0
            disp('Generating low-pass filtered file ...')
            tic
            %design filter: Bandpass
            BPfilt_low = designfilt('bandpassiir', 'FilterOrder', order, ...
            'HalfPowerFrequency1', low_pass(1),'HalfPowerFrequency2', low_pass(2), ...
            'SampleRate', fs, 'DesignMethod', 'butter') ;
            
            %Create copy of file with filter name
            copyfile(filepath(m,:),filepath_low(m,:)) ;
            
            %Section data according to channel_num. Label removed channels -1.
            channels = reshape(1:60, channel_num, [])' ;
            if channel_length ~= 60
                %Get dividend and modulo of actual channels / 60.
                div_val = floor(channel_length / channel_num) ;
                mod_val = mod(channel_length,channel_num) ;
                if mod_val > 0
                    channels = channels(1:div_val+1,:) ;
                    remove_idx = channels(1,:) > mod_val ;
                    channels(end,remove_idx) = - 1 ;
                else
                    channels = channels(1:div_val,:) ;
                end
            end
            
            %Get data
            for j = 1:size(channels,1)
                
                channel_set = channels(j,:) ;
                %Remove -1
                channel_set = channel_set(channel_set > -1) ;
                cfg = [] ;
                cfg.channel = [channel_set(1) channel_set(end)] ;
            
                stream = data.Recording{1,1}.AnalogStream{1,1}.readPartialChannelData(cfg) ;
                sample = stream.ChannelData' ;
                sample_length = size(sample,1) ;
        
                sample = filtfilt(BPfilt_low,sample) ;
                
                %Re-convert with conversion factor, round, and convert as int32
                sample = sample / double(data.Recording{1,1}.AnalogStream{1,1}.Info.ConversionFactor(1)) ;
                sample = int32(round(sample)) ;
                
                %Write to copied .h5 file in directory of raw data
                h5write(filepath_low(m,:),'/Data/Recording_0/AnalogStream/Stream_0/ChannelData',sample,[1 channel_set(1)],[sample_length length(channel_set)]) ;
                
                %Write filter specs in copied .h5 filter
                info_filter = ["Filter Type", "Low Cut", "High Cut", "Order";
                "Band-Pass" low_pass(1) low_pass(2) order] ;
            
            end
        
            h5create(filepath_low(m,:),'/Filter_Info', size(info_filter),'Datatype','string') ;
            h5write(filepath_low(m,:),'/Filter_Info', info_filter) ;
            
            toc
            disp('Lowpass filtered file generated.')
            clear info_filter sample sample_length stream cfg channel_set i
            clear channels remove_idx mod_val div_val BPfilt_low
        else
            disp('Lowpass filtered file already in directory.')
            
        end
        
        if is_high == 0
            disp('Generating high-pass filtered file ...')
            tic
            %design filter: Bandpass
            BPfilt_high = designfilt('bandpassiir', 'FilterOrder', order, ...
            'HalfPowerFrequency1', high_pass(1),'HalfPowerFrequency2', high_pass(2), ...
            'SampleRate', fs, 'DesignMethod', 'butter') ;
            
            %Create copy of file with filter name
            copyfile(filepath(m,:),filepath_high(m,:)) ;
            
            %Section data according to channel_num. Label removed channels -1.
            channels = reshape(1:60, channel_num, [])' ;
            if channel_length ~= 60
                %Get dividend and modulo of actual channels / 60.
                div_val = floor(channel_length / channel_num) ;
                mod_val = mod(channel_length,channel_num) ;
                if mod_val > 0
                    channels = channels(1:div_val+1,:) ;
                    remove_idx = channels(1,:) > mod_val ;
                    channels(end,remove_idx) = - 1 ;
                else
                    channels = channels(1:div_val,:) ;
                end
            end
            
            %Get data
            for k = 1:size(channels,1)
                
                channel_set = channels(k,:) ;
                %Remove -1
                channel_set = channel_set(channel_set > -1) ;
                cfg = [] ;
                cfg.channel = [channel_set(1) channel_set(end)] ;
            
                stream = data.Recording{1,1}.AnalogStream{1,1}.readPartialChannelData(cfg) ;
                sample = stream.ChannelData' ;
                sample_length = size(sample,1) ;
        
                sample = filtfilt(BPfilt_high,sample) ;
                
                %Re-convert with conversion factor, round, and convert as int32
                sample = sample / double(data.Recording{1,1}.AnalogStream{1,1}.Info.ConversionFactor(1)) ;
                sample = int32(round(sample)) ;
                
                %Write to copied .h5 file in directory of raw data
                h5write(filepath_high(m,:),'/Data/Recording_0/AnalogStream/Stream_0/ChannelData',sample,[1 channel_set(1)],[sample_length length(channel_set)]) ;
                
                %Write filter specs in copied .h5 filter
                info_filter = ["Filter Type", "Low Cut", "High Cut", "Order";
                "Band-Pass" high_pass(1) high_pass(2) order] ;
            
            end
        
            h5create(filepath_high(m,:),'/Filter_Info', size(info_filter),'Datatype','string') ;
            h5write(filepath_high(m,:),'/Filter_Info', info_filter) ;
            
            toc
            disp('Highpass filtered file generated.')
            clear info_filter sample sample_length stream cfg channel_set i
            clear channels remove_idx mod_val div_val BPfilt_high
        else
            disp('Highpass filtered file already in directory.')
            
        end
        clear data is_high is_low name new_name new_name_high new_name_low j k
        
        %Count files
        out = inputname(1) ;
        disp(append(out, " is completed."))
        disp(append(num2str(m), " files filtered in their entirety."))
    end
    


end
