
1) Functionalities of primary files 
main_src.m		Matlab scripts of main controller of CoLoRa decoder
param_configs.m		Parameter configuration table of the CoLoRa programs
input/collisions_k		PHY samples of collided LoRa packets (k-node collisions)

2) A running example
Operate step-by-step as follow:
a. open Matlab (version R2020a [or above])
b. set the working directory of Matlab to the dir of CoLoRa program
c. run main_src.m

After runing main_src.m, you can see the infomation of every detected chirp symbol at the terminal window of MATLAB, which includes each symbol's frequency, amplitude, and peak ratios. The demodulation result is also presented at the MATLAB terminal window, which is also writen out as a csv file under the 'output/' directory.

3) Default parameters 
The default CoLoRa program is configured for LoRa packets with Spreading Factor SF=12, Bandwith BW=125kHz, Sampling rate Fs=1e6 Samples per second. You can find and change the parameters in file "param_configs.m".

The input data file of LoRa signal samples (e.g., input/collisions_k) is loaded in the file "main_src.m" by the code "mdata = io_read_iq('input/collisions_2');". 


