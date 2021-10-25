function symb = symb_gen_normal(code_word,down,Fs)
    if nargin < 3 || isempty(Fs) || Fs < 0
        Fs = param_configs(3);         % default sample rate
    end      
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    org_Fs = Fs;
    if Fs < BW
        Fs = BW;
    end
    T = 0:1/Fs:2^SF/BW-1/Fs;       % time vector a chirp
    num_samp = Fs * 2^SF / BW;     % number of samples of a chirp

    % I/Q traces
    f0 = -BW/2; % start freq
    f1 = BW/2;  % end freq
    chirpI = chirp(T, f0, 2^SF/BW, f1, 'linear', 90);
    chirpQ = chirp(T, f0, 2^SF/BW, f1, 'linear', 0);
    baseline = complex(chirpI, chirpQ);
    if nargin >= 2 && down
        baseline = conj(baseline);
    end
    baseline = repmat(baseline,1,2);
%             baseline = [baseline, baseline*exp(1i*(0))];
    clear chirpI chirpQ

    % Shift for encoding
    offset = round((2^SF - code_word) / 2^SF * num_samp);
    symb = baseline(offset+(1:num_samp));

    if org_Fs ~= Fs
        overSamp = Fs/org_Fs;
        symb = symb(1:overSamp:end);
    end
end