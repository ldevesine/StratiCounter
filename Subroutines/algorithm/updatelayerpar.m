function [Layerpar_new, relweight] = ...
    updatelayerpar(ExpVal,FBprob,Prior,Layerpar,d,pd,logb,Model)

%% [Layerpar_new, relweight] = updatelayerpar(ExpVal,FBprob,Prior,...
%    Layerpar,d,pd,logb,bweight,Model)
% Calculating 1) a new, optimized set of layer parameters, and 2) average 
% relative probability of layer thickness and layer shape when calculating 
% layer likelihoods. The variable "relweight" is the value of bweight, 
% which will make layer shape and layer thicknesses to be weighted equally. 

% The layer parameters may be updated in one out of the following ways:
% a) No updates (for one or several layer parameter components)

% b) Maximum likelihood layer parameters:
% Calculating the resulting maximum likelihood duration parameters as
% well as annual layer parameters based on a MAP analysis of the data
% section. The result is based on the entire data batch. The update is
% performed without assuming any prior knowledge. 

% c) Quasi-Bayes estimate of layer parameters: 
% Calculating the resulting maximum-a-posteriori duration parameters as
% well as annual layer parameters based on a MAP analysis of the data
% section. The result is based on the entire data batch. The update
% equations are computed using a quasi-Bayes approach. To simplify matters,
% only my and par are allowed to vary, all remaining parameters are assumed
% known.

% d) Gibbs sampling using either of the two above (not fully implemented):
% The new layer parameters are found by drawing randomly from resulting
% parameter distributions, assuming these to be normal distributed. This is 
% a blocked Gibbs sampler since all parameters are updated at once. By 
% using Gibbs sampling to explore the probability space of the layer 
% parameters we obtain better (larger) uncertainty distributions on the
% resulting timescale.

% e) If new parameter values are nan (due to nan in data): Use the original 
% version of layerpar as substitute.

% Copyright (C) 2015  Mai Winstrup
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation; either version 2 of the License, or (at your 
% option) any later version.

%% Duration parameters:
dmax = max(d);
D = length(d);
% Length of data batch:
T = length(ExpVal)-dmax;

%% Layer probabilities:
% As all layer parameter probabilities are independent of layer number, the 
% important measure is the probability that we have any layer j with 
% duration d ending at t, conditioned on the entire data series
% (P(S[t-d+1:t]=j|o_1:T)).
% Summing eta over all possible states, j: 
eta_sumj = nansum(FBprob.eta,2);
eta_sumj = reshape(eta_sumj(:,1,:),T+dmax,D); % Indexed: eta_sumj(tend,id)

% Summing over all ending times and durations: 
sumeta = nansum(eta_sumj(:));

% Number of data points on which the estimates are based:
N = nan(T+dmax,D,Model.nSpecies);
for j = 1:Model.nSpecies
    N(:,:,j) = reshape([ExpVal(:,:,j).N],T+dmax,D); 
    % Not the same for all species as there may be nans in data. 
end

% For parameter estimation, we wish to remove the contribution to the
% summation of eta from areas where parameter values are not defined: 
sumeta2 = nan(Model.nSpecies,1);
for j = 1:Model.nSpecies
    eta_sumj2 = eta_sumj;
    eta_sumj2(N(:,:,j)==0)=0;
    sumeta2(j) = sum(eta_sumj2(:));
end

%% Expectation value of b and p(d):
% logb was previously multiplied by bweight, given by: 
nEff = (Model.derivatives.nDeriv+1)*sum(Model.wSpecies);
bweight = Model.bweight/nEff;
% Original values: 
logb_raw = logb/bweight;

% Expectation value of b:
matrix1 = eta_sumj.*exp(logb_raw); 
expvalb = nansum(matrix1(:))/sumeta;
% Expectation value of logb:
expvalLogb = log(expvalb);

% Expectation value of p(d)
matrix2 = nan(size(eta_sumj,1),D);
for i = 1:D
    matrix2(:,i) = eta_sumj(:,i).*pd(i);
end
expValpd = nansum(matrix2(:))/sumeta;
% Expectation value of log(p(d))
expVallogpd = log(expValpd);

% Relative values of the two: 
relweight = expVallogpd/expvalLogb;

%% If no updating of any model parameters:
if sum(~strcmp(Model.update,'none'))==0 % No updating of any parameter
    Layerpar_new = Layerpar;
    return
end

