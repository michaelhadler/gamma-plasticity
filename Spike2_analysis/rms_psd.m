%Compute RMS-based PSD

%Computes the RMS-averaged power spectral density of an input signal
%"trace" given
    %fs: sampling frequency in Hz
    %SR: frequency resolution in Hz
% A hamming window is used as standard


function [psd,f] = rms_psd(trace,fs,SR)

%spectral resolution and FFT size
nfft = 2^nextpow2(fs/SR) ;
bw = fs/nfft ;

%Coefficients of Hamming window already taken into account
[Pyy, f] = pwelch(trace, hamming(nfft), nfft/2, nfft, fs);
%Complete RMS averaging by accounting for bin frequency.
psd = Pyy * bw ;