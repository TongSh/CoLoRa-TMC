function frame_show(file_path, payload_ref, out_path)
%     payload_ref = [2666,28,659,475,470,1635,243,3576,376,2335,3903,2503,425,198,45,3370,3340,1399,2185,115];
    max_payload = param_configs(6);      
    if nargin == 3
        % write out analysis result
        Utils.wfile('%s\n', 'FILE,Errros,SER', out_path, true);
    end
    

    fprintf('file = %s\n',file_path);

    fid = fopen(file_path, 'r');
    if fid == -1, error('Cannot open file: %s', file_path); end
    D = dir(file_path);
    
    frame_num = str2double(split(fgetl(fid),','));
    fgetl(fid); % escape title

    % extract info of each symbol
    value = [];
    belong = [];
    pkrt = [];
    while ~feof(fid) && D.bytes > 0
        temp = str2double(split(fgetl(fid),','));
        value = [value, temp(6)];
        belong = [belong, temp(5)];
        pkrt = [pkrt, temp(3)];
    end
    
    if nargin == 1
        for loop = 1:frame_num
            var = value(belong == loop);
            ratio = pkrt(belong == loop);
            
            ST = [1,0];
            ED = [length(ratio),0];
%             for loop2 = 1:length(ratio)
%                 if ratio(loop2) > 0 && ST(2) == 0
%                     ST(1) = loop2;
%                     ST(2) = 1;
%                 end
%                 
%                 if ratio(length(ratio) - loop2 + 1) > 0 && ED(2) == 0
%                     ED(1) = length(ratio) - loop2 + 1;
%                     ED(2) = 1;
%                 end
%             end
            
            ED = min(ED,ST+max_payload-1);
            var = var(ST:ED);
            fprintf('Packet%d: ',loop);
            for item=var
                fprintf('%d, ',item);
            end
            fprintf('END\n');
        end
        return;
    end

    % calculate symbol error rate
    for j = 1:frame_num
        v = value(belong == j);
        mindiff = -1;

        for mis = -10:10
            pool = [zeros(1,50), v, zeros(1,50)];
            mv = pool(50+mis +(1:length(payload_ref)));
            diffv = abs(mv - payload_ref);
            diffv(diffv < 3) = 0;
            diffv(diffv > 2) = 1;
            diff = sum(diffv);
            if mindiff < 0 || diff < mindiff
                mindiff = diff;
            end
        end

        disp([num2str(j),':',num2str(mindiff)]);
        Utils.wfile('%d,%d,%.2f\n', [j,mindiff,mindiff/20], outFile);
    end
   
    fclose all;

end