clc
clear
close all

% LoRa modulation & sampling parameters
Fs = param_configs(3);         % sample rate        
BW = param_configs(2);         % LoRa bandwidth
SF = param_configs(1);         % LoRa spreading factor
nsamp = Fs * 2^SF / BW;
payload_len = 10;

% % load raw signal
% %
mdata = io_read_iq('input/collisions_2');
% mdata = [zeros(1,nsamp/2), mdata];
frame_spectrum(mdata);
        
%%
% % detect FFT peaks in each reception window
win_num = ceil(length(mdata) / nsamp); 
win_set(1,win_num) = cwin(0);

mdata = [mdata, zeros(1,nsamp*win_num - length(mdata))];
for i = 1:win_num
    win_set(i) = cwin(i);  
    symb = mdata((i-1)*nsamp + (1:nsamp));
    
    if i == 1
        symb_pre = zeros(1, nsamp);
    else
        symb_pre = mdata((i-2)*nsamp + (1:nsamp));
    end
    
    if i == win_num
        symb_follow = zeros(1, nsamp);
    else
        symb_follow = mdata(i*nsamp + (1:nsamp));
    end
    
    pks = peak_detect(symb, symb_pre, symb_follow);
%     close all;
    for pk = pks
        win_set(i).addPeak(pk);
    end
    win_set(i).show;
end

%%
% calculate peak ratios for each peak
sym_set(1,win_num) = cwin(0);
for pk = win_set(1).symset
    sym_set(1) = cwin(1);  
    sym_set(1).addPeak(csymbol(pk.freq, pk.height, nsamp, Inf));
end
for i = 2:win_num
    sym_set(i) = cwin(i); 
    for pk = win_set(i).symset
        pk_ratio = symb_pair(pk, win_set(i-1));
        sym_set(i).addPeak(csymbol(pk.freq, pk.height, nsamp, pk_ratio));
    end
    sym_set(i).show();
end

%%
% detect LoRa frames by preambles
[start_win,bin_value] = frame_detect(sym_set);

if isempty(start_win)
    disp('ERROR: No packet is found!!!\n');
    return;
end

%%
% detect STO and CFO for each frame
packet_set(1,length(start_win)) = cpacket(0,0,0);
for i = 1:length(start_win)
    fprintf('y(%d),value(%.1f)\n',start_win(i),bin_value(i));
    
    % coarse synchronization (moving peak around zero bin)
    offset = round(bin_value(i) / 2^SF * nsamp);
    
    if start_win(i) > numel(mdata)/nsamp - 20
        packet_set(i) = cpacket(start_win(i),0,0);
        continue;
    end
    
    upsig = mdata((start_win(i)+2)*nsamp + offset + (1:nsamp));
    downsig = mdata((start_win(i)+9)*nsamp + offset +(1:nsamp));
    
%     figure;
%         subplot(2,1,1);
%         frame_spectrum(upsig);
%         subplot(2,1,2);
%         frame_spectrum(downsig);
    
    [cfo,sto] = frame_cal_offset(upsig, downsig);
    sto = mod(round(sto*Fs+offset+0.25*nsamp), nsamp);
    packet_set(i) = cpacket(start_win(i),cfo,sto);
    fprintf('Packet from %d: CFO = %.2f, TO = %d\n',i,cfo,sto);
end

%%
% group each symbol to corresponding TX
% outFile = ['data/out/', num2str(snr), '_', num2str(con),'.csv'];
outFile = 'output/result.csv';

io_write_text('%d\n', length(packet_set), outFile, true);
io_write_text('%s', 'window,bin,peak ratio,amplitude,belong,value', outFile);

code_array = zeros(length(packet_set), payload_len*2);
for w = sym_set
    fprintf('Window(%d)\n',w.id);

    symset = symb_group(w.symset, packet_set, w.id);
    
    for s = symset
        s.show();
        
        sto =  nsamp - packet_set(s.pkt_id).to;
        cfo = 2^SF * packet_set(s.pkt_id).cfo/ BW;

        value = mod(2^SF - s.bin - sto/nsamp*2^SF - cfo, 2^SF);
        code_array(s.pkt_id, w.id-10) = round(value);
        
        fprintf('\t\t     value = %d\n', round(value));
        s.write(outFile, w.id, s.pkt_id, round(value));
    end
end 

frame_show(outFile);

fprintf('Experiment Finish!\n'); 