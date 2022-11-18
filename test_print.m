


tic

Bytes_01 = Data_all(1:4:end);
Bytes_02 = Data_all(2:4:end);
Bytes_03 = Data_all(3:4:end);
Bytes_04 = Data_all(4:4:end);

Bytes_01(Bytes_01>=128) = Bytes_01(Bytes_01>=128) - 256;
Bytes_03(Bytes_03>=128) = Bytes_03(Bytes_03>=128) - 256;

Value_X = (Bytes_01*256 + Bytes_02)*10/2^15;
Value_Y = (Bytes_03*256 + Bytes_04)*10/2^15;

toc




hold on
plot(Value_X)
plot(Value_Y)




%%




% clc
tic

Bytes_01 = Data_all(1:4:end);
Bytes_02 = Data_all(2:4:end);
Bytes_03 = Data_all(3:4:end);
Bytes_04 = Data_all(4:4:end);

for i = 1:numel(Bytes_02)

Value_X(i) = double(typecast(uint8([Bytes_02(i), Bytes_01(i)]), 'int16'))*10/2^15;
Value_Y(i) = double(typecast(uint8([Bytes_04(i), Bytes_03(i)]), 'int16'))*10/2^15;

end
toc


hold on
plot(Value_X)
plot(Value_Y)









