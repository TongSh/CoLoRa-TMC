function [snr_db,nPow,sPow] = frame_cal_snr(data)
    %CALSNR estimate the SNR of a received LoRa packet
    
    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    
    sig_n = data(nsamp+(1:nsamp*32));
    dn_chp = symb_gen_normal(0,true);
    match_tone = sig_n .* repmat(dn_chp,1,32);

    [snr_db,nPow] = snr(real(match_tone),Fs);

    totalNoise = 10^(nPow/10);
    totalSig = 10^(snr_db/10) * totalNoise;
    sPow = 10*log10(totalSig);

    fprintf("SNR = %g,nPow = %gdB,sPow = %gdB(%g)\n",snr_db,nPow,sPow,totalSig);
end