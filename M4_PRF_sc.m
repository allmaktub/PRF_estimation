
clear, close all, clc
%%  1:  Load physiological variables (heart rate and respiration) and global signal (GS) from MAT-File

%  Set the following parameters !!

sc = 140;     % choose a scan (sc) from 1-164

% -----------------------------------------

load('../Data/HCP_41_subjects_phys_GS.mat')

GS=GS_all(:,sc);  HR=HR_all(:,sc); resp=zscore(resp_all(:,sc));
Ts_10 = 0.1 ;                                                       % Sampling period in seconds
time_10 = 0:Ts_10:(length(HR)-1)*Ts_10;
timeMR = time_10(ind_BOLD_10);

figure('Position',[543         425        1588         792])
ax1 = subplot(3,1,1);
plot(time_10,HR)
title('Heart rate (HR)')
ylabel('HR (bpm)')

ax2 = subplot(3,1,2);
plot(time_10,resp)
title('Respiration')
ylabel('Amplitude (a.u.)')

ax3 = subplot(3,1,3);
plot(timeMR,GS);
title('Global signal (GS)')
ylabel('Amplitude (a.u.)')
xlabel('Time (s)')

linkaxes([ax1,ax2,ax3],'x')
xlim([0,max(time_10)])

%% 2: Estimate PRF parameters

resp_s = smooth(resp,10*1.5) ;
RF=diff(resp_s); RF=[0;RF(:)]; RF = RF.^2;

ga_opts = gaoptimset('TolFun',1e-10,'StallGenLimit',20,'Generations',100,'Display','iter','UseParallel',1);   % Display: iter
options = optimoptions('fmincon','Display','off','Algorithm','interior-point',...
    'UseParallel',true,'MaxIterations',100,'MaxFunctionEvaluations',3000,'OptimalityTolerance',1e-8,'PlotFcn','optimplotfval');    % 'PlotFcn','optimplotfval'

PRF_par = [  3.1    2.5   5.6    0.9    1.9   2.9   12.5    0.5 ];  
ub = PRF_par+3;
lb = PRF_par-3; lb(find(lb<0))=0;

h_train = @(P) func_M4_PRF_sc(P,Ts_10,HR,RF,ind_BOLD_10,GS,1);
% Uncomment the following line if you want to use  Genetic Algorithm
% (GA). GA may yield better fit with the cost of longer computational time.
% PRF_par = ga(h_train,length(ub),[],[],[],[],lb,ub,[],[],ga_opts);
PRF_par = fmincon(h_train,PRF_par,[],[],[],[],lb,ub,[],options);

h = @(P) func_M4_PRF_sc(P,Ts_10,HR,RF,ind_BOLD_10,GS,0);
[obj_function,CRF_sc,RRF_sc,HR_conv,RF_conv,r_PRF_sc,yPred, HR_conv_MR, RF_conv_MR] = h(PRF_par);

fprintf(' ----------------------------------------------- \n')
fprintf('Correlation b/w GS and PRF output \n')
fprintf('CRF (HR): %3.2f  \n',r_PRF_sc(2))
fprintf('RRF (RF): %3.2f  \n',r_PRF_sc(3))
fprintf('CRF & RRF (HR & RF): %3.2f  \n',r_PRF_sc(1))

%%  3: Plot output of PRF model (timeseries and PRF curves)  

%  Set the following parameters !!

smoothPar = 5;
fontTitle = 20;
fontLabels = 8;
fontTxt = 16;
lineW = 3;
yl1 = -5.3; yl2 = 5.5;

% -----------------------------------------

t_IR = 0:Ts_10:(length(CRF_sc)-1)*Ts_10;

screenSize = get(0,'ScreenSize'); xL = screenSize(3); yL = screenSize(4);
figure
set(gcf, 'Position', [0.2*xL 0.2*yL  0.6*xL 0.6*yL ]);
set(gcf, 'Position', [0.1*xL 0.1*yL  0.8*xL 0.8*yL ]);

ax1 = subplot(5,3,1:2);
plot(time_10,HR)
ylabel('HR (bpm)')
title(sprintf('Heart rate (HR; %2.0f±%1.0f bpm )',mean(HR),std(HR)))

ax6 = subplot(5,3,[3,6]);
plot(t_IR,CRF_sc,'LineWidth',4), grid on
title('Cardiac Response Function (CRF_{sc}) ')
xlabel('Time (s)'), ylabel('Amplitude (a.u.)')
xlim([0 60])

ax2 = subplot(5,3,4:5);
h1=plot(timeMR,smooth(GS,smoothPar),'LineWidth',lineW); hold on
h2=plot(time_10,HR_conv,'LineWidth', lineW);
legend([h1,h2],'Global signal', 'X_{HR}')
title('BOLD fluctuations due to changes in HR')
text(60, 4,  sprintf('r=%3.2f  ',  r_PRF_sc(2)) ,'FontSize',fontTxt,'FontWeight','bold')
ylabel('Amplitude (a.u.)')
ylim([yl1, yl2])
legend('boxoff')

ax3 = subplot(5,3,7:8);
h1=plot(timeMR,smooth(GS,smoothPar),'LineWidth',lineW); hold on
h2=plot(timeMR,yPred,'LineWidth',lineW);
title('Full model')
text(60, 4,  sprintf('r=%3.2f  ',  r_PRF_sc(1)) ,'FontSize',fontTxt,'FontWeight','bold')
ylabel('Amplitude (a.u.)')
legend([h1,h2],'Global signal','X_{FM}')
ylim([yl1, yl2])
legend('boxoff')

ax4 = subplot(5,3,10:11);
h1 = plot(timeMR,smooth(GS,smoothPar),'LineWidth',lineW); hold on
h2 = plot(time_10,RF_conv,'LineWidth',lineW);
title('BOLD fluctuations due to changes in respiration')
text(60, 4,  sprintf('r=%3.2f  ',  r_PRF_sc(3)) ,'FontSize',fontTxt,'FontWeight','bold')
legend([h1,h2],'Global signal','X_{RF}'), legend('boxoff')
ylabel('Amplitude (a.u.)')
ylim([yl1, yl2])

ax7 = subplot(5,3,[12,15]);
plot(t_IR,RRF_sc,'LineWidth',4), grid on
title('Respiration response function (RRF_{sc}) ')
xlim([0 60])
xlabel('Time (s)'), ylabel('Amplitude (a.u.)')

ax5 = subplot(5,3,13:14);
plot(time_10,RF,'LineWidth',1), hold on
title('Respiratory flow (RF)')
ylabel('RF (a.u.)')
ylim([-0.01 0.1])
xlabel('Time (s)')

linkaxes([ax1,ax2,ax3,ax4,ax5],'x')
xlim([timeMR(1) timeMR(end)])

ax_list = [ax1,ax2,ax3,ax4,ax5,ax6,ax7];
for ax=ax_list
    subplot(ax)
    ax.XGrid = 'on';
    ax.GridAlpha=0.7;
    ax.GridLineStyle='--';
    ax.FontSize = 17;
    ax.FontWeight = 'bold';    
end

%%   4: Create matrix of Physiological Regressors for the General linear Model 

xPhys = [HR_conv_MR,RF_conv_MR];  xPhys = detrend(xPhys,'linear');

figure('Position', [ 316         673        1849         483])
plot(timeMR(:), xPhys)
xlabel('Time (s)')
ylabel('Amplitude (a.u.)')
subject = scans_41_subjects{sc,1};
task = scans_41_subjects{sc,2};
title(sprintf('Physiological regressors to be included in the General Linear Model for scan %s (%s) ', subject, task),'Interpreter','none')











