










%% Get Frame with specific duration
clc

obj = Ammeter("COM3", 'nyan');

% obj.show_flags()

obj.connect();
relay_chV(obj, true);
obj.sending(1);
pause(0.1);
obj.relay_zerocap(true);
% pause(0.1);
% obj.relay_zerocap(false);

[ch_V, ch_I] =  Ammeter_get_data_frame(obj, 1000);



obj.sending(0);
obj.relay_zerocap(false);
relay_chV(obj, false);
obj.disconnect();

figure
hold on
plot(ch_V, '-r', 'linewidth', 0.8)
plot(ch_I, '-b', 'linewidth', 0.8)





%% get data in real-time

clc


% obj = Ammeter("COM3", [], 'bias');
obj = Ammeter("COM3", []);
obj.set_gain(1);


obj.connect();
relay_chV(obj, false);
% obj.sending(1);
% obj.relay_zerocap(true);
% obj.voltage_set(0);

obj.start_measuring();

fig_main = figure;
hold on
try
    
stream_ch1 = [];
stream_ch2 = [];

timer = tic;
while toc(timer) < 5

[part_ch_1, part_ch_2, isOk] = obj.read_data();
stream_ch1 = [stream_ch1 part_ch_1];
stream_ch2 = [stream_ch2 part_ch_2];

cla
plot(stream_ch1, '-r', 'linewidth', 0.8);
plot(stream_ch2, '-b', 'linewidth', 0.8);
% ylim([-0.01 0.01])
drawnow

end

catch error
    disp('--------error!--------')
    disp(error.identifier);
    disp(error.message);
    disp('----------------------')
end

% obj.relay_zerocap(false);
obj.sending(0);
relay_chV(obj, false);
obj.disconnect();




%%



clc


obj = Ammeter("COM3", 'pig');

% obj.show_analog;


obj.connect();

obj.voltage_set(0);
pause(1);

% obj.show_analog;

% obj.sending(true);
% pause(0.1);
% obj.sending(false);

% while 1
%     obj.get_handle_position();
%     pause(0.4)
% end

obj.disconnect();































