function Model = straticounter_variableinput(name,speciesls,datapath,startdepth,enddepth,tiepts,dx,dxoffset)
%there are functions defined in ./Subroutines that is used to load the
%default settings
addpath(genpath('./Subroutines'));
Model = defaultsettings();
Model.icecore=name;
Model.species=speciesls;
Model.nSpecies=length(Model.species);
Model.wSpecies=ones(Model.nSpecies,1);
Model.path2data=datapath;
Model.dstart=startdepth;
Model.dend=enddepth;
Model.tiepoints=tiepts;
Model.dx=dx;
Model.dx_offset=dxoffset;
for j = 1:Model.nSpecies
    Model.preprocsteps{j,1} = {'zscore',1};
    Model.preprocsteps{j,2} = []; 
end
Model.nLayerBatch=50;
Model.nameManualCounts='counts_example.txt';
Model.ageUnitManual='AD';
Model.manualtemplates=[Model.dstart Model.dend];
Model.initialpar=[Model.dstart, Model.dstart+0.5*(Model.dend-Model.dstart)];
Model.update={'ML''ML''ML''ML''ML'};
Model.dxLambda=[1 5];
Model.dMarker=[];
Model.ageUnitOut='AD';
Model.releasedate = '07-07-2015';
end