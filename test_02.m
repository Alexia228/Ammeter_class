

clc
figure


Obj = serialport("COM5", 230400);

CMD_get_handle = uint8([1 0 0 0 0]);
CMD_set_send_flag = uint8([4 0 1 0 0]);
CMD_clear_send_flag = uint8([4 0 0 0 0]);

CMD_set_chV_relay = uint8([10 0 1 0 0]);
CMD_clear_chV_relay = uint8([10 0 0 0 0]);

% write(Obj, CMD_get_handle, "uint8");

% write(Obj, CMD_set_chV_relay, "uint8");
% pause(0.5)
write(Obj, CMD_set_send_flag, "uint8");
% pause(0.1)

Data_all = [];

Bias_X = -0.0021;
Bias_Y = -3.8772e-04;
for i = 1:100
    [Data, error] = get_bytes(Obj);
    Data_all = [Data_all Data];
    
    [Value_X, Value_Y] = unpack_raw_bytes(Data_all);
    Value_X = Value_X - Bias_X;
    Value_Y = Value_Y - Bias_Y;
    
    cla
    hold on
    plot(Value_X, '-', 'linewidth', 0.8)
    plot(Value_Y, '-', 'linewidth', 0.8)
    drawnow
end

write(Obj, CMD_clear_send_flag, "uint8");
[Data, error] = get_bytes(Obj);
Data_all = [Data_all Data];

delete(Obj)
% clearvars Obj



% [Value_X, Value_Y] = unpack_raw_bytes(Data_all);
% 
% cla
% hold on
% plot(Value_X, '.')
% plot(Value_Y, '.')
% drawnow



%%

function [Data, timeout_flag] = get_bytes(Obj)
Time_start = tic;

timeout_flag = 0;
stop = 0;

while ~stop
    Bytes_count = Obj.NumBytesAvailable;
    Bytes_count = floor(Bytes_count/4)*4;
    
    if Bytes_count
        Data = read(Obj, Bytes_count, "uint8");
        stop = 1;
%         toc(Time_start)
    end
    
    Time_now = toc(Time_start);
    if Time_now > 1
        stop = 1;
        timeout_flag = 1;
        Data = 0;
    end
    
end

end




% binStr = dec2bin(CMD_set_out_flag)






