% Constants
v = 15.0;                    % UE velocity in km/h
fc = 4e9;                    % carrier frequency in Hz
c = physconst('lightspeed'); % speed of light in m/s
fd = (v*1000/3600)/c*fc;     % UE max Doppler frequency in Hz
subcarriers = 52;
antennas = 64;
nPilots = 50;

range = 25:100;
MSEs = zeros(size(range));

for i = 1:numel(range)
    k = range(i);
    nPilots = k;
    cdl = nrCDLChannel;
    cdl.DelayProfile = 'CDL-A';
    cdl.DelaySpread = 10e-9;
    cdl.CarrierFrequency = fc;
    cdl.MaximumDopplerShift = fd;

    cdl.TransmitAntennaArray.Size = [1 antennas 1 1 1];
    cdl.ReceiveAntennaArray.Size = [1 1 1 1 1];

    SR = 15.36e6;
    T = SR * 1e-3;
    cdl.SampleRate = SR;
    cdlinfo = info(cdl);
    Nt = cdlinfo.NumTransmitAntennas;
    Nr = cdlinfo.NumReceiveAntennas;

    % Generate waveform with pilots
    txWaveform = ones(nPilots,Nt);

    % Calculate H
    A = (1/sqrt(Nt)) * exp(-1j*2*pi/Nt .* ((0:Nt-1)' * (0:Nt-1)));
    txWaveformA = txWaveform * A';

    % Send Signal through the channel
    [rxWaveform, pathGains, sampleTimes] = cdl(txWaveformA);

    % Lasso in attempt to find H
    % Complex LASSO code taken from Mark Schmidt
    % Link: https://www.cs.ubc.ca/~schmidtm/Software/code.html

    % Functions for switching between the two complex representations
    makeReal = @(z)[real(z);imag(z)];
    makeComplex = @(zRealImag)zRealImag(1:Nt) + 1i*zRealImag(Nt+1:end);

    % Initial guess of parameters
    zRealImag = makeReal(zeros(Nt,1));

    % Set up Objective Function
    XRealImag = [real(txWaveformA) -imag(txWaveformA);imag(txWaveformA) real(txWaveformA)];
    yRealImag = [real(rxWaveform);imag(rxWaveform)];
    funObj = @(zRealImag)SquaredError(zRealImag,XRealImag,yRealImag);

    % Set up Complex L1-Ball Projection
    tau = 1;
    funProj = @(zRealImag)complexProject(zRealImag,tau);

    % Solve with PQN
    fprintf('\nComputing optimal Lasso parameters.\n');
    zRealImag = minConf_PQN(funObj,zRealImag,funProj);
    h_1 = makeComplex(zRealImag);

    % Another method to complex LASSO regression
    % https://stats.stackexchange.com/questions/469653/implementing-complex-lasso-in-matlab
    [h, FitInfo] = lasso(XRealImag,yRealImag);
    hl = h(:,50);
    h_2 = makeComplex(hl);

    % Calculate MSE
    estiY = txWaveformA * h_1;
    MSEs(k - min(range) + 1) = abs(mean((rxWaveform - estiY).^2));
end

plot(range,MSEs)
xlabel('Number of Pilots')
ylabel('NMSE')
title('Sparse Channel Estimation using Joint Burst LASSO')
