

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
clc

Data_stream = [];

Data = [1 2 3; 7 8 9]
Data_stream = [Data_stream Data]

Data = [1 2 3; 7 8 9]
Data_stream = [Data_stream Data]













