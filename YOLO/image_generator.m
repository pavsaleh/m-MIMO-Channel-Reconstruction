clear
file_out = "pathData.csv";

% Parameters for the YOLO paper
c = physconst('lightspeed'); % Speed of light in m/s
fft_points = 2048;
df = 75000; % Hz
BW = 90 * 10^6; % Hz
fc = 3.5 * 10^9; % Hz
pt = -20; % Power Transmitted
lambda = c / fc; % Carrier Wavelength
d = lambda / 2; % Distance between antennas
N = 32; % Number of Sub-carriers
M = 32; % Number of Antennas

% Simple ULA transmission
v = 15.0; % UE velocity (km/h)
fd = (v*1000/3600)/c*fc; % UE Max Doppler Frequency (Hz)
MAX_PATH_COUNT = 10;
CHANNEL_COUNT = 500;
SR = 15.36e6;
T = SR * 1e-3;
Nt = 1;
Nr = M;

% Generating CDL profile
cdl_list = randCdlProfile(CHANNEL_COUNT, MAX_PATH_COUNT, M, fc, fd, SR);

% Generating strings
AoA_str = "";
AoZ_str = "";
T_str = "";
g_str = "";
for i = 1:MAX_PATH_COUNT 
    AoA_str = strcat(AoA_str, "AoA_"+i, ",");
    AoZ_str = strcat(AoZ_str, "AoZ_"+i, ",");
    T_str   = strcat(T_str, "T_"+i, ",");
    g_str   = strcat(g_str, "g_"+i, ",");
end
x = [strcat("Index,", AoA_str, AoZ_str, T_str, g_str, "NumPaths,MaxPixel")];

% Generating YOLO images
for i = 1:CHANNEL_COUNT
    cdl = cdl_list{i};
    c = nrCarrierConfig;
    c.NSizeGrid = N;
    c.SubcarrierSpacing = 15;
    c.NSlot = 1;
    c.NFrame = 0;
    tx_one = ones(N*12, Nt);
    tx_zero = zeros(N, Nt);
    tx_waveform = nrOFDMModulate(c, tx_one);

    ch_info = info(cdl);
    [rx_waveform, path_gains] = cdl(tx_waveform);
    [rx_waveform, path_gains] = cdl(tx_waveform);
    noise = db2mag(-80) .* complex(randn(size(rx_waveform)), randn(size(rx_waveform)));
    rx = nrOFDMDemodulate(c, rx_waveform);

    alpha = 12;
    beta = 1;
    delta = 2^10;
    Y = squeeze(rx).';
    U_theta = dftmtx(alpha * M);
    U_theta = U_theta(1:M, :);
    U_T = dftmtx(beta * N*12);
    U_T = U_T(1:N*12, :);
    Y_bar = U_theta.' * Y * U_T;
    
    [max_Y_bar,y_coord] = max(abs(Y_bar));
    [max_Y_bar,x_coord] = max(max_Y_bar);
    Y_tilda = (delta / max_Y_bar) .* abs(Y_bar);

    % Save output image to disk
    foldername = 'ChannelImages';
    filename = fullfile(foldername, sprintf('%d.png', i));
    imwrite(uint8(Y_tilda), filename);
    
    % Pad and format channel information
    delay_pad = padarray(ch_info.PathDelays, [0,MAX_PATH_COUNT-size(ch_info.PathDelays, 2)],0,"post");
    AoA_pad   = padarray(ch_info.AnglesAoA, [0,MAX_PATH_COUNT-size(ch_info.AnglesAoA, 2)],0,"post");
    ZoA_pad   = padarray(ch_info.AnglesZoA, [0,MAX_PATH_COUNT-size(ch_info.AnglesZoA, 2)],0,"post");
    gain_pad  = padarray(ch_info.AveragePathGains, [0,MAX_PATH_COUNT-size(ch_info.AveragePathGains, 2)],-1000,"post");
    x = [x strcat(sprintf('%d,', i), sprintf('%f,' , AoA_pad), sprintf('%f,' , ZoA_pad), sprintf('%f,' , delay_pad.*1000), sprintf('%f,' , gain_pad), sprintf('%d, %d %d',  size(ch_info.AnglesZoA, 2), x_coord, y_coord(x_coord)))];
end

% Write output file to disk
fid = fopen(file_out, 'w');
for j = 1 : length(x)
    fprintf(fid, x(j) + "\n");
end
fclose(fid);

% a() function definition
function out = a(theta, M, d, lambda)
    m = -M/2:(M/2-1);
    out = exp(1j*2*pi*m*d*lambda*sin(theta))'
end

% p() function definition
function out = p(tau, N, df)
    n = -N/2:(N/2-1);
    out = exp(1j*2*pi*n*df*tau)'
end

% randCdlProfile() function definition
function cdl = randCdlProfile(n, LMax, M, fc, fd, SR)
    cdl = cell(1,n);
    for k = 1:n
        L = 5; % Set path count to 5
        cdl{k} = nrCDLChannel;
        cdl{k}.CarrierFrequency = fc;
        cdl{k}.MaximumDopplerShift = fd;
        cdl{k}.SampleRate = SR;
        cdl{k}.TransmitAntennaArray.Size = [1 1 1 1 1];
        cdl{k}.ReceiveAntennaArray.Size = [1 M 1 1 1];
        cdl{k}.DelayProfile = 'custom';
        cdl{k}.PathDelays = rand(1,L) .* 10^-4;
        cdl{k}.AveragePathGains = (rand(1,L)-0.5) * 30; % [-15, 15]
        cdl{k}.AnglesAoA = (rand(1,L)-0.5)*360;
        cdl{k}.AnglesZoA = (rand(1,L)-0.5)*360;
        cdl{k}.AnglesAoD = (rand(1,L)-0.5)*360; 
        cdl{k}.AnglesZoD = (rand(1,L)-0.5)*360; 
        cdl{k}.HasLOSCluster = false;
    end
end
