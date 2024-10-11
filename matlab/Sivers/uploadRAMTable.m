function [evkObject, W_quantized] = uploadRAMTable(evkObject,array,weights)
% This function uploads a BF weights table to the evk.
% INPUTS:
% evkObject: must be created using evk.m function
% array: can be a MATLAB phased array object, or a matrix containing the
%           positions of the elements (to perform weight mapping).
% weights: a 16x1 or 16xN matrix of complex BF weights, N is the number of
%           different beams (weight vectors).
% W_quantized: The real applied weights to the EVK
% The function currently applies the same weights to vertical and
% horizontal polarizations, it will be extended later %%%
% Last Update: 11.10.2024 by MYY

cd '..\..\python\Sivers\';
if ~exist("evkObject","var") || isempty(evkObject)
    disp("Error, provide evkObject")
    evkObject = [];
    return;
end
if ~exist("array","var") || isempty(array)
    disp("Error, provide array")
    evkObject = [];
    return;
end
if ~exist("weights","var") || isempty(weights)
    disp("Error, provide weight vector(s)")
    evkObject = [];
    return;
end
% if class(array) == 'phased.URA'
%     array = array.getElementPosition;
if ~(any(size(array) == 16) && ...
        (any(size(array) == 2) || any(size(array) == 3)))
    disp("Error, check the array size")
    evkObject = [];
    return;
end
if size(array,1) == 16
    array = array';
end
x = sort(unique(array(1,:)));
y = sort(unique(array(2,:)));
if (size(array,1) == 3 && length(unique(array(3,:))) > 1) ...
        || length(x) ~= 4 || length(y) ~= 4
    disp("Error, the array element positions must be in x and y")
    evkObject = [];
    return;
end

if ~(any(size(weights) == 16))
    disp("Error, weight should be a vector of 16 elements or a" + ...
        " matrix of 16-element vectors")
    evkObject = [];
    return;
end
if size(weights,1) ~= 16
    weights = weights.';
end


N = size(weights,2);
W_quantized = zeros(size(weights));
for i = 1:N
    row = py.dict();
    [Enable_vec,Atten_vec,I_vec,Q_vec] = weight2reg(weights(:,i));
    quanitzed_mag = 10.^(-Atten_vec/20);
    quantized_I = zeros(size(I_vec));
    quantized_I(I_vec > 15) = ((I_vec(I_vec > 15) - 1) ./15)-1;
    quantized_I(I_vec <= 15) = (I_vec(I_vec <= 15) ./15)-1;
    quantized_Q = zeros(size(Q_vec));
    quantized_Q(Q_vec > 15) = ((Q_vec(Q_vec > 15) - 1) ./15)-1;
    quantized_Q(Q_vec <= 15) = (Q_vec(Q_vec <= 15) ./15)-1;
    W_quantized(:,i) = quanitzed_mag .* (quantized_I + 1j * quantized_Q);

    % direkt registerlara birşey yazılacaksa
    w = int16(mapping2Sivers(array,x,y,[Enable_vec,Atten_vec,I_vec,Q_vec]));
    for k = 0:15
        row{"bf_enable_v" + num2str(15-k)} = w(k+1,1);
        row{"bf_vpa_att_v" + num2str(15-k)} = w(k+1,2);
        row{"bf_vpa_q_v" + num2str(15-k)} = w(k+1,4);
        row{"bf_vpa_i_v" + num2str(15-k)} = w(k+1,3);
        row{"bf_enable_h" + num2str(15-k)} = w(k+17,1);
        row{"bf_vpa_att_h" + num2str(15-k)} = w(k+17,2);
        row{"bf_vpa_q_h" + num2str(15-k)} = w(k+17,4);
        row{"bf_vpa_i_h" + num2str(15-k)} = w(k+17,3);
    end
    evkObject = py.hisar_scripts.write_RAM_row(evkObject,row,'ram',int32(i-1));

end
cd '..\..\matlab\Sivers\';
end