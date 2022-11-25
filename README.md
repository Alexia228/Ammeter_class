
TODO here:
1) Describe class using restrictions
2) Describe every function and its arguments
3) Describe external functions, for ammeter application


classdef Ammeter

Public methods:

function obj = Ammeter(port_name, varargin)
function delete(obj)
function connect(obj, varargin)
function disconnect(obj)
function [V_ch1, V_ch2, isOk] = read_data(obj, varargin)
function bias_correction(obj)
%-------------------------------CMD---------------------------------
function sending(obj, flag)
function relay_chV(obj, flag)
function relay_zerocap(obj, flag)
function voltage_set(obj, voltage)
function start_measuring(obj)
function set_amp_and_period(obj, amp, period)
function [R, C] = get_handle_position(obj)
%----------------------------Getters--------------------------------
function varargout = show_flags(obj)
function varargout = show_analog(obj)
function set_gain(obj, gain)
function name = get_name(obj)


 
Private Data:

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




