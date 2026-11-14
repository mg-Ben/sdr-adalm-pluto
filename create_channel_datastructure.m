function [resulting_dict] = create_channel_datastructure(carrier_frequency_channel1, fs, Ny, unique_channel_numbers, Lr)
    % Input parameters:
    % - carrier_frequency_channel1: central frequency of channel 1
    % - fs: Radio sampling rate (to compute carrier signal)
    % - Ny: Length of buffer (to compute carrier signal)
    % - unique_channel_numbers: a list with the distinct channel numbers
    % - Lr: (to compute receive band-pass channel selection filter)
    resulting_dict = dictionary();
    for i=1:length(unique_channel_numbers)
        channel_number = unique_channel_numbers(i);

        carrier_frequency_channel = carrier_frequency_channel1*channel_number;
        channel_carrier_signal = exp(1i*2*pi*(0:Ny-1)'*carrier_frequency_channel/fs);
        channel_reception_filter = fir1(Lr,(0.95*[-carrier_frequency_channel1, carrier_frequency_channel1]/2+carrier_frequency_channel)*2/fs);
        channel_datastructure = struct('carrier_frequency_channel', carrier_frequency_channel, 'channel_carrier_signal', channel_carrier_signal, 'channel_reception_filter', channel_reception_filter);
        resulting_dict(channel_number) = channel_datastructure;
    end
end