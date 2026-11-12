fsa = 48000;    % Audio sampling rate
M = 5;          % Oversampling for radio bandwidth
fs = M*fsa;     % Radio sampling rate
fc= 2.4e9;      % Carrier frequency
Na = 4000;      % Length of audio buffer
Ny = Na*M;      % Length of receive buffer

m=1;            % AM modulation index (0 to 1)

chan = app.chan;                      % base-band channel
fc1=fsa*chan;
c = exp(1i*2*pi*(0:Ny-1)'*fc1/fs);    % Channel carrier

f0 = fsa/50;
xtest_a = sin(2*pi*(0:Na-1)'*f0/fsa);     % Test signal to be transmitted at audio rate
xtest_b = sin(2*pi*(0:Ny-1)'*f0/fs);      % Test signal to be transmitted at base-band rate

% Receive band-pass channel selection filter
Lr=128;
hr=fir1(Lr,(0.95*[-fsa, fsa]/2+fc1)*2/fs);
zfr=zeros(Lr,1); % Filter memory

% Transmit interpolation low-pass filter
Lt=128;
ht=M*fir1(Lt,1/M);
zft=zeros(Lt,1); % Filter memory

% Open audio reader
adr=audioDeviceReader(fsa,'SamplesPerFrame',Na);

% Open audio writer
adw=audioDeviceWriter(fsa,'BufferSize',Na);

% Open transmitter and configure it. Release it at the end
% *** YOUR CODE ***

% Open receiver and configure it. Release it at the end
% *** YOUR CODE ***

disp('Radio on: Rx');

drawnow;
state = app.state;  % State of the radio. 0: OFF. 1: Rx. -1:Tx
state_0 = state;    % Preceding state 
chan_0 = chan;      % Preceding channel

%Override test signals:
while(state~=0)
    switch state
        case 1
            if state~=state_0; disp('Tx'); end
            
            xa = adr(); %xa is a Na length buffer
            % We work with the current buffer:
            xb = conv(upsample(xa, M), ht');
            xc = (m/2)*xb + (1-m/2);

            % On Rx side, we would downsample, truncate to Na and try to eliminate DC component:
            yc = xc;
            yb = yc-mean(yc);
            ya = downsample(yb, M);
            ya = ya(1:Na);

            adw(ya);
    end
    state_0 = state;
    drawnow;
    state = app.state;
    chan = app.chan;
    if chan~=chan_0
        disp(['Switched to channel ',num2str(chan)]);
        % *** YOUR CODE ***
        chan_0 = chan;
    end
end

release(adw);
release(adr);

% Release transmitter and receiver
% *** YOUR CODE ***


disp('Radio off');