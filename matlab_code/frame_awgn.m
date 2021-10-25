function dataout = frame_awgn(datain,snr)
%ADDNOISE Summary of this function goes here
% datain is generated frame signal without noise
    amp_sig = mean(abs(datain));
    amp_noise = amp_sig/10^(snr/20);
    fprintf('sig amplitude:%.2f, noise amplitude:%.2f\n',amp_sig,amp_noise);
    dlen = length(datain);
    dataout  = datain + (amp_noise/sqrt(2) * randn([1 dlen]) + 1i*amp_noise/sqrt(2) * randn([1 dlen]));
end