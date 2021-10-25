function y = frame_spectrum(data,window,overlap,nfft,Fs)
    if nargin < 3
        window = 512;
        overlap = 256;
        nfft = 2048;
    end
    if isa(data,'double')
        data = data + 1e-10*1i;
    end

    % Param
    if nargin < 4
        Fs = param_configs(3);         % sample rate  
    end
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    num_samp = Fs * 2^SF / BW;     % number of samples of a chirp

    if Fs <= BW*2
        window = 64;
        overlap = 60;
        nfft = 2048;
    end

    % STFT
    s = spectrogram(data,window,overlap,nfft,'yaxis');

    % Cut target band
    if Fs > BW
        nvalid = floor(BW / Fs * nfft);
        % Add up
        y = s(1:nvalid,:);
        for i = 1:floor(nfft/nvalid)-1
            y = y + s(nvalid*i+(1:nvalid),:);
        end
        y = [y(ceil(nvalid/2):end,:); y(1:floor(nvalid/2),:)];
    else
        y = zeros(floor(BW/Fs * nfft), size(s,2));

        base = round(size(y,1) /2 );
        h1 = ceil(nfft/2);
        h2 = nfft-h1;
        y(base+1:base+h1,:) = s(1:h1,:);
        y(base-h2+1:base,:) = s(h1+1:end,:);
%                 y(flength/2+(0:floor(nfft/2)-1)) = s(1:floor(nfft/2),:);
%                 y(1:nfft,:) = s(1:nfft,:);
    end


%             figure;
        imagesc([1 num_samp],[-BW/2 BW/2]/1e3,abs(y)*20-40);
        set(gca,'YDir','normal');
%                 title('Spectrogram');
        xlabel('PHY sample #');
        ylabel('Frequency (kHz)');
        set (gcf,'position',[500,300,500,270] );
end