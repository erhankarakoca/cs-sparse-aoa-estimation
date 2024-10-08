function [Enable_vec,Atten_vec,I_vec,Q_vec] = weight2reg(w_complex)
% This function convert BF configuration vectors to a register values
% for the vectors structure check Rpinoe/API/doc
% might need some revisions
% last update: 18.12.2023 by MYY
w_complex = w_complex(:);
Enable_vec = double(abs(w_complex)>0);
Atten_vec = abs(round(10*log10(abs(w_complex)),1));
Atten_vec(Atten_vec>15.5) = 15.5;
Atten_vec = round(Atten_vec*2);
I_vec = cos(angle(w_complex));
I_vec(I_vec >= 0) = quantiz(I_vec(I_vec >= 0), linspace(0,1,16))+16;
if sum(I_vec < 0) ~= 0
    I_vec(I_vec < 0) = quantiz(I_vec(I_vec < 0), linspace(-1,0,16));
end
Q_vec = sin(angle(w_complex));
Q_vec(Q_vec >= 0) = quantiz(Q_vec(Q_vec >= 0), linspace(0,1,16))+16;

if sum(Q_vec < 0)  >= 1
    Q_vec(Q_vec < 0) = quantiz(Q_vec(Q_vec < 0), linspace(-1,0,16));
end