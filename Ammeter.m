
% Update code in box CPU
% if (Analog_data_1 == 0x8000){
%   Analog_data_1 = 0x8001;
% }
% if (Analog_data_2 == 0x8000){
%   Analog_data_2 = 0x8001;
% }
%

% Add README.md

% TODO:
%  1) Transform values
%  2) Add all CMDs
%  3) ADD double to binary converter
%  4) add function to send cmd: function(CMD_n, arg_high, arg_low)
%  5) Data2File export
%  6) add flush buffer on sending(false)
%  7) after TODO(6) -> remove read 'force'
%  8) chech default Period and Waveform in Flags.Analog
%  9) update all warning('CMD ignored')
% 10) DO set_voltage with gain and limits check
% 11) create output voltage limits
% 12) get_name UNUSED
% 13) Find real values of RC
% 14) Create FIXME parser
% 15) Create a new waveform

%CMD:
%  1) get handle pos      - DONE           % [1 0 0 0 0]
%  2) ---                                  % [2 0 0 0 0]
%  3) set zero relay      - DONE           % [3 0 0 0 0]
%  4) set sending flag    - DONE           % [4 0 0 0 0]
%  5) Set amp and period  - ----UNDONE     % [5 0 0 0 0]
%  6) Start measuring     - DONE           % [6 0 0 0 0]
%  7) Set Output_flag     - ----UNDONE     % [7 0 0 0 0]
%  8) Set DAC value       - DONE           % [8 0 0 0 0]
%  9) RESET               - DONE           % [9 0 0 0 0]
% 10) set V_ch relay      - DONE           %[10 0 0 0 0]
% 11) set_wave_form_gen   - ----UNDONE     %[11 0 0 0 0]

% To find all FIXME, TODO, NOTE use:
% dofixrpt('Ammeter.m','file') -> find notes in file
% dofixrpt(dir) -> find notes in all files in directory 'dir'

