
% TODO:
% 1) Transform values
% 2) Add all CMDs
% 3) 
% 4) 
% 5) Data2File export
% 6) 
% 7) 

%CMD:
%  1) get handle pos      - DONE
%  2) ---
%  3) set zero relay      - DONE
%  4) set sending flag    - DONE
%  5) Set amp and period  - 
%  6) Start measuring     - DONE
%  7) Set Output_flag     - 
%  8) Set DAC value       - DONE
%  9) RESET               - DONE
% 10) set V_ch relay      - DONE
% 11) set_wave_form_gen   - 


classdef Ammeter < handle
    %--------------------------------public--------------------------------
    methods (Access = public)
        function obj = Ammeter(port_name, varargin)
            if nargin > 1 && ~isempty(varargin{1})
                name_in = varargin{1};
            else
                name_in = 'Yoyo';
            end
            close_all_ammeters();
            obj.name = char(name_in);
            obj.COM_port_str = char(port_name);
            port_name_check(obj.COM_port_str);
            disp(['"' obj.name '" Ammeter created at port: ' obj.COM_port_str]);
            if nargin > 2 && varargin{2} == "bias"
                disp(['Input bias correction in "' obj.name '"']);
                obj.bias_correction();
            end
        end
        
        function delete(obj)
            close(obj);
        end
        
        function connect(obj, varargin)
            if ~obj.Flags.connected
                obj.Serial_obj = serialport(obj.COM_port_str, 230400);
                obj.Flags.connected = true;
                if nargin == 2 && varargin{1} == "reset"
                    obj.RESET();
                    pause(0.2);
                end
                get_handle_position(obj);
                disp(['"' obj.name '" connected at port: ' obj.COM_port_str])
            else
                warning(['"' obj.name '" already connected at port: ' obj.COM_port_str]);
            end
        end
        
        function disconnect(obj)
            if obj.Flags.connected
                obj.voltage_set(0);
                obj.relay_zerocap(false);
                delete(obj.Serial_obj);
                obj.Flags.connected = false;
                disp(['Disconnecting "' obj.name '" at port: ' obj.COM_port_str])
            else
                warning(['Nothing to disconnect at ' obj.name]);
            end
        end
        
        function [V_ch1, V_ch2, isOk] = read_data(obj, varargin)
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
        
        %--------------------------------CMD--------------------------------
        function sending(obj, flag)
            if obj.Flags.connected
                if ~obj.Flags.sending
                    get_handle_position(obj);
                end
                flag = logical(flag);
                obj.send_cmd(uint8([4 0 flag 0 0]));
                obj.Flags.sending = flag;
            else
                warning('CMD ignored')
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
                [byte_high, byte_low] = voltage2bitcode(voltage);
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
        
        function [R, C] = get_handle_position(obj)
            R = -1;
            C = -1;
            if ~obj.Flags.connected
                warning('Could not get handle position: ammeter disconnected')
            elseif ~obj.Flags.sending
                serial_flush(obj.Serial_obj);
                obj.send_cmd(uint8([1 0 0 0 0]));
                [Data, timeout_flag] = get_bytes(obj.Serial_obj);
                if timeout_flag
                   warning('receive timeout')
                else
                    [R, C] = get_rc(Data);
%                     disp([num2str(R) ' ' num2str(C)])
                    obj.Analog.res = R;
                    obj.Analog.cap = C;
                end
                
            else
                warning('Could not get handle position: ammeter is sending data now')
            end
        end
        
        
        
        
        
        function varargout = show_flags(obj)
            if nargout == 1
                varargout{1} = obj.Flags;
            elseif nargout == 0
                disp(obj.Flags)
            else
                warning('wrong number of output arguments')
            end
        end
        
        function set_gain(obj, gain)
            if gain < 0 | gain > 10000
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
        

        
        function show_analog(obj)
            if nargout == 1
                varargout{1} = obj.Analog;
            elseif nargout == 0
                disp(obj.Analog)
            else
                warning('wrong number of output arguments')
            end
        end
    end
    
    %-------------------------------private--------------------------------
    
    properties (Access = private)
        name = '';
        COM_port_str = '';
        Serial_obj = [];
        
        Flags = struct('sending', false, ...
            'connected', false, ...
            'relay_chV', false, ...
            'relay_zerocap', false);
        
        Analog = struct('bias', ...
            struct('ch1', -0.0021, 'ch2', -3.8772e-04), ...
            'voltage_out', 0, ...
            'gain', 1, ...
            'res', -1, ...
            'cap', -1);
        
    end
    
    
    methods (Access = private)
        function close(obj)
            if obj.Flags.sending
                sending(obj, false);
            end
            if obj.Flags.connected
                obj.disconnect();
            end
            disp(['"' obj.name '" Ammeter closed']);
        end
        
        function send_cmd(obj, CMD)
                write(obj.Serial_obj, uint8(CMD), "uint8");
                pause(0.01);
        end
        
        function RESET(obj)
            send_cmd(obj, uint8([9 0 0 0 0]));
        end
    end
    
    
end


function [R, C] = get_rc(Data)
Data = Data(4);
Cind = bitand(Data, 0b1111) + 1;
Rind = bitshift(Data, -4) + 1;
Rarray = [2e-9, 200e-9, 20e-6, 2e-3, 25e-3, -1]; %Ohm
Carray = [-1, 10e-12, 100e-12, 1e-9, 100e-9, 10e-6]; %F
R = Rarray(Rind);
C = Carray(Cind);
end



function port_name_check(port_name)

Avilable_ports = serialportlist('available');
% Avilable_ports = ["COM1" "COM3" "COM11" "COM12"];

if ~(sum(Avilable_ports == port_name) == 1)
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
    pause(0.1)
    Bytes_count = serial_obj.NumBytesAvailable;
    if Bytes_count > 0
        read(serial_obj, Bytes_count, "uint8");
    end
end


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




function close_all_ammeters()

input_class_name = 'Ammeter';

baseVariables = evalin('base' , 'whos');

Indexes = string({baseVariables.class}) == input_class_name;

Var_names = string({baseVariables.name});

Var_names = Var_names(Indexes);
Valid = zeros(size(Var_names));
for i = 1:numel(Var_names)
    Valid(i) = evalin('base', ['isvalid(' char(Var_names(i)) ')']);
end
Valid = logical(Valid);
Var_names = Var_names(Valid);


for i = 1:numel(Var_names)
    evalin('base', ['delete(' char(Var_names(i)) ')']);
end

end


function [ch1_mean, ch2_mean] = Ammeter_bias_measure(obj)

Measuring_period = 1; %s

Flags = obj.show_flags;

if ~Flags.connected
    obj.connect('reset');
else
    obj.disconnect();
    pause(0.1);
    obj.connect('reset');
end
pause(0.2);

%TODO: add zero voltage at outout
relay_chV(obj, false);
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

ch1_mean = mean(stream_ch1);
ch2_mean = mean(stream_ch2);

obj.sending(0);
relay_chV(obj, false);
obj.disconnect();

end


function [byte_high, byte_low, bitcode] = voltage2bitcode(voltage)
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


