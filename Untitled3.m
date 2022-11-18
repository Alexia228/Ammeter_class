

clc


obj = Ammeter("COM5", 'nyan');



% [ch1, ch2] = read_data(obj)

obj.connect();

obj.sending(1);
pause(1);

[ch_V, ch_I] = obj.read_data();


obj.sending(0);

[~, ~] = obj.read_data();

obj.disconnect();




figure
hold on
plot(ch_V, '-r', 'linewidth', 0.8)
plot(ch_I, '-b', 'linewidth', 0.8)


% clearvars obj



% clear


% serialportlist('all') == 'COM1'


%%


sum(["COM1" "COM3" "COM11" "COM12"] == 'COM1') == 1



%%
clc

Avilable_ports = ["COM1" "COM3" "COM11" "COM12"];
port_name = ['COM122'];

Text_ports_list = '';
for i = 1:numel(Avilable_ports)
   Text_ports_list = [Text_ports_list char(Avilable_ports(i)) newline];
end

msg = ['ERROR: No such com port name.' newline ...
    'List of avilable ports:' newline ...
    Text_ports_list ...
    'Provided name: ' port_name];

error(msg)



%%


obj = Ammeter("COM5", 'nyan');


obj.connect();
pause(0.2)


relay_chV(obj, true);
pause(1)

relay_chV(obj, false);
pause(1)

obj.disconnect();








%%
clc

obj = Ammeter("COM5", 'nyan');

% obj.show_flags()

obj.connect();
relay_chV(obj, true);
pause(0.5)
obj.sending(1);
pause(0.5)

[ch_V, ch_I] = get_data_frame(obj, 100);


obj.sending(0);
relay_chV(obj, false);
obj.disconnect();

figure
hold on
plot(ch_V, '-r', 'linewidth', 0.8)
plot(ch_I, '-b', 'linewidth', 0.8)



function [out_ch1, out_ch2] = get_data_frame(ammeter_obj, time_ms)
out_ch1 = [];
out_ch2 = [];

if ~isvalid(ammeter_obj)
    error('invalid ammeter handle');
end

Flags = ammeter_obj.show_flags();

if ~Flags.connected
    warning([ammeter_obj.get_name() ' disconnected']);
elseif ~Flags.sending
    warning([ammeter_obj.get_name() ' is not sending anything']);
else
    
    while numel(out_ch1) < time_ms
        [part_ch_1, part_ch_2] = ammeter_obj.read_data();
        out_ch1 = [out_ch1 part_ch_1];
        out_ch2 = [out_ch2 part_ch_2];
    end
    
end



end






