classdef Ammeter < handle
    %--------------------------------PUBLIC--------------------------------
    methods (Access = public)
        function obj = Ammeter(port_name, varargin) % Конструктор
            narginchk(1, 3);
            if nargin > 1 && ~isempty(varargin{1})
                name_in = varargin{1};            % Имя амперметра
            else
                name_in = 'Yoyo';                 % Имя по дефолту
            end
            close_all_ammeters();                 % Закрывает всё, что было до этого
            obj.name = char(name_in);
            obj.COM_port_str = char(port_name);
            port_name_check(obj.COM_port_str);
            disp(['"' obj.name '" Ammeter created at port: ' obj.COM_port_str]);
            if nargin > 2 && varargin{2} == "bias"
                disp(['Input bias correction in "' obj.name '"']); % Коррекция смещения щупов, никуда не подкулючённых
                obj.bias_correction(); %Получения значениц коррекции на ch1 и ch2
            end
        end
        
        function delete(obj) % Пока просто переименование
            close(obj);
        end
        
        function connect(obj, varargin) % Подключение
            narginchk(1, 2) % ОБЩЕЕ число аргументов
            if ~obj.Flags.connected
                obj.Serial_obj = serialport(obj.COM_port_str, 230400); % Подключение к порту в виде переменной obj.Serial_obj
                obj.Flags.connected = true;
                if nargin == 2 && varargin{1} == "reset"
                    obj.RESET(); % Перезапуск амперметра
                elseif nargin == 2 && varargin{1} ~= "reset" % Либо перезапускаешь, либо не передаёшь количество аргументов больше одного 
                    warning('wrong value of 2nd argument in connection()')
                end
                get_handle_position(obj);
                disp(['"' obj.name '" connected at port: ' obj.COM_port_str])
            else
                warning(['"' obj.name '" already connected at port: ' obj.COM_port_str]);
            end
        end
        
        function disconnect(obj)
            if obj.Flags.connected
                obj.relay_zerocap(false);
                obj.voltage_set(0);
                obj.sending(false);
                obj.relay_chV(false)
                delete(obj.Serial_obj);
                obj.Flags.connected = false;
                disp(['Disconnecting "' obj.name '" at port: ' obj.COM_port_str])
            else
                warning(['Nothing to disconnect at ' obj.name]);
            end
        end
        
        function [V_ch1, V_ch2, isOk] = read_data(obj, varargin) %Чтение данных с амперметра
            V_ch1 = [];
            V_ch2 = [];
            isOk = 0;
            Force = nargin == 2 && varargin{1} == "force";
            if ~obj.Flags.connected
                warning([obj.name ' disconnected'])
                isOk = -1;
            elseif ~obj.Flags.sending && ~Force
                warning([obj.name ' is not sending anything'])
                isOk = -2;
            else
                [Temp_data, timeout_flag] = get_bytes(obj.Serial_obj);
                if timeout_flag
                    warning('data recive timeout')
                    isOk = -3;
                end
                [V_ch1, V_ch2, CMD] = unpack_raw_bytes(Temp_data);
                V_ch1 = V_ch1 - obj.Analog.bias.ch1;
                V_ch2 = V_ch2 - obj.Analog.bias.ch2;
                if CMD.flag
                    if CMD.high == 2 && CMD.low == 0
                        disp('Measuring stopped')
                        obj.Flags.sending = false;
                    end
                end
            end
        end
        
        function bias_correction(obj)
            [ch1_mean, ch2_mean] = Ammeter_bias_measure(obj);
            obj.Analog.bias.ch1 = obj.Analog.bias.ch1 + ch1_mean;
            obj.Analog.bias.ch2 = obj.Analog.bias.ch2 + ch2_mean;
        end
        
        %-------------------------------CMD---------------------------------
        function sending(obj, flag)
            if obj.Flags.connected
                if ~obj.Flags.sending
                    get_handle_position(obj);
                end
                flag = logical(flag);
                obj.send_cmd(uint8([4 0 flag 0 0]));
                obj.Flags.sending = flag;
            else
                warning(['CMD(sending == ' num2str(flag) ') ignored'])
            end
        end
        
        function relay_chV(obj, flag)
            if obj.Flags.connected
                flag = logical(flag);
                obj.Flags.relay_chV = flag;
                obj.send_cmd(uint8([10 0 flag 0 0]));
            else
                warning('CMD ignored')
            end
        end
        
        function relay_zerocap(obj, flag)
            if obj.Flags.connected
                flag = logical(flag);
                obj.Flags.relay_zerocap = flag;
                obj.send_cmd(uint8([3 0 flag 0 0]));
            else
                warning('CMD ignored')
            end
        end
        
        function voltage_set(obj, voltage)
            if obj.Flags.connected
                [byte_high, byte_low, voltage] = voltage2bitcode(voltage);
                obj.Analog.voltage_out = voltage;
                obj.send_cmd(uint8([8 byte_high byte_low 0 0]));
            else
                warning('CMD ignored')
            end
        end
        
        function start_measuring(obj)
            if obj.Flags.connected
                obj.send_cmd(uint8([6 0 0 0 0]));
                obj.Flags.sending = true;
            else
                warning('CMD ignored')
            end
        end
        
        function set_amp_and_period(obj, amp, period)
        end
        
        % Получение текущего положения ручки, определяемого R и C(
        % сопротивление и ёмкость)
        function [R, C] = get_handle_position(obj) 
            R = -1;
            C = -1;
            if ~obj.Flags.connected
                warning('Could not get handle position: ammeter disconnected')
            elseif ~obj.Flags.sending
                serial_flush(obj.Serial_obj); %Очисикка буфера
                obj.send_cmd(uint8([1 0 0 0 0])); %Отправка запроса позиции ручек
                [Data, timeout_flag] = get_bytes(obj.Serial_obj); %Ожидание ответа
                if timeout_flag
                    warning('receive timeout (in get_handle_position)')
                else
                    [R, C] = get_rc(Data);
                    obj.Analog.res = R;
                    obj.Analog.cap = C;
                end
            else
                warning('Could not get handle position: ammeter is sending data now')
            end
        end
        %----------------------------CMD_END--------------------------------
        
        
        %----------------------------Getters--------------------------------%Установка_приватных_полей_класса
        
        %varargout - любое количество выходных данных функции
        %nargout - количество выходных аргументов
        function varargout = show_flags(obj)
            if nargout == 1
                varargout{1} = obj.Flags;
            elseif nargout == 0
                disp(obj.Flags)
            else
                warning('wrong number of output arguments (show_flags)')
            end
        end
        
        function varargout = show_analog(obj)
            if nargout == 1
                varargout{1} = obj.Analog;
            elseif nargout == 0
                disp(obj.Analog)
            else
                warning('wrong number of output arguments (show_analog)')
            end
        end
        
        function set_gain(obj, gain)
            if gain < 0 || gain > 10000
                msg = ['Wrong gain settings (ignoreg):' newline ...
                    'input value: ' num2str(gain) newline ...
                    'current value: ' num2str(obj.Analog.gain)];
                warning(msg)
            else
                obj.Analog.gain = gain;
            end
        end
        
        function name = get_name(obj)
            name = obj.name;
        end
        %--------------------------Getters_END------------------------------
    end
    
    %-------------------------------PRIVATE--------------------------------
    properties (Access = private)
        name = '';
        COM_port_str = '';
        Serial_obj = [];
        pause_after_reset = 0.5;
        
        Flags = struct('sending', false, ...
            'connected', false, ...
            'relay_chV', false, ...
            'relay_zerocap', false);
        
        Analog = struct('bias', ...
            struct('ch1', -0.0021, 'ch2', -3.8772e-04), ...
            'voltage_out', 0, ...
            'Amplitude', 0, ...
            'Period', 1, ...
            'Waveform', 1,...
            'gain', 1, ...
            'res', -1, ...
            'cap', -1);
        
    end
    
    methods (Access = private)
        function close(obj)
            if obj.Flags.connected
                obj.disconnect();
            end
            disp(['"' obj.name '" Ammeter closed']);
        end
        
        function send_cmd(obj, CMD)
            write(obj.Serial_obj, uint8(CMD), "uint8"); % Отправляет на порт obj.Serial_obj данные в виде восьмибитного числа [0 - 255] от CMD
            pause(0.01);
        end
        
        function RESET(obj) %RESET CMD
            send_cmd(obj, uint8([9 0 0 0 0])); % Массив  uint8[9 0 0 0 0] - команда на аппаратном уровне, ПЕРЕЗАПУСКАЮЩАЯ амперметр
            pause(obj.pause_after_reset);
        end
    end
