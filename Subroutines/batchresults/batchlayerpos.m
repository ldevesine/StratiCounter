function [LayerposDepth, logPobs_final] = batchlayerpos(Layerpos,depth,...
    tau,Layer0,postau,ntauTotal,d,pd,logb,dx,plotlevel)

%% [LayerposDepth, logPobs_final] = batchlayerpos(Layerpos,depth,...
% tau,Layer0,postau,ntauTotal,d,pd,logb,dx,plotlevel)
% Converting the entries in Layerpos from pixel to depth, and computing an
% optimal set of layer boundaries based on a Forward-Backward constrained 
% version of the Viterbi algorithm.
% 
% Copyright (C) 2015  Mai Winstrup
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation; either version 2 of the License, or (at your 
% option) any later version.

%% ForwardBackward layering within considered interval:
% Layering according to the Forward-Backward algorithm, converted to
% depths. Boundaries located in pixel 1 are defined to be part of the 
% previous batch.
mask = Layerpos.fb(:,1)>1 & Layerpos.fb(:,1)<=tau;
Layerpos.fb = Layerpos.fb(mask);
LayerposDepth.fb = depth(Layerpos.fb-0.5)+0.5*dx;

% Locations with layer location issues:
mask = Layerpos.fb_issues(:,1)>1 & Layerpos.fb_issues(:,1)<=tau;
Layerpos.fb_issues = Layerpos.fb_issues(mask,:);
LayerposDepth.fb_issues(:,1) = depth(Layerpos.fb_issues(:,1)-0.5)+0.5*dx;
LayerposDepth.fb_issues(:,2) = Layerpos.fb_issues(:,2);

%% An optimal set of layerboundaries: 
% Found by using the viterbi algorithm, constrained by output of the
% Forward-Backward algorithm. 
% Constraints are: Probability distribution of location of first layer 
% (layer0), location of the last layer boundary (fixed), and the derived 
% most likely number of layers inbetween. 

% Layer duration parameters:
dmax = max(d);
D = length(d);

% Constraints:
% Probability distribution for ending of layer previous to batch:
layer0_pos = zeros(1,dmax);
istart = dmax-length(Layer0.pos)+1;
layer0_pos(max(1,istart):end)=Layer0.pos(max(1,-istart+2):end);
% Normalize probabilities:
layer0_pos = layer0_pos/sum(layer0_pos); %[probabilities]

% Location of last layer boundary (end of layer) in batch:
% Selected as mode of the probability distribution postau.
[~, imax] = max(postau);
lastlayerpx = tau-length(postau)+imax-1; %[pixel]
% We know that this layer boundary will be located before tau, just as will 
% the corresponding Forward-Backward layer boundary.

% Most likely number of layers in data series up to now: 
[~,imax] = max(ntauTotal(:,2));
nLayerML = ntauTotal(imax,1);
% Most likely number of layers in beginning of data series:
[~,imax] = max(Layer0.no(:,2));
nLayer0ML = Layer0.no(imax,1);
% Most likely number of layers in this batch:
nLayerML = nLayerML-nLayer0ML;

% Tiepoints must be non-empty, but value is not used (?)
tiepoints = 'not empty';  
[layerpos_final, logPobs_final] = viterbi(tau,nLayerML,layer0_pos,d,...
    dmax,D,log(pd),logb(1:tau+dmax,:),tiepoints,lastlayerpx,plotlevel); 

% Convert to depth:
LayerposDepth.final = depth(layerpos_final-0.5)+0.5*dx;

%% Compare resulting layer boundary positions:
if plotlevel > 1
    figure;
    plot(LayerposDepth.fb,'-k')
    hold on
    plot(LayerposDepth.final,'-r')
    hleg = legend({'FB agescale','Final agescale'});
    set(hleg,'location','northwest')
    xlabel('Age')
    ylabel('Depth')
end