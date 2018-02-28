function sdc_multiTE(fileName,fileNumber,NTE,NPro)

%%Author: Jinbang Guo; sampling density compensation for data from
%%interleaved multi-TE UTE
% clear all;
%addpath '/users/frend7/recon/sdc3_nrz_11aug/';
%addpath '/users/frend7/recon/grid3_dct_11aug/';
%addpath '/users/frend7/recon/MultiTE_Recon/';
% path = '/users/frend7/20160906_093109_IRC272A_MF_DoxyMice_1_1/';
%path=strcat(['/users/frend7/',fileName]);
% fileNumber = 16;
% beta = 1.5; % expansion factor ratio: alpha_x/alpha_z, with alpha_x=alpha_y.
beta=1;

% NPro=ones(1,1);
%NPro(1)=29556;


% fid=fopen(char(strcat([path,'/',num2str(fileNumber),'/acqp'])));acqpRead=textscan(fid,'%s','delimiter','\n');acqpRead=acqpRead{1};
% for index=1:size(acqpRead,1)
% 	testStr=char(acqpRead{index});
% 	if length(testStr)>10
% 		if strcmp(testStr(1:11),'##$ACQ_size')==1
% 			acqpReadFrames=str2num(acqpRead{index+1});
% 		end
% 	end
% end
% fclose(fid);
% NPro=acqpReadFrames(2)/NTE;

% NPro=15192; % overwrite readout to match gated number of projections

NPoints=ones(1,1);
fidpoints=ones(1,1);
for i=1:1
    NPoints(i)=101;
    fidpoints(i)=128;
end

NPShift = 20; % number of points shifted before gradient on;
rampoints=NPoints-84;

LeadingCutPro=zeros(1,1);
EndingCutPro=zeros(1,1);
% for i=1:44
% LeadingCutPro(i) =0;%number of leading spokes cut
% EndingCutPro(i)= 0;%number of ending spokes cut;
% end



% respMode = 'measured2';%synthesized means no data registration, only traj synthesization for ellip traj.
%RespMode='expiration';
RespMode='inspiration';
%RespMode='measured2';

for i=1:numel(fileNumber)
RealNPoints = NPoints(i) - NPShift;
RealNPro = NPro(i) - LeadingCutPro(i)- EndingCutPro(i);
realpath = fullfile(path,num2str(fileNumber(i)));
trajfilename = strcat('traj_',RespMode);
DCFfilename = strcat('DCF_',RespMode,'.raw');
% trajfilename = 'traj';
% DCFfilename = 'DCF.raw';

% load coordinates
 fid = fopen(fullfile(realpath,trajfilename));
 tmp = squeeze(fread(fid,inf, 'double'));
 fclose(fid);
%disp(size(tmp));disp(NPoints(i));disp(NPro(i));
 tmp = reshape(tmp,[3,NPoints(i),NPro(i)]);
 crds = tmp(:,1:RealNPoints,(LeadingCutPro(i)+1):NPro(i)-EndingCutPro(i));%cut ending points along one spoke;
 r = sqrt(crds(1,RealNPoints,:).^2 + crds(2,RealNPoints,:).^2 + crds(3,RealNPoints,:).^2);
 crds = crds./max(r(:))/2;
disp(['generating DCF for ',realpath]);

'   SDC params:'
numIter = 25;
effMtx  = (RealNPoints - rampoints(i)) * 2 * beta;
osf     = 2.1;
verbose = 1;

'   start SDC calc'
DCF = sdc3_MAT(crds,numIter,effMtx,verbose,osf);
DCF = single(DCF); % float32

'   write output DCF'
tmp = DCF;
fid = fopen(fullfile(realpath,DCFfilename),'w');
    fwrite(fid,tmp,'float32');
    fclose(fid);
clear tmp DCF crds r trajfilename DCFfilename;


disp(['Reconstructing ',realpath]);
grid3_multiTE(NPoints(i),NPro(i),rampoints(i),fidpoints(i),LeadingCutPro(i),EndingCutPro(i),NPShift,RespMode,realpath,beta,NTE);

end


