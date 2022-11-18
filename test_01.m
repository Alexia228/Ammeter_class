



Obj = serialport("COM5", 230400);


clc

CMD_01 = uint8([1 0 0 0 0]);

write(Obj, CMD_01, "uint8");
pause(0.1)

Bytes_count = Obj.NumBytesAvailable

if Bytes_count
   In_data = read(Obj, Bytes_count-1, "uint8")
end
In_data = read(Obj, 1, "uint8")


clearvars Obj





