end


function [R, C] = get_rc(Data)
Data = Data(4);
Cind = bitand(Data, 0b1111) + 1; % Получение младшего ниббла первого число
Rind = bitshift(Data, -4) + 1;   % Получение маладшего ниббла второго числа 
R_array = [2e-9, 200e-9, 20e-6, 2e-3, 25e-3, -1]; %Ohm  %Эти два числа - индекс положения ручек
C_array = [-1, 10e-12, 100e-12, 1e-9, 100e-9, 10e-6]; %F
R = R_array(Rind);
C = C_array(Cind);
end

function port_name_check(port_name)

Avilable_ports = serialportlist('available');

if ~(sum(Avilable_ports == port_name) == 1) % Проверка наличия порта в доступных
    Text_ports_list = '';
    for i = 1:numel(Avilable_ports)
        Text_ports_list = [Text_ports_list char(Avilable_ports(i)) newline];
    end
    
    msg = ['ERROR: No such com port name.' newline ...
        'List of avilable ports:' newline ...
        Text_ports_list ...
        'Provided name: ' port_name];
    error(msg)
end

end

function serial_flush(serial_obj)
pause(0.05) %FIXME: why pause?
Bytes_count = serial_obj.NumBytesAvailable;
if Bytes_count > 0
    read(serial_obj, Bytes_count, "uint8");
end
end

function [Data, timeout_flag] = get_bytes(Obj)
Wait_timeout = 1; %s FIXME: do it 'global' value of class
timeout_flag = 0;
stop = 0;
Time_start = tic;
while ~stop
    Bytes_count = Obj.NumBytesAvailable;
    Bytes_count = floor(Bytes_count/4)*4;
    
    if Bytes_count > 0
        Data = read(Obj, Bytes_count, "uint8");
        stop = 1;
    end
    
    Time_now = toc(Time_start);
    if Time_now > Wait_timeout
        stop = 1;
        timeout_flag = 1;
        Data = 0;
    end
end
end

