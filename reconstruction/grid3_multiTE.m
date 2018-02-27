%%Author: Jinbang Guo; image reconstruction for data from
%%RetroGatingGenLeadPhase.m.
function grid3_multiTE(NPoints,NPro,rampoints,fidpoints,LeadingCutPro,EndingCutPro,NPShift,RespMode,path,beta,NTE)

% alpha=max([beta 1.375]); %gridding oversampling ratio.
alpha=2;

RealNPoints = NPoints - NPShift; % actual number of points encoded;
RealNPro = NPro - LeadingCutPro - EndingCutPro;

trajfilename = strcat('traj_',RespMode);
DCFfilename = strcat('DCF_',RespMode,'.raw');
fidname = strcat('fid_',RespMode);
% imagefilename = strcat('img_TE','.raw');
imagefilename = strcat('img_',RespMode,'.raw');

% trajfilename = 'traj';
% DCFfilename = 'DCF.raw';
% fidname = 'fid';
% imagefilename='img.raw';

fid = fopen(fullfile(path,trajfilename));
tmp = squeeze(fread(fid,inf,'double'));
fclose(fid);
tmp = reshape(tmp,[3,NPoints,NPro]);
crds = tmp(:,1:RealNPoints,(LeadingCutPro+1):NPro-EndingCutPro);
r = sqrt(crds(1,RealNPoints,:).^2 + crds(2,RealNPoints,:).^2 + crds(3,RealNPoints,:).^2);
crds = crds./max(r(:))/2;
clear tmp r;

'   read pre-weights'
fid = fopen(fullfile(path,DCFfilename));
tmp = squeeze(fread(fid,inf,'float32'));
fclose(fid);
DCF = reshape(tmp,[RealNPoints,RealNPro]);
clear tmp;

% NTE=1;
'   read k-space data'
fid = fopen(fullfile(path,fidname));
tmp = squeeze(fread(fid,inf,'int32'));%step-like scaling depending on SW_h.
fclose(fid);
% disp(size(tmp));disp(fidpoints);disp(NTE);disp(NPro);
Alldata = reshape(tmp,[2,fidpoints,NTE,NPro]);
clear tmp;



for nte=1:NTE

data = squeeze(Alldata(:,(NPShift +1):NPoints,nte,(LeadingCutPro+1):(NPro-EndingCutPro)));

'   Grid3 params:'

effMtx    = (RealNPoints - rampoints) * 2* alpha;
% numThread = 8   % or 1 for no pthread lib exec
numThread = 1;

'   start Grid3 calc'
gdata = grid3_MAT(data,crds,DCF,effMtx,numThread);
clear data numThread;

'   make a rolloff kernel'
delta = [1.0, 0.0];
k_not = [0.0, 0.0, 0.0];
DCF_not   = 1.0;
numThread = 1; % only have 1 data point
rokern = grid3_MAT(delta',k_not',DCF_not,effMtx,numThread);

clear delta k_not DCF_not numThread;

'   fft into image space'
% DATA
% change to complex, fft, then shift
gdata = squeeze(gdata(1,:,:,:) + 1j*gdata(2,:,:,:));
gdata = fftn(gdata);
gdata = fftshift(gdata,1);
gdata = fftshift(gdata,2);
gdata = fftshift(gdata,3);

% ROLLOFF
% change to complex, shift, then fft
rokern = squeeze(rokern(1,:,:,:) + 1j*rokern(2,:,:,:));
rokern = fftn(rokern);
rokern = fftshift(rokern,1);
rokern = fftshift(rokern,2);
rokern = fftshift(rokern,3);
rokern = abs(rokern);

'   apply rolloff and crop'
gdata(rokern > 0) = gdata(rokern > 0) ./ rokern(rokern > 0);
xs = floor(effMtx/2 - effMtx/2/alpha)+1;
xe = floor(effMtx/2 + effMtx/2/alpha);
gdata = gdata(xs:xe,xs:xe,xs:xe);
% img_r=real(gdata);
% img_i=imag(gdata);
% save(fullfile(path,strcat('image_TE',num2str(nte),'.mat')),'gdata');
gdata = single(abs(gdata)); % magnitude, float32

'   write output file'
tmp = rot90(gdata,2);
% fid = fopen(fullfile(path,strcat(imagefilename,num2str(nte))),'w');
fid = fopen(fullfile(path,imagefilename),'w');
fwrite(fid,tmp,'float32');
fclose(fid);

% fid=fopen(fullfile(path,strcat('image_r',num2str(nte),'.raw')),'w');
% fwrite(fid,img_r,'float32');
% fclose(fid);
% fid=fopen(fullfile(path,strcat('image_i',num2str(nte),'.raw')),'w');
% fwrite(fid,img_i,'float32');
% fclose(fid);
% end

end

end

