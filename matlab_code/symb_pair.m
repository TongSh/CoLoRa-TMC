function pk_ratio = symb_pair(pk, pre_set)
    % Pair a peak of the same frequency

    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
   
    idx_array = zeros(1, pre_set.size);
    for i = 1:pre_set.size
        idx_array(i) = pre_set.symset(i).bin;
    end
    
    [I, value] = nearest(idx_array, pk.bin, 3);
    if I < 0
        pk_ratio = Inf;
    else
        pk_ratio = pk.height / pre_set.symset(I).height;
    end
end
    
function [I,value] = nearest(array,target,threshold)
    if isempty(array) || isnan(target)
        value = -1;
        I = -1;
        return
    end
    delta = abs(array-target);
    [va,I] = min(delta);
    value = array(I);
    if nargin == 3 && ~isempty(threshold) && va > threshold
        value = -1;
        I = -1;
    end
end