function [Value_X, Value_Y, CMD] = unpack_raw_bytes(Data_all)
Bytes_01 = Data_all(1:4:end);
Bytes_02 = Data_all(2:4:end);
Bytes_03 = Data_all(3:4:end);
Bytes_04 = Data_all(4:4:end);

CMD_ind = find((Bytes_01 == 0x80) & (Bytes_02 == 0x00));
if CMD_ind
    CMD.flag = true;
    CMD.high = Bytes_03(CMD_ind);
    CMD.low = Bytes_04(CMD_ind);
    Bytes_01(CMD_ind) = [];
    Bytes_02(CMD_ind) = [];
    Bytes_03(CMD_ind) = [];
    Bytes_04(CMD_ind) = [];
else
    CMD.flag = false;
    CMD.high = 0;
    CMD.low = 0;
end

Bytes_01(Bytes_01>=128) = Bytes_01(Bytes_01>=128) - 256;
Bytes_03(Bytes_03>=128) = Bytes_03(Bytes_03>=128) - 256;

Value_X = (Bytes_01*256 + Bytes_02)*10/2^15;
Value_Y = (Bytes_03*256 + Bytes_04)*10/2^15;
end

%Функция close all очищает все объекты класса Ammetr, которые были созданы начала работы
function close_all_ammeters()
input_class_name = 'Ammeter';
baseVariables = evalin('base' , 'whos'); % Берёт аргументы из рабочей области и приминяет ко всем функцию whos
Indexes = string({baseVariables.class}) == input_class_name; % Создали массив из значений поля class, сравнили с Ammeter, получили массив нулей и единиц
Var_names = string({baseVariables.name}); 
Var_names = Var_names(Indexes); % Оставили в массиве только имена класса Ammeter
Valid = zeros(size(Var_names));
for i = 1 : numel(Var_names)
    Valid(i) = evalin('base', ['isvalid(' char(Var_names(i)) ')']); % Проверка на существование имён
end
Valid = logical(Valid);
Var_names = Var_names(Valid);    % Отсеяли только валидные имена
for i = 1:numel(Var_names)
    evalin('base', ['delete(' char(Var_names(i)) ')']);  %Удалили
end
end

% Ammeter_bias_measure замеряет сигнал щупов, когда они висят в воздухе
function [ch1_mean, ch2_mean] = Ammeter_bias_measure(obj)     
Measuring_period = 1; %s FIXME: do it 'global' value of class
Flags = obj.show_flags;

if ~Flags.connected
    obj.connect('reset');
else
    obj.disconnect();
    pause(0.01); %FIXME: why pause?
    obj.connect('reset');
end

obj.voltage_set(0);
obj.relay_chV(false);
obj.relay_zerocap(false);

stream_ch1 = [];
stream_ch2 = [];

obj.sending(1);
timer = tic;
while toc(timer) < Measuring_period
    [part_ch_1, part_ch_2, ~] = obj.read_data();
    stream_ch1 = [stream_ch1 part_ch_1];
    stream_ch2 = [stream_ch2 part_ch_2];
end
obj.sending(false);
obj.disconnect();

ch1_mean = mean(stream_ch1);       %Получаем сигнал
ch2_mean = mean(stream_ch2);
end

function [byte_high, byte_low, voltage] = voltage2bitcode(voltage)
high_limit = 10 - 1/2^16;
low_limit = -10;
if voltage > high_limit
    voltage = high_limit;
end
if voltage < low_limit
    voltage = low_limit;
end

bitcode = int16(floor(32768*voltage/10));


bit_set_low = bitget(bitcode, 8:-1:1);
byte_low = uint8(bi2de(flip(bit_set_low)));

bit_set_high = bitget(bitcode, 16:-1:9);
byte_high = uint8(bi2de(flip(bit_set_high)));

end

%FIXME: delete old code below
% function [byte_high, byte_low] = voltage2bitcode(voltage)
% if voltage < -10
%     voltage = -10;
% end
% if voltage > 10
%     voltage = 10;
% end
%
% bitcode = int16(32767*voltage/(10*32767/32768));
%
% byte_low = int8(bitand(bitcode, int16(0b11111111)));
% byte_high = int8(bitshift(bitcode, -8));
% byte_high = typecast(int8(byte_high), 'uint8');
%
% end