%% Layer distribution parameters (my and sigma):
% My:
switch Model.update{1}
    case 'none'
        Layerpar_new.my = Layerpar.my;
    case 'ML'
        Layerpar_new.my = sum(sum(eta_sumj,1).*log(d*Model.dx))/sumeta;
    case 'QB'
        Layerpar_new.my = (Prior.v*sum(sum(eta_sumj,1).*log(d*Model.dx))+...
            Model.rho*Prior.sigma^2*Prior.m)/...
            (Prior.v*sumeta+Model.rho*Prior.sigma^2);
    case 'gibbs'
        % Gibbs sampling (with priors) 
        n = sumeta;
        ymean = sum(sum(eta_sumj,1).*log(d*Model.dx))/n;
        m_post = (Prior.m*Prior.kappa*Layerpar.sigma^2+n*ymean)/...
            (Prior.kappa*Layerpar.sigma^2+n);
        kappa_post = Prior.kappa+n/Layerpar.sigma^2;
    
        % Draw new value for my from this distribution:
        my = m_post+kappa_post^-2*randn(1,1);
        Layerpar_new.my = my+randn(1,1)*(Prior(1).v)^0.5; % OBS: not correct
end

% Sigma:
switch Model.update{2}
    case 'none'
        Layerpar_new.sigma = Layerpar.sigma;
    case 'ML'
        Layerpar_new.sigma = sqrt(sum(sum(eta_sumj,1).*...
            (log(d*Model.dx)-Layerpar_new.my).^2)/sumeta);
    case 'gibbs'
        % Gibbs sampling: 
        % Prior of sigma^2 is an inverse-gamma distribution.
        alpha_post = Prior.alpha + n/2;
        beta_post = Prior.beta+0.5*sum(sum(eta_sumj,1).*...
            (log(d*Model.dx)-Layerpar_new.my).^2);   
        %beta_post = prior.beta+0.5*sum( (log(lambda)-Layerpar_new.my).^2) 
        %not correct: hvorfor bliver denne v�rdi dobbelt s� stor?
        sigma = sqrt(1./random('gam',alpha_post,1/beta_post));
        Layerpar_new.sigma = sigma; % not correct 
end

%% Parameter values and their covariance:
% Mean trajectory parameter (par):
switch Model.update{3}
    case 'none'
        Layerpar_new.par = Layerpar.par;
    case 'ML'
        for j = 1:Model.nSpecies
            XWXmatrix = reshape([ExpVal(:,:,j).XWX],Model.order,Model.order,T+dmax,D);
            XWoXrmatrix = reshape([ExpVal(:,:,j).XWoXr],Model.order,T+dmax,D);
        
            XWX = nan(Model.order,Model.order);
            XWoXr = nan(Model.order,1);
            for i = 1:Model.order
                matrix1 = eta_sumj2.*reshape(XWoXrmatrix(i,:,:),T+dmax,D);
                XWoXr(i) = nansum(matrix1(:));
    
                for k = 1:Model.order
                    matrix2 = eta_sumj2.*reshape(XWXmatrix(i,k,:,:),T+dmax,D);
                    XWX(i,k) = nansum(matrix2(:));
                end
            end
            Layerpar_new.par(:,j) = XWX\XWoXr;
        end
        
    case 'QB'
        for j = 1:Model.nSpecies
            XWXmatrix = reshape([ExpVal(:,:,j).XWX],Model.order,Model.order,T+dmax,D);
            XWoXrmatrix = reshape([ExpVal(:,:,j).XWoXr],Model.order,T+dmax,D);
                
            XWX = nan(Model.order,Model.order);
            XWoXr = nan(Model.order,1);
            for i = 1:Model.order
                matrix1 = eta_sumj2.*reshape(XWoXrmatrix(i,:,:),T+dmax,D);
                XWoXr(i) = nansum(matrix1(:));
        
                for k = 1:Model.order
                    matrix2 = eta_sumj2.*reshape(XWXmatrix(i,k,:,:),T+dmax,D);
                    XWX(i,k) = nansum(matrix2(:));
                end
            end
            XWX_rhonvarinvU = XWX+Prior.nvar(:,j)*Prior.invU(:,:,j)*Model.rho;
            Layerpar_new.par(:,j) = XWX_rhonvarinvU\...
                (XWoXr+Model.rho*Prior.nvar(:,j)*Prior.invU(:,:,j)*Prior.u(:,j));
        end
    
    case 'gibbs'
        %% Gibbs sampling:    
        % Sample mean: 
        par_mean = nan(Model.order,Model.nSpecies);
        for j = 1:Model.nSpecies
            XWXmatrix = reshape([ExpVal(:,:,j).XWX],Model.order,Model.order,T+dmax,D);
            XWoXrmatrix = reshape([ExpVal(:,:,j).XWoXr],Model.order,T+dmax,D);
        
            XWX = nan(Model.order,Model.order);
            XWoXr = nan(Model.order,1);
            for i = 1:Model.order
                matrix1 = eta_sumj2.*reshape(XWoXrmatrix(i,:,:),T+dmax,D);
                XWoXr(i) = nansum(matrix1(:));
    
              for k = 1:Model.order
                    matrix2 = eta_sumj2.*reshape(XWXmatrix(i,k,:,:),T+dmax,D);
                    XWX(i,k) = nansum(matrix2(:));
              end
            end
            par_mean(:,j) = XWX\XWoXr; % sample mean
        
            C = inv(Layerpar.cov((j-1)*Model.order+1:j*Model.order,...
                (j-1)*Model.order+1:j*Model.order));
            %par_post(:,j)=(prior.Lambda(:,:,j)+n*C)\(prior.Lambda(:,:,j)...
            % *prior.u(:,j)+n*prior.Lambda(:,:,j)*par_mean(:,j));

            S0 = inv(Prior.Lambda(:,:,j));
            my0 = Prior.u(:,j);
            S = inv(C);
        
            SN = inv(inv(S0)+n*inv(S));
            myN = SN*(n*inv(S)*par_mean(:,j)+inv(S0)*my0);
            par_post(:,j)=myN;
    
            Layerpar_new.par(:,j)=mvnrnd(myN,SN); % create random number            
            %Layerpar_gibbs.par = Layerpar_new.par+randn(Model.order,1)*Layerpar_new.par/10;
        end
