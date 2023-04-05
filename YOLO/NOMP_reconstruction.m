% Constants for the YOLO algorithm
c = physconst('lightspeed'); % Speed of light in meters per second
fft_points = 2048;
df = 75000; % Hertz
BW = 90 * 10^6; % Hertz
fc = 3.5 * 10^9; % Hertz
pt = -20; % Transmitted Power
lambda = c / fc; % Carrier Wavelength
d = lambda / 2; % Distance between antennas

% Simple ULA transmission
v = 15.0; % Velocity of the user equipment (km/h)
fd = (v*1000/3600)/c*fc; % Maximum Doppler Frequency of the user equipment (Hertz)
SR = 15.36e6;
T = SR * 1e-3;

cdl = nrCDLChannel;
cdl.CarrierFrequency = fc;
cdl.MaximumDopplerShift = 0;
cdl.SampleRate = SR;
cdl.TransmitAntennaArray.Size = [1 1 1 1 1];
cdl.ReceiveAntennaArray.Size = [1 8 1 1 1];
cdl.DelaySpread = 0;
cdl.DelayProfile = 'CDL-D';
cdlinfo = info(cdl);
Nt = cdlinfo.NumTransmitAntennas;
Nr = cdlinfo.NumReceiveAntennas;

txWaveform = ones(52,Nt);

chInfo = info(cdl);

[rxWaveform, pathGains] = cdl(txWaveform);
[rxWaveform, pathGains] = cdl(txWaveform);

% Channel Reconstruction
N = 52; % Sub-carrier count
M = Nr; % Antenna count

% Get the set of path components from the channel model.
L = length(chInfo.PathDelays);
tau = chInfo.PathDelays;
theta = wrapTo180(chInfo.AnglesAoA - 180 .* ones(size(chInfo.AnglesAoA)));
gul = squeeze(pathGains(1,:,1,:));

% Reconstruct the channel using the method from NOMP paper

% Initialize h temporarily to the exact size obtained from kron
h = zeros(N, M);
for i = 1 : length(theta)
     h = h + gul(i,:) .* kron(p(tau(i), N, df), a(theta(i), M, d, lambda)');
end

disp("RMSE: ")
mean(mean(abs((h-rxWaveform).^2)))^1/2

% a() returns the steering vector for a given angle by inputting the angle
% of the received path, the number of antennas, the distance between the
% antennas, and the wavelength of the carrier.

function out = a(theta, M, d, lambda)
    m = -M/2:(M/2-1);
    out = exp(1j*2*pi*m*d*lambda*sin(theta))';
end

% p() returns the steering vector for a given angle by inputting the
% received path, the number of antennas, and the subcarrier spacing.

function out = p(tau, N, df)
    n = -N/2:(N/2-1);
    out = exp(1j*2*pi*n*df*tau)';
end
