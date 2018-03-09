function ReadTextData(fileName,fileNumber,NTE)
% path = '/home/jinbang/ReconMethod/20160112raw';
% path = '/users/frend7/20160906_093109_IRC272A_MF_DoxyMice_1_1';
path=strcat(['/users/frend7/',fileName]);
% fileNumber=16;
% NPointsarray=101;
NPointsarray=zeros(1,1);
for i=1:1
    NPointsarray(i)=101;
end
% NPro=51472;
% NPro=17734;
% NPro=29556;
% NPro=11376;
%NPro=17734;

fid=fopen(char(strcat([path,'/',num2str(fileNumber),'/acqp'])));
acqpRead=textscan(fid,'%s','delimiter','\n');acqpRead=acqpRead{1};
for index=1:size(acqpRead,1)
	testStr=char(acqpRead{index});
	if length(testStr)>10
		if strcmp(testStr(1:11),'##$ACQ_size')==1
			acqpReadFrames=str2num(acqpRead{index+1});
		end
	end
end
fclose(fid);
NPro=acqpReadFrames(2)/NTE;

NPro=15192;

% Interleaves=13;% for keyhole trajectory
Interleaves=13;
for k=1:numel(fileNumber)
    realpath=fullfile(path,num2str(fileNumber(k)));
fid = fopen(fullfile(realpath,'method'));
trajmode='goldmean';% goldmean for golden mean traj, keyhole for keyhole trajectory.
line=fgetl(fid);

NPoints=NPointsarray(k);

phi=[0.46557123 0.68232780];% for 2D golden mean trajectory;
% linenum=1;
% disp([num2str(linenum) ',' line]);

while(~strcmp(strtok(line,'='),'##$PVM_TrajKx')) 
line=fgetl(fid);
end
TrajKx=zeros(NPoints,1);
KxCount=0;
while(~strcmp(strtok(line,'='),'##$PVM_TrajKy'))
line=fgetl(fid);
temp=(str2num(line))';
TrajKx(KxCount+1:size(temp,1)+KxCount)=temp;
KxCount=KxCount+size(temp,1);
end;
TrajKy=zeros(NPoints,1);
KyCount=0;
while(~strcmp(strtok(line,'='),'##$PVM_TrajKz'))
line=fgetl(fid);
temp=(str2num(line))';
TrajKy(KyCount+1:size(temp,1)+KyCount)=temp;
KyCount=KyCount+size(temp,1);
end;
TrajKz=zeros(NPoints,1);
KzCount=0;
while(~strcmp(strtok(line,'='),'##$PVM_TrajBx'))
line=fgetl(fid);
temp=(str2num(line))';
TrajKz(KzCount+1:size(temp,1)+KzCount)=temp;
KzCount=KzCount+size(temp,1);
end;
fclose(fid);

maxkx=max(TrajKx);
maxky=max(TrajKy);
maxkz=max(TrajKz);

if strcmp(trajmode,'keyhole')
nviews=NPro;
keys=Interleaves;
halfnviews=int32((nviews-1)/2);
keyviews=nviews/keys;
sf=int32((keyviews-1)/2);
primeplus=203;
r=zeros(nviews,1);
p=zeros(nviews,1);
s=zeros(nviews,1);
fl=-1;
grad_indx=0;
for j=0:(keys-1)
    for i=1:keyviews
        indx=j+(i-1)*keys;
        f=1-double(indx)/double(halfnviews);
        if(f<-1)
            f=-1;
        end
        ang=primeplus*indx*pi/180;
        d=sqrt(1-f*f);
        grad_indx=grad_indx+1;
        r(grad_indx)=d*cos(ang);
        p(grad_indx)=d*sin(ang);
        if(i<=sf)
            s(grad_indx)=sqrt(1-d*d);
        else
            s(grad_indx)=fl*sqrt(1-d*d);
        end
    end
end
else
    nviews=NPro;
    halfnviews=nviews/2;
    r=zeros(nviews,1);
    p=zeros(nviews,1);
    s=zeros(nviews,1);
%     for i=1:halfnviews
%         s(i)=mod((i-1)*phi(1),1);
%         s(i+halfnviews)=-s(i);
%         alpha=2*pi*mod((i-1)*phi(2),1);
%         d=sqrt(1-s(i)^2);
%         r(i)=d*cos(alpha);
%         r(i+halfnviews)=-r(i);
%         p(i)=d*sin(alpha);
%         p(i+halfnviews)=-p(i);
%     end
    for i=1:nviews
        s(i)=2*mod((i-1)*phi(1),1)-1;
        alpha=2*pi*mod((i-1)*phi(2),1);
        d=sqrt(1-s(i)^2);
        r(i)=d*cos(alpha);
        p(i)=d*sin(alpha);
    end
end

% TrajKx=TrajKx/maxkx/2;
% TrajKy=TrajKy/maxky/2;
% TrajKz=TrajKz/maxkz/2;

trajectory=zeros(3,NPoints,nviews);
for i=1:nviews
    trajectory(1,:,i)=r(i)*TrajKx;
    trajectory(2,:,i)=p(i)*TrajKy;
    trajectory(3,:,i)=s(i)*TrajKz;
end

fid = fopen(fullfile(realpath,'traj_measured2'),'w');
fwrite(fid,trajectory,'double');
fclose(fid);
end
clear all;


        




