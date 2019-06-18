
global radius
radius=1.5;

Alignd = uigetdir(pwd, 'Select a folder with alignment .mat files');
nAlignd = uigetdir(pwd, 'Select a folder with no_alignment .mat files');

Afiles = dir(fullfile(strcat(Alignd,'/', '*.mat')));
NAfiles = dir(fullfile(strcat(nAlignd,'/', '*.mat')));

if size(Afiles,1)==size(NAfiles,1)
    Interference=cell(2,size(Afiles,1));
    for f=1:size(Afiles,1)        
        Interference{1,f}=getInter(strcat(Alignd,'/',Afiles(f).name));
        Interference{2,f}=getInter(strcat(nAlignd,'/',NAfiles(f).name));
    end
else
    disp('Number of parameter files do not match');
end




function out=getInter(varargin)

if (size(varargin,2)==0)
    [file, path] = uigetfile({'*.*'},'Select .mat file');
    data=load(strcat(path,file));
else
    data=load(varargin{1});
end
limits=data.limits;

Len = cellfun(@length, data.coverage, 'UniformOutput', false);
finalLength=min([Len{:}]);

timeStep=(data.Time/finalLength);
nPoses=size(data.poses.position,2);
nRuns=size(data.coverage,2);

x=0:timeStep:(data.Time);
% bottom=zeros(1,finalLength);
% top=zeros(1,finalLength);
% average=zeros(1,finalLength);
AvoidHits=zeros(finalLength,nPoses,nRuns);
Order=zeros(finalLength,nPoses,nRuns);

EvalHits=zeros(finalLength,nPoses,nRuns);
for rr=1:nRuns
    for pp=1:nPoses
        %        AvoidHits(:,pp,rr)=double([data.avoidState{1,rr,pp}(:).Data]);
        for tt=1:finalLength            
            %N=[];
            N=GetNeigbhours(cellfun(@(v)v(tt,:),data.poses.position(rr,:),'UniformOutput', false),pp);
            
            if sum(N)>1
                Order(tt,pp,rr)=EvalOrder(N,cellfun(@(v)v(tt,:),data.poses.orientation(rr,:),'UniformOutput', false));
                AvoidHits(tt,pp,rr)=1;
                EvalHits(tt,pp,rr)=AvoidHits(tt,pp,rr)*(1-Order(tt,pp,rr));
            else
                Order(tt,pp,rr)=0;%EvalOrder(N,cellfun(@(v)v(tt,:),data.poses.orientation(rr,:),'UniformOutput', false));
                AvoidHits(tt,pp,rr)=0;
                EvalHits(tt,pp,rr)=0;%AvoidHits(tt,pp,rr)*(1-Order(tt,pp,rr));
            end
        end
    end
end


while size(x,2)>finalLength
    x(:,size(x,2))=[];
end

rawHits=EvalHits;
threshold=0.2;
EvalHits(EvalHits>threshold)=1;
EvalHits(EvalHits<threshold)=0;

out=getCTs(EvalHits,timeStep);

end




%
%
%
%
%
%
%
%
%
%
%
%
%
% colour={'blue','red'};
% figure
% hold on
% set(gcf,'Position',[1000 1500 800 500])
% box on
% for ff=1:2
% data=load(strcat(path{ff},file{ff}));
%
% limits=data.limits;
%
%
%
%
%
% %close
% % hold on
% % box on
% %axis([0 x(1,size(x,2)) 0 200])
%
% meanAvoidTimes=mean(ct,3);
% average=mean(meanAvoidTimes,2)';
% sd=std(ct,0,3);
% top=average+sd;
% bottom=average-sd;
% %top=(max(meanAvoidTimes,[],2))';
% %bottom=(min(meanAvoidTimes,[],2))';
% % %
% %colour='blue';
% if strcmp(colour{ff},'red')
%     fillColour = [255,99,71] / 255;
%     MeanColour = [128,0,0] / 255;
%     a=0.2;
% elseif strcmp(colour{ff},'blue')
%     fillColour = [135,206,235] / 255;
%     MeanColour = [25,25,112] / 255;
%     a=0.5;
% elseif strcmp(colour{ff},'green')
%     fillColour = [34,139,34] / 255;
%     MeanColour = [85,107,47] / 255;
%     a=0.2;
% end
% %
% x2 = [x, fliplr(x)];
% inBetween = [bottom, fliplr(top)];
% s=fill(x2, inBetween,fillColour,'LineStyle','none');
% alpha(s,a);
% h(ff)=plot(x,average,'color',MeanColour,'Linewidth',2)
% xlabel('time [s]')
% ylabel('T(t)')
% set(gca,'FontSize',20)
% %hold off
% end
%%
function N=GetNeigbhours(poses,i)
    global radius
    d=zeros(1,size(poses,2));
    N=zeros(1,size(poses,2));
    for pp=1:size(d,2)       
        d(pp)=norm(poses{1,pp}-poses{1,i});        
    end
    N((d<=radius))=1;
end


function O=EvalOrder(N,qCell)
    Npos=find(N==1);
    if size(Npos,2)>1
        yaw=zeros(1,size(Npos,2));
        for y=1:size(yaw,2)
            qWXYZ=[qCell{Npos(y)}(4),qCell{Npos(y)}(1:3)];
            rpy=quat2eul(qWXYZ,'XYZ');
            yaw(y)=rpy(3);
        end
        O=norm(sum(exp(yaw.*1i)))/(size(yaw,2));
    else
        O=0;
    end   
end


function  CumulativeTimes=getCTs(EvalHits,timeStep)
    %finalLength=size(EvalHits,1);
    nPoses=size(EvalHits,2);
    nRuns=size(EvalHits,3);

    CumulativeTimes=zeros(size(EvalHits));
    for rr=1:nRuns
        for pp=1:nPoses

           CumulativeTimes(:,pp,rr)=cumsum(EvalHits(:,pp,rr)).*timeStep;

        end
    end    
end