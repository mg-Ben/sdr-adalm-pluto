close all; clc;
% -------------------------------------------------------------------------
% -                     INPUT GLOBAL VARIABLES                            -
% -------------------------------------------------------------------------
plot_signals = 0; % Decides whether we want to plot signals or not
test_mode = 1;  % Decides whether send signals over the air or not (test mode)
fsa = 48000;    % Audio sampling rate
M = 5;          % Oversampling for radio bandwidth
fc= 2.4e9;      % Carrier frequency
Na = 4000;      % Length of audio buffer
m=1;            % AM modulation index (0 to 1)
Lt=128;         % Transmit interpolation low-pass filter
Lr=128;         % Receive band-pass selection filter length
unique_channels = [1, 2]; % Define all the available distinct channel numbers that will be used
% Transmission over the air configuration:
tx=sdrtx('Pluto');
tx.CenterFrequency = fc;
tx.BasebandSampleRate = fs;
tx.Gain = -10;
% Reception from the air configuration:
rx=sdrrx('Pluto');
rx.CenterFrequency = fc;
rx.BasebandSampleRate = fs;
rx.GainSource = 'Manual';       % Disable AGC for manual setting of gain
rx.Gain = 0;

% Channel mapping: we decide which one is TX channel and which RX channel:
% For MASTER1 mode:
master1_dict = dictionary(["RX_channel", "TX_channel"], [2, 1]);
% For SLAVE1 mode:
slave1_dict = dictionary(["RX_channel", "TX_channel"], [1, 2]);
% For MASTER2 mode:
master2_dict = dictionary(["RX_channel", "TX_channel"], [-2, -1]);
% For SLAVE2 mode:
slave2_dict = dictionary(["RX_channel", "TX_channel"], [-1, -2]);

% Final settings datastructure: we define a final datastructure where we
% can switch among different operation modes:
MasterSlave_settings = dictionary(["MASTER1", "SLAVE1", "MASTER2", "SLAVE2"], {master1_dict, slave1_dict, master2_dict, slave2_dict});



% -------------------------------------------------------------------------
% -                      SYSTEM INITIALIZATION                            -
% -------------------------------------------------------------------------
% If false, the transmission and reception channels are different and we transmit and receive over the air
fs = M*fsa;     % Radio sampling rate
Ny = Na*M;      % Length of receive buffer

% Create a struct object for each unique channel. Each key corresponds to the channel number:
% Example:
% {
%   "1": struct(
%       "carrier_frequency_channel": 48000,
%       "channel_carrier_signal": [...], 
%       "channel_reception_filter": [...]
%   )
%   "2": struct(
%       "carrier_frequency_channel": 96000,
%       "channel_carrier_signal": [...], 
%       "channel_reception_filter": [...]
%   )
% }
channel_settings = create_channel_datastructure(fsa, fs, Ny, unique_channels, Lr);

state = app.state;
chan = app.chan;
% Convert the numeric state and channel to a string that decides the key to access:
state_string = format_state(state, chan); %E.g.: "MASTER1", "MASTER2", "SLAVE1", "SLAVE2"
state_0 = state;    % Preceding state 
chan_0 = chan;      % Preceding channel

% Default configuration:
tx_channel = MasterSlave_settings{state_string}("TX_channel");
rx_channel = MasterSlave_settings{state_string}("RX_channel");
% TX - Carrier signal c:
c = channel_settings(tx_channel).channel_carrier_signal;
% TX - Transmit interpolation low-pass filter ht:
ht = M*fir1(Lt,1/M);
zft = zeros(Lt,1);
% RX - Reception channel selection filter hr:
hr = channel_settings(rx_channel).channel_reception_filter;
zfr = zeros(Lr,1);

% Open audio reader
adr=audioDeviceReader(fsa,'SamplesPerFrame',Na);
% Open audio writer
adw=audioDeviceWriter(fsa,'BufferSize',Na);

% Open transmitter and configure it. Release it at the end
% *** YOUR CODE *** TO-DO
% Open receiver and configure it. Release it at the end
% *** YOUR CODE *** TO-DO



% -------------------------------------------------------------------------
% -                      OTHERS - TEST SIGNALS                            -
% -------------------------------------------------------------------------
f0 = fsa/50;
xtest_a = sin(2*pi*(0:Na-1)'*f0/fsa);     % Test signal to be transmitted at audio rate
xtest_b = sin(2*pi*(0:Ny-1)'*f0/fs);      % Test signal to be transmitted at base-band rate



% -------------------------------------------------------------------------
% -                               MAIN                                    -
% -------------------------------------------------------------------------
disp('Radio on: '+state_string+' mode');
drawnow;
if plot_signals == 1; figure; end
while(state~=0)
    if state~=state_0 || chan~=chan_0
        state_string = format_state(state, chan);
        disp('Switched to '+state_string+' mode');
        tx_channel = MasterSlave_settings{state_string}("TX_channel");
        rx_channel = MasterSlave_settings{state_string}("RX_channel");
        % TX - Carrier signal c:
        c = channel_settings(tx_channel).channel_carrier_signal;
        % RX - Selection filter hr:
        hr = channel_settings(rx_channel).channel_reception_filter;
        zfr = zeros(Lr,1);
    end

    % TX Operation:
    xa = adr(); if plot_signals == 1; subplot(4, 1, 1); plot([0:Na-1]*1/fsa, xa); xlim tight; xlabel('time [s]'); end
    [xb, zft] = filter(ht, 1, upsample(xa, M), zft);
    xc = (m/2)*xb + (1-m/2);
    x = xc.*c; if plot_signals == 1; subplot(4, 1, 2); domain = [0:Ny-1]*1/fs; stem(domain(200:300), real(x(200:300))); xlim tight; xlabel('time [s]'); end

    % ---------------
    if test_mode == 1
        % We receive the exact transmitted signal:
        y1 = x;
    else
        % Transmit signal over the air
        tx(complex(x));
        % Receive signal
        [y1,valid,overflow]=rx();
        if overflow
            disp('Buffer overflow')
            y1 = zeros(1, Ny);
        end
    end
    % ---------------

    % RX Operation:
    if plot_signals == 1; subplot(4, 1, 3); domain = [0:Ny-1]*1/fs; stem(domain(200:300), real(y1(200:300))); xlim tight; xlabel('time [s]'); end
    [y, zfr] = filter(hr, 1, y1, zfr);

    yc = abs(y);
    yb = yc-mean(yc);
    ya = downsample(yb, M); if plot_signals == 1; subplot(4, 1, 4); plot([0:Na-1]*1/fsa, ya); xlim tight; xlabel('time [s]'); end

    adw(ya);
    
    % Final loop updates:
    state_0 = state;
    drawnow;
    state = app.state;
    chan = app.chan;
end

release(adw);
release(adr);

% Release transmitter and receiver
release(tx);
release(rx);

disp('Radio off');