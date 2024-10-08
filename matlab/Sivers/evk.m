function evkObject = evk(serialNumber,frequency,TxRx)
% This function is a replica of the initialization python codes for EVK in
% Rapinoe. The aim is to obtain the evkObject in MATLAB to keep the
% connection to the deivce and update the BF table in the ram of the chip
% directly from here. 
% INPUTS:
% serialNumber (string or char array): The serial number of EVK (Mandatory)
%               example: 'T582300517'
% frequency: operation frequency (24-31 GHz), optional, default is 27 GHz.
% TxRx: mode selection, if you provide this argument the device will
%               operate in Tx mode, if not provided the device will
%               operate in Rx mode.
% Last Update: 26.01.2024 by MYY

if ~exist("serialNumber","var")
    disp("Error, enter serial number")
    evkObject = [];
    return;
end
if ~exist("frequency","var") || isempty(frequency)
    frequency = 27e9;
end
if exist("TxRx","var") && ~isempty(TxRx)
    evkObject = py.hisar_scripts.create_evk(serialNumber,frequency,TxRx);
else
    evkObject = py.hisar_scripts.create_evk(serialNumber,frequency);
end
end