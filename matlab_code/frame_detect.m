function [start, value] = frame_detect(winset)

    % LoRa modulation & sampling parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;

    start = [];
    value = [];
    state_table = containers.Map('KeyType','double','ValueType','double');
    pending_keys = containers.Map('KeyType','double','ValueType','double');
    
    % window by window traversal
    for i = 1:length(winset)
        fprintf('window(%d)\n',i);
        key_set = cell2mat(keys(state_table));
        update_keys = containers.Map('KeyType','double','ValueType','double');
        
        % print keys
        fprintf('Keys:');
        for k = key_set
            update_keys(k) = 0;
            fprintf(' %d',round(k));
        end
        fprintf('\n');

        % group each symbol to a possible frame
        symbset = winset(i).symset;
        
        % print symbs
        fprintf('symbs:');
        for k = symbset
            fprintf(' %.d',round(k.bin));
        end
        fprintf('\n');
        
        for sym = symbset
            % detect consecutive preambles 
            [I, key] = peak_nearest(key_set, sym.bin, 2);
            if I < 0
                state_table(sym.bin) = 1;
            else
                state_table(key) = state_table(key) + 1;
                update_keys(key) = 1;
                if state_table(key) >= 5
                    pending_keys(key) = 10;
                end
            end
            
            % detect the first sync word (8)
            [I, key] = peak_nearest(key_set, mod(-1+sym.bin+24, 2^SF)+1, 2);
            if I > 0 && pending_keys.isKey(key)
                fprintf('SYNC-1: %d\n',round(key));
                pending_keys(key) = 10;
                state_table(key) = state_table(key) + 1;
                update_keys(key) = 1;
            end
            
            % detect the second sync word (16)
            [I,key] = peak_nearest(key_set, mod(-1+sym.bin+32,2^SF)+1, 2);
            if I > 0 && pending_keys.isKey(key) && pending_keys(key) > 5
                fprintf('SYNC-2: %d\t Frame Detected\n',round(key));
                start = [start, i-9];
                value = [value, key];
                remove(pending_keys, key);
                update_keys(key) = 0;
            end
        end

        % delete items without updated
        for k = key_set
            if pending_keys.isKey(k) && pending_keys(k) > 0
                if update_keys(k) == 0
                    pending_keys(k) = pending_keys(k) - 1;
                    update_keys(k) = 1;
                end
            end
            
            if update_keys(k)== 0
                remove(state_table, k);
                fprintf('\tRemove %.2f from table\n',k);
            end
        end
    end
end