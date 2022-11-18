
classdef Ammeter < handle
    %--------------------------------public--------------------------------
    methods (Access = public)
        function obj = Ammeter(port_name, name_in)
            close_all_ammeters();
            obj.name = char(name_in);
            obj.COM_port_str = char(port_name);
            port_name_check(obj.COM_port_str);
            
            disp(['"' obj.name '" Ammeter created at port: ' obj.COM_port_str]);
        end
        
        function connect(obj)
            if ~obj.Flags.connected
                obj.Serial_obj = serialport(obj.COM_port_str, 230400);
                obj.Flags.connected = true;
                disp(['"' obj.name '" connected at port: ' obj.COM_port_str])
            else
                warning(['"' obj.name '" already connected at port: ' obj.COM_port_str]);
            end
        end
        
        function disconnect(obj)
            if obj.Flags.connected
                delete(obj.Serial_obj);
                obj.Flags.connected = false;
                disp(['Disconnecting "' obj.name '" at port: ' obj.COM_port_str])
            else
                warning(['Nothing to disconnect at ' obj.name]);
            end
        end
        
        function [V_ch1, V_ch2] = read_data(obj)
            V_ch1 = [];
            V_ch2 = [];
%             Data = [];
            if ~obj.Flags.connected
                warning([obj.name ' disconnected'])
            elseif ~obj.Flags.sending
                warning([obj.name ' is not sending anything'])
            else
                [Temp_data, timeout_flag] = get_bytes(obj.Serial_obj);
                if timeout_flag
                    warning('data recive timeout')
                end
                [V_ch1, V_ch2] = unpack_raw_bytes(Temp_data);
                % Data = [V_ch1; V_ch2] - [obj.Analog.bias.ch1; obj.Analog.bias.ch2];
                V_ch1 = V_ch1 - obj.Analog.bias.ch1;
                V_ch2 = V_ch2 - obj.Analog.bias.ch2;
            end
        end
        
        function sending(obj, flag)
            if obj.Flags.connected
                flag = logical(flag);
                write(obj.Serial_obj, uint8([4 0 flag 0 0]), "uint8");
                obj.Flags.sending = flag;
            else
                warning('CMD ignored')
            end
        end
        
        
        function relay_chV(obj, flag)
            flag = logical(flag);
            obj.Flags.relay_chV = flag;
            write(obj.Serial_obj, uint8([10 0 flag 0 0]), "uint8");
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
        
        function name = get_name(obj)
            name = obj.name;
        end
        
        function delete(obj)
            
            close(obj);
        end
    end
    
    %-------------------------------private--------------------------------
    
    properties (Access = private)
        name = '';
        COM_port_str = '';
        Serial_obj = [];
        
        Flags = struct('sending', false, ...
                       'connected', false);
        
        Analog = struct('bias', ...
            struct('ch1', -0.0021, 'ch2', -3.8772e-04));
        
    end
    
    
    methods (Access = private)
        function close(obj)
            if obj.Flags.connected
                obj.disconnect();
            end
            disp(['"' obj.name '" Ammeter closed']);
        end
        
    end
    
    
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










