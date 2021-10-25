function par = param_configs(p_id)

    % LoRa PHY transmitting parameters
    LORA_SF = 12;            % LoRa spreading factor
    LORA_BW = 125e3;        % LoRa bandwidth
    
    % Receiving device parameters
    RX_Sampl_Rate = 125e3*8;  % recerver's sampling rate 
    Dn_Samp_Factor = 1;       % down sampling factor
    
    % Decoding parameters
    Max_Peak_Num = 20;
    Max_Payload_Num = 20;
    
    
    switch(p_id)
        case 1,
            par = LORA_SF;
        case 2,
            par = LORA_BW;
            
        case 3,
            par = RX_Sampl_Rate;
            
        case 4,
            par = Dn_Samp_Factor;
        case 5,
            par = Max_Peak_Num;
        case 6,
            par = Max_Payload_Num;
        otherwise,
    end
end