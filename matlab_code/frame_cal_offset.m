function [cfo,sto] = frame_cal_offset(upsig, dnsig)
    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    
    % input signal has been roughly synchronized (peak appear near zero bin)
    dn_chp = symb_gen_normal(0,true);
    match_tone = upsig .* dn_chp;
    nfft = length(match_tone)*10;
    fout = fft(match_tone, nfft);
    upz = symb_freq_alias(fout);
    
    num_bins = length(upz);
    freq_idx = (0:num_bins-1) * BW/num_bins;
    
    % peaks in the range of 0¡À2kHz is retained
    reta_rang = round(2e3/BW * num_bins);
    upz(reta_rang+1 : end-reta_rang) = 0;
%     upz(round(nfft/BW) : end - round(nfft/BW)) = 0;
    [~,I] = max(abs(upz));
    upf = freq_idx(I);

    % peak frequency of down chirp
    up_chp = symb_gen_normal(0,false);
    match_tone = dnsig .* up_chp;
    fout = fft(match_tone, nfft);
    dnz = symb_freq_alias(fout);
    
    num_bins = length(upz);
    freq_idx = (0:num_bins-1) * BW/num_bins;
    
    reta_rang = round(2e3/BW * num_bins);
    dnz(reta_rang+1 : end-reta_rang) = 0;
    [~,I] = max(abs(dnz));
    dnf = freq_idx(I);
    
%     figure;
%         plot(freq_idx,upz);
%         hold on
%         plot(freq_idx,dnz);

    cfo = (upf + dnf) / 2;
    fprintf('CFO=%.2f\n', cfo);
    if abs(cfo) > 200e3
        cfo = cfo - BW;
    else
        if abs(cfo) > 10e3
            if cfo < 0
                cfo = cfo + BW/2;
            else
                cfo = cfo - BW/2;
            end
        end
    end
    
    sto = (dnf - cfo) / BW * (2^SF/BW);
end