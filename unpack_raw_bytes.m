function [Value_X, Value_Y] = unpack_raw_bytes(Data_all)

Bytes_01 = Data_all(1:4:end);
Bytes_02 = Data_all(2:4:end);
Bytes_03 = Data_all(3:4:end);
Bytes_04 = Data_all(4:4:end);

Bytes_01(Bytes_01>=128) = Bytes_01(Bytes_01>=128) - 256;
Bytes_03(Bytes_03>=128) = Bytes_03(Bytes_03>=128) - 256;

Value_X = (Bytes_01*256 + Bytes_02)*10/2^15;
Value_Y = (Bytes_03*256 + Bytes_04)*10/2^15;

end
