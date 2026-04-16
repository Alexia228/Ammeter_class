
% TODO:
% 1) replace fig to axis
% 2) add smart lim

classdef DWM_graph < handle

    methods (Access = public)
        function obj = DWM_graph(fig)
            obj.fig = fig;
            figure(obj.fig);
            obj.clear;
        end

%         function delete(obj)
%             close(obj.fig)
%         end

        function lines = get_lines(obj)
            axis = obj.fig.Children;
            lines = axis.Children;
        end

        function set_props_to_active(obj, color, style, width)
            obj.active_line.Color = color;
            obj.active_line.LineStyle = style;
            obj.active_line.LineWidth = width;
        end

        function add_new_line(obj, color, style, width)
            axis = obj.fig.Children;
            if isempty(axis)
                axis = axes(obj.fig);
            end
            obj.active_line = line_factory(color, style, width, axis);
        end

        function update_last(obj, x, y)
            obj.active_line.XData = x;
            obj.active_line.YData = y;
            drawnow;
        end

        function clear(obj)
            axis = obj.fig.Children;
            delete(axis);
            
        end

        function gray_all(obj)
            axis = obj.fig.Children;
            if ~isempty(axis)
                lines = axis.Children;
                for i = 1:numel(lines)
                    color = lines(i).Color;
                    color = rgb2gray(color);
                    lines(i).Color = color;
                    sparse_lines(lines(i));
                end
                drawnow
            end
        end

        function add_new_and_shadow_prev(obj, color, style, width)
            obj.gray_all();
            obj.add_new_line(color, style, width);
        end

    end

    methods (Access = private)

        
    end

    properties (Access = private)
        fig;
        active_line;
    end

end






function line_out = line_factory(color, style, width, axis)
x = xlim;
y = ylim;
line_out = line(axis, [x(1) x(1)], [y(1) y(1)], 'color', color, 'linestyle', style, 'linewidth', width);
end


function [x, y] = sparse_data(x, y)
    while numel(x) > 4000
        x2 = x(1:2:end);
        y2 = y(1:2:end);
        x2(end) = x(end);
        y2(end) = y(end);
        x = x2;
        y = y2;
    end
end


function sparse_lines(line)
x = line.XData;
y = line.YData;
[x, y] = sparse_data(x, y);
line.XData = x;
line.YData = y;
end

