function peaks = peak_detect(sig, sig_pre, sig_follow)
    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    MAX_PK_NUM = 30;         % maximum number of peaks
    DEBUG = false;

    % detect in-window distributions for signal in each window
    peaks = [];

%     figure;
    % iteratively extract the highest peak
    for loop = 1:MAX_PK_NUM
        % dechirpring and fft
        dn_chp = symb_gen_normal(0,true);
        match_tone = sig .* dn_chp;
        station_fout = fft(match_tone, nsamp*10);
%         if loop == 1
%             plot(abs(station_fout));
%         end
        
        % applying non-stationary scaling down-chirp
%         amp_lower_bound = 1;
%         amp_upper_bound = 1.2;
%         scal_func = linspace(amp_lower_bound,amp_upper_bound,nsamp);
%         match_tone = sig .* (scal_func .* dn_chp);
%         non_station_fout = fft(match_tone, nsamp*10);

        % peak infomation
        pk_height = -1;
        pk_index = 0;
        pk_phase = 0;
        
        % iterative compensate phase rotation 
        % (taking the advantage of over sampleing)
        align_win_len = length(station_fout) / (Fs/BW);
        for pending_phase = (0:19)/20*2*pi    
            targ = exp(1i*pending_phase)*station_fout(1:align_win_len) + station_fout(end-align_win_len+1:end);

            if max(abs(targ)) > pk_height
                [pk_height,pk_index] = max(abs(targ));
                pk_phase = pending_phase;
                targ_rec = targ;
            end
        end

        fidx = (0:numel(targ_rec)-1)/numel(targ_rec) * 2^SF;
        
        % threshold for peak detecting
        if loop == 1
            threshold = pk_height / 20;
        else
            if pk_height < threshold
                break;
            end
        end
        
        if DEBUG
        figure;
        subplot(3,3,1);
            plot(fidx, abs(targ_rec));
            title('Target FFT Peaks');
        end
            
        % Determine whether the peak is legitimate (whether it is duplicated)
        repeat = false;
        cbin = (1 - pk_index/align_win_len) * 2^SF;
        for pk = peaks
            if abs(pk.bin - cbin) < 2
                repeat = true;
                break;
            end
        end
        if repeat 
            break;
        end

        % Peak refining for iterative cancellation
        % SL or SR
        dn_chp = repmat(symb_gen_normal(0,true),1,2);
        yL = [sig_pre, sig];
        match_toneL = yL .* dn_chp;
        foutL = fft(match_toneL, numel(yL)*10);
        align_win_len = length(foutL) / (Fs/BW);
        targL = exp(1i*pk_phase) * foutL(1:align_win_len) + foutL(end-align_win_len+1:end);
        
        fidx = (0:numel(targL)-1)/numel(targL) * 2^SF;
        mindex = pk_index * 2;
        if DEBUG
        subplot(3,3,2); hold on
            plot(fidx, abs(targL));
            plot(fidx([mindex mindex]), [0 max(abs(targL))],'Color','r');
            title('Left FFT Peaks');
        end
            
        yR = [sig, sig_follow];
        match_toneR = yR .* dn_chp;
        foutR = fft(match_toneR, numel(yR)*10);
        align_win_len = length(foutR) / (Fs/BW);
        targR = exp(1i*pk_phase) * foutR(1:align_win_len) + foutR(end-align_win_len+1:end);
        
        if DEBUG
        subplot(3,3,3); hold on
            plot(fidx, abs(targR));
            plot(fidx([mindex mindex]), [0 max(abs(targR))],'Color','r');
            title('Right FFT peaks');
        
        subplot(3,3,4);
            plot(real(sig));
            title('[Origin] Time Domain Signal'); 
        end
        
        binw = ceil(numel(targL) / 2^SF);
        srg = mindex+(-binw*5:binw*5);
        srg = srg(srg >= 1);
        srg = srg(srg <= numel(targL));
        if max(abs(targL(srg))) > max(abs(targR(srg)))
            seg_loc = 1;    % adjacent to the previous window
        else
            seg_loc = 2;    % adjacent to the latter window
        end
        
        % Amplitude
        subl = nsamp / 8;
        if seg_loc == 1
            tmp = [match_tone(1:subl), zeros(1, nsamp-subl)];
        else
            tmp = [zeros(1, nsamp-subl), match_tone(end-subl+1:end)];
        end
        mfout = fft(tmp, nsamp*10);
        align_win_len = length(mfout) / (Fs/BW);
        mtarg = exp(1i*pk_phase)*mfout(1:align_win_len) + mfout(end-align_win_len+1:end);
        binw = ceil(numel(mtarg) / 2^SF);
        srg = pk_index+(-binw*10:binw*10);
        srg = srg(srg >= 1);
        srg = srg(srg <= numel(mtarg));
        amp = max(abs(mtarg(srg))) / nsamp * 8;
        
        % Duration
        seg_len = min(floor(pk_height / amp), nsamp);
        amp = pk_height / seg_len;
        freq = (0 : align_win_len-1) * BW / align_win_len;
        if seg_loc == 1
            [dout, sym] = symb_refine(true, seg_len, amp, freq(pk_index), sig);
        else
            [dout, sym] = symb_refine(false, seg_len, amp, freq(pk_index), sig);
        end
        peaks = [peaks,cpeak(sym.amp*sym.len, sym.freq, SF)];
        org_sig = sig;
        sig = dout;
        
        if DEBUG
        subplot(3,3,5);
            plot(real((org_sig - dout)));
            title('[Generated] Time Domain Signal');
        subplot(3,3,6);
            plot(real(sig));
            title('[Cancelled] Time Domain Signal');
            
        subplot(3,3,7);
            frame_spectrum(org_sig);
            title(['[Origin] Spectrum ', num2str(loop)]);
        
        subplot(3,3,8);
            frame_spectrum(sig);
            title(['[Cancelled] Spectrum ', num2str(loop)]);
            
        set (gcf,'position',[-1500,400,1000,800] );
        end
        
%         subplot(4,1,4);plot(real(dout));
        
        
%         % Scaling factor of peaks: alpha
%         targ = exp(1i * pk_phase) * non_station_fout(1:align_win_len) + non_station_fout(end-align_win_len+1:end);
%         alpha = abs(targ(pk_index)) / pk_height;
% 
%         % abnormal alpha
%         if alpha < amp_lower_bound || alpha > amp_upper_bound
%             return;
%         end
% 
%         % According to the scaling factor, reconstruct signal segment
%         freq = (0 : align_win_len-1) * BW / align_win_len;
%         if alpha < (amp_lower_bound + amp_upper_bound) / 2      % near previous window
%             seg_len = (alpha - amp_lower_bound) * 2 / (amp_upper_bound - amp_lower_bound) * nsamp;
%             amp = pk_height / seg_len;
%             [dout,sym] = symb_refine(true, seg_len, amp, freq(pk_index), sig);
%         else                                                    % near following window
%             seg_len = (amp_upper_bound - alpha) * 2 / (amp_upper_bound - amp_lower_bound) * nsamp;
%             amp = pk_height / seg_len;
%             [dout,sym] = symb_refine(false, seg_len, amp, freq(pk_index), sig);
%         end
%         peaks = [peaks,sym];
%         sig = dout;
    end
end