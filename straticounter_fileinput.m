function m = straticounter_fileinput(varargin)

%% STRATICOUNTER: A layer counting algorithm
% STRATICOUNTER(settings_file_name) loads settings from the named file in
%   "settings_file_name". 
%
% STRATICOUNTER(settings_path, output_path) loads settings from a ".mat"
%   file whose path and name is given in "settings_path". The output of the
%   function will be saved in the "output_path".
%
% INPUTS:
%   settings_file_name (string): Name of the settings file (.m) to load.
%       It is assumed that the file is located in a local folder
%       called "Settings".
%   settings_path (string): Path to the file (.mat) from which the
%       settings should be loaded.
%   output_path (string): Path to the folder where the output of the
%       function should be written.
%
% OUTPUTS:
%   When providing only 1 argument, the output files will be placed in a
%   local folder named "Output"
%
%   When providing 2 arguments, the output files will be saved in the
%   folder specified by the "output_path" argument.
%
% DETAILS:
% The algorithm is based on the principles of statistical inference of
% hidden states in semi-Markov processes. States, and their associated
% confidence intervals, are inferred by the Forward-Backward algorithm.
% The EM (Expectation-Maximization) algorithm is used to find the optimal
% set of layer parameters for each data batch. Confidence intervals do not
% account for the uncertainty in estimation of layer parameters.
%
% If (absolute) tiepoints are given, the algorithm is run between these,
% while assuming constant annual layer signals between each pair. If no
% tiepoints, the algorithm is run batch-wise down the core, with a slight
% overlap between consecutive batches.
%
% The algorithm was developed for visual stratigraphy data from the NGRIP
% ice core (Winstrup (2011), Winstrup et al. (2012)). It has later been
% applied to other cores, and extended to parallel analysis of multi-
% parameter data sets (e.g. Vallelonga et al. (2014), Sigl et al. (in prep,
% 2015)). For testing purposes, it can also be run on synthetic data.
%
% See Winstrup (2011) and Winstrup et al. (2012) for further documentation.
%
% When using this script, please provide release date of the algorithm,
% and cite:
% Winstrup et al., An automated approach for annual layer counting in
% ice cores, Clim. Past. 8, 1881-1895, 2012.
%
%% Copyright (C) 2015  Mai Winstrup
% Files associated with the matchmaker software (matchmaker.m,
% matchmaker_evaluate.m) is authored and copyrighted by Sune Olander
% Rasmussen.
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
% Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

%% Release date:
releasedate = '07-07-2015';

%% Paths to subroutine and settings folders:
if ~isdeployed % shows whether this is a compiled instance of the code
    % Header for current run:
    disp('==========================================')
    disp(varargin{1})
    disp('==========================================')
    % close all
    addpath(genpath('./Subroutines'))
    addpath(genpath('./Settings'))
end

%% Select model settings:
% Import default settings:
Model = defaultsettings();
% Add release date:
Model.releasedate = releasedate;

%% Core-specific settings:
% Make generic message to be used when incorrect number of inputs are used:
vararg_err = 'This function accepts a maximum of two (2) input arguments';

% Use 'nargin' to see the number of input arguments, and select appropriate 
% behavior:
if nargin == 1    
    % Check that settings file exists:
    if ~exist(['Settings/' varargin{1}],'file')
        error('Settings file unknown, please correct')
    end
    % Import settings:
    run(varargin{1});
elseif nargin ==2
    run(varargin{1});
else
    error(vararg_err);
end

m = Model;
end