end

%% Covariance (cov):
switch Model.update{4}
    case 'none'
        Layerpar_new.cov = Layerpar.cov;
   
    case 'ML'
        Layerpar_new_cov = nan(Model.order,Model.order,Model.nSpecies);
        for j = 1:Model.nSpecies
            rrmatrix = reshape([ExpVal(:,:,j).rr],Model.order,Model.order,T+dmax,D);
            for i = 1:Model.order
                for k = 1:Model.order
                    rr = eta_sumj2.*reshape(rrmatrix(i,k,:,:),T+dmax,D);
                    Layerpar_new_cov(i,k,j) = nansum(rr(:))/sumeta2(j);
                end
            end
        end
        % Convert to new format of the covariance matrix:
         for j = 1:Model.nSpecies
             Layerpar_new.cov((j-1)*Model.order+1:j*Model.order,(j-1)*Model.order+1:j*Model.order) = Layerpar_new_cov(:,:,j);
         end
         
    case 'gibbs'        
end

% To which degree should data covariance be included?
switch Model.covariance
    case 'none' % All covariance neglected
        Layerpar_new.cov = diag(diag(Layerpar_new.cov));
    
    case 'species' % Only accounting for intra-species covariance
        for j = 1:Model.nSpecies
            Layerpar_new.cov((j-1)*Model.order+1:j*Model.order,1:(j-1)*Model.order)=0;
            Layerpar_new.cov((j-1)*Model.order+1:j*Model.order,j*Model.order+1:end)=0;
        end
        
    otherwise
        % Version using full covariance matrix, i.e. accounting 
        % also for inter-species covariance, is not implemented. 
        disp('Using full covariance matrix not implemented')
        return
end

%% White noise component (nvar):
switch Model.update{5}
    case 'none'
        Layerpar_new.nvar = Layerpar.nvar;

    case 'ML'
        for j = 1:Model.nSpecies
            eWe = nan(T+dmax,D);
            for t = 1:T+dmax
                for id = 1:D
                    if isempty(ExpVal(t,id,j).oXr)
                        eWe(t,id) = nan;
                    else
                        residuals = ExpVal(t,id,j).oXr-ExpVal(t,id,j).X*Layerpar_new.par(:,j);
                        eWe(t,id) = residuals'*diag(ExpVal(t,id,j).invw)*residuals+...
                            trace(ExpVal(t,id,j).XWX*ExpVal(t,id,j).Cr);        
                    end
                end
            end
            upperpart = eta_sumj2.*eWe;
            lowerpart = eta_sumj2.*double(N(:,:,j));
            % Dividing here with the number of datapoints included in vector, 
            % which is not necessarily the same as its duration.
            Layerpar_new.nvar(:,j) = nansum(upperpart(:))/nansum(lowerpart(:));
        end
        
    case 'gibbs'
        % Not implemented.
end

%% If any of the layer parameters come up as NaN, we use the old version of 
% the layer parameters instead. This may e.g. happen if there is no data at
% all in the entire data section for a given species.
if ~isfinite(Layerpar_new.sigma)
    Layerpar_new.sigma = Layerpar.sigma;
end
if sum(~isfinite(Layerpar_new.par(:)))>0
    mask = ~isfinite(Layerpar_new.par);
    Layerpar_new.par(mask) = Layerpar.par(mask);
end
if sum(~isfinite(Layerpar_new.cov(:)))>0
    mask = ~isfinite(Layerpar_new.cov);
    Layerpar_new.cov(mask) = Layerpar.cov(mask);
end
if sum(~isfinite(Layerpar_new.nvar(:)))>0
    mask = ~isfinite(Layerpar_new.nvar);
    Layerpar_new.nvar(mask) = Layerpar.nvar(mask);
end