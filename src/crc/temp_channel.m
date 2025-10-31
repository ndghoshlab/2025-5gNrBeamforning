clear; clc;

channel = nrTDLChannel;

channel.DelayProfile = "TDL-C";
channel.NumTransmitAntennas = 1;
channel.NumReceiveAntennas = 1;
channel.MaximumDopplerShift = 0;
channel.DelaySpread = 300e-9;
chInfo = info(channel);

maxChDelay = chInfo.MaximumChannelDelay;
Ts = 1/channel.SampleRate;
maxDelay_seconds = maxChDelay * Ts

maxExcessDelay_seconds = max(chInfo.PathDelays)