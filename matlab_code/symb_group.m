function dout = symb_group(syms, pkts, wid)
    % Group symbols to the correponding packets
    
    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    max_payload = param_configs(6);
    nsamp = Fs * 2^SF / BW;
    
    dout = [];
    
    for pid = 1:length(pkts)
        p = pkts(pid);
        if wid <= p.start_win + 12
            continue;
        end
        
        if wid > p.start_win + 12 + max_payload
            continue;
        end
        
        pkt_ratio = p.to / (nsamp - p.to);
        
        ratio_set = zeros(1, length(syms));
        for i = 1:length(syms)
            ratio_set(i) = syms(i).peak_ratio;
        end
        
%         lenset = zeros(1,length(syms));
%         for i = 1:length(syms)
%             if syms(i).ahead
%                 if syms(i).len >= nsamp / 2
%                     lenset(i) = syms(i).len;
%                 end
%             else
%                 if syms(i).len >= nsamp / 2
%                     lenset(i) = nsamp - syms(i).len;
%                 end
%             end
%         end
        
        [I,value] = peak_nearest(ratio_set, pkt_ratio, pkt_ratio*0.1);
        
        fprintf('PKT[%d]: ',round(p.to));
        for i = 1:length(ratio_set)
            fprintf('%d ',round(ratio_set(i)));
        end
        fprintf('\n');
        
        if I < 0
            sym = csymbol(0, 1, 0, Inf);
            sym.belong(pid);
            dout = [dout, sym];
        else
            sym = syms(I);
            syms = [syms(1:I-1),syms(I+1:end)];
            sym.belong(pid);
            dout = [dout, sym];
        end
    end
end