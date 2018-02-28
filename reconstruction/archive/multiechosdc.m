function multiechosdc(fileName, fileNum, numProj)
    % MULTIECHOSDC Sampling density compensation for interleaved multi-TE UTE.
    % AUTHORS: Jinbang Guo, Matt Freeman, Alex Cochran
    
    addpath '/users/frend7/recon/sdc3_nrz_11aug/';
    addpath '/users/frend7/recon/grid3_dct_11aug/';
    addpath '/users/frend7/recon/MultiTE_Recon/';
    path=strcat(['/users/frend7/',fileName]);
    beta=1;

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

    RespMode='inspiration';

    for i=1:numel(fileNum)
        RealNPoints = NPoints(i) - NPShift;
        RealNPro = numProj(i) - LeadingCutPro(i)- EndingCutPro(i);
        realpath = fullfile(path,num2str(fileNum(i)));
        trajfilename = strcat('traj_',RespMode);
        DCFfilename = strcat('DCF_',RespMode,'.raw');

        % load coordinates
        fid = fopen(fullfile(realpath,trajfilename));
        tmp = squeeze(fread(fid,inf, 'double'));
        fclose(fid);
        tmp = reshape(tmp,[3,NPoints(i),numProj(i)]);
        crds = tmp(:,1:RealNPoints,(LeadingCutPro(i)+1):numProj(i)-EndingCutPro(i));%cut ending points along one spoke;
        r = sqrt(crds(1,RealNPoints,:).^2 + crds(2,RealNPoints,:).^2 + crds(3,RealNPoints,:).^2);
        crds = crds./max(r(:))/2;
        disp(['generating DCF for ',realpath]);

        %% SDC parameters
        numIter = 25;
        effMtx  = (RealNPoints - rampoints(i)) * 2 * beta;
        osf     = 2.1;
        verbose = 1;

        %% start SDC calculations
        DCF = sdc3_MAT(crds,numIter,effMtx,verbose,osf);
        DCF = single(DCF); % float32

        %% write output DCF
        tmp = DCF;
        fid = fopen(fullfile(realpath,DCFfilename),'w');
            fwrite(fid,tmp,'float32');
            fclose(fid);
        clear tmp DCF crds r trajfilename DCFfilename;


        disp(['Reconstructing ',realpath]);
        grid3_multiTE(NPoints(i),numProj(i),rampoints(i),fidpoints(i),LeadingCutPro(i),EndingCutPro(i),NPShift,RespMode,realpath,beta,NTE);
    end
end
