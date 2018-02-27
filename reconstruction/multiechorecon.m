function multiechorecon(numPoints, numProj, ramPoints, FIDPoints, leadCutProj, ...
        endCutProj, NPShift, respMode, path, NTE)
    %   MULTIECHORECON Reconstruct multi-echo image acquisitions.
    %   AUTHORS: Jinbang Guo, Alex Cochran.
    
    % alpha=max([beta 1.375]); %gridding oversampling ratio.
    alpha=2;

    RealNPoints = numPoints - NPShift; % actual number of points encoded;
    RealNPro = numProj - leadCutProj - endCutProj;

    trajFilename = strcat('traj_', respMode);
    DCFfilename = strcat('DCF_',RespMode,'.raw');
    fidname = strcat('fid_',RespMode);
    imagefilename = strcat('img_',RespMode,'.raw');

    fid = fopen(fullfile(path,trajFilename));
    tmp = squeeze(fread(fid,inf,'double'));
    fclose(fid);
    tmp = reshape(tmp,[3,numPoints,numProj]);
    crds = tmp(:,1:RealNPoints,(leadCutProj+1):numProj-endCutProj);
    r = sqrt(crds(1,RealNPoints,:).^2 + crds(2,RealNPoints,:).^2 + crds(3,RealNPoints,:).^2);
    crds = crds./max(r(:))/2;
    clear tmp r;

    
    %% read pre-weights
    
    fid = fopen(fullfile(path,DCFfilename));
    tmp = squeeze(fread(fid,inf,'float32'));
    fclose(fid);
    DCF = reshape(tmp,[RealNPoints,RealNPro]);
    clear tmp;


    %% read k-space information
    
    fid = fopen(fullfile(path,fidname));
    tmp = squeeze(fread(fid,inf,'int32'));%step-like scaling depending on SW_h.
    fclose(fid);
    Alldata = reshape(tmp,[2,FIDPoints,NTE,numProj]);
    clear tmp;

    
    %% iterate over all TEs
    for nte=1:NTE

        data = squeeze(Alldata(:,(NPShift +1):numPoints,nte,(leadCutProj+1):(numProj-endCutProj)));
        

        %% grid3 parameters

        effMtx    = (RealNPoints - ramPoints) * 2* alpha;
        numThread = 1; % no pthread lib exec

        
        %% grid3 calculation
        
        gdata = grid3_MAT(data,crds,DCF,effMtx,numThread);
        clear data numThread;

        
        %% make roll-off kernel
        
        delta = [1.0, 0.0];
        k_not = [0.0, 0.0, 0.0];
        DCF_not   = 1.0;
        numThread = 1; % only have 1 data point
        rokern = grid3_MAT(delta',k_not',DCF_not,effMtx,numThread);

        clear delta k_not DCF_not numThread;

        
        %% fft into image-space
        
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

        
        %% apply roll-off and crop
        
        gdata(rokern > 0) = gdata(rokern > 0) ./ rokern(rokern > 0);
        xs = floor(effMtx/2 - effMtx/2/alpha)+1;
        xe = floor(effMtx/2 + effMtx/2/alpha);
        gdata = gdata(xs:xe,xs:xe,xs:xe);
        gdata = single(abs(gdata)); % magnitude, float32

        
        %% write output to file
        
        tmp = rot90(gdata,2);
        fid = fopen(fullfile(path,imagefilename),'w');
        fwrite(fid,tmp,'float32');
        fclose(fid);
    end
end