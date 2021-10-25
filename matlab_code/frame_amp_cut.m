function B = frame_amp_cut(datain)
    %AMPCUT extract the useful signal based on the amplitude

    % parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    
    mwin = nsamp/2;
    A = movmean(abs(datain),mwin);
    B = datain(A >= max(A)/2);
end