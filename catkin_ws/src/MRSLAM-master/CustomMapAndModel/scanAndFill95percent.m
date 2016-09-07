function scanAndFill95percent()

    close all;
    
    %[x,y,theta]=MYpath();
    OdometryModel='OdometryMotion';
    THEIMAGE='Test5.png';
    [MAP,PIXDIM]=getTheMAP(THEIMAGE);
    SENSOR.RADIUS=50;           %Limit of the sensor
    SENSOR.AOS=[-90 90]*pi/180; %Sensor angle of sensitivity
    SENSOR.AOSDIV=180;          %Division of AOS, important for ray tracing
    phi=linspace(SENSOR.AOS(1),SENSOR.AOS(2),SENSOR.AOSDIV);
    
    figure(1)    
    NEWMAP=zeros(size(MAP));
    sNEWMAP=size(NEWMAP);
    
    STEPS=250;
    NROBOTS=5;
    
    
    x=zeros(STEPS,NROBOTS);
    y=zeros(STEPS,NROBOTS);
    theta=zeros(STEPS,NROBOTS);
    dt=0.1;
    
    R=diag([0.05,0.01]);
    Q=diag([0.5]);
     x(1,:)=[25 25 275 275 150];
     y(1,:)=[25 275 25 275 150];
    theta(1,:)=linspace(0,2*pi-2*pi/NROBOTS,NROBOTS);
    
    colours=lines(NROBOTS);
    
    c1=1;
    pcom=0;
    while (pcom<0.95)
        figure(1)
        hold off;
        for a1=1:NROBOTS
            %[r]=customMapMeasurement(x(c1,a1),y(c1,a1),theta(c1,a1),THEIMAGE,SENSOR);
            [r]=customMapMeasurement(x(c1,a1),y(c1,a1),theta(c1,a1),MAP,PIXDIM,SENSOR);
            
            
            if (~isempty(r))
                MU=[];
                for a2=1:numel(r)
                    MU=measurementToPosition([x(c1,a1);y(c1,a1);theta(c1,a1)],[r(a2);phi(a2)]);

                    MU=round(MU);
                    if (MU(1)<=0)
                        MU(1)=1;
                    end

                    if (MU(2)<=0)
                       MU(2)=1; 
                    end

                    if (sNEWMAP(1)<=MU(1))
                        MU(1)=sNEWMAP(1);
                    end

                    if (sNEWMAP(2)<=MU(2))
                       MU(2)=sNEWMAP(2); 
                    end
                    NEWMAP(MU(1),MU(2))=1;
                end
            end
            
            switch lower(OdometryModel)
                case 'odometrymotion'
                    [xnew,ynew,thetanew,dx,dtheta]=odometryMotion(x(c1,a1),y(c1,a1),theta(c1,a1),MAP,c1,a1);
                    data(a1).uact(:,c1)=[dx;dtheta];
                    data(a1).u(:,c1)=[dx+R(1,1)*randn(1);dtheta+R(2,2)*randn(1)];
                case 'velocitymotion'
                    [xnew,ynew,thetanew,v,omega]=velocityMotionModel(x(c1,a1),y(c1,a1),theta(c1,a1),MAP,c1,a1,dt);
                    data(a1).uact(:,c1)=[v;omega;dt];
                    data(a1).u(:,c1)=[v+R(1,1)*randn(1);omega+R(2,2)*randn(1);dt];
            end
                    
            data(a1).r{c1}=r;
            data(a1).r{c1}=r+Q(1,1)*randn(SENSOR.AOSDIV,1);        
            x(c1+1,a1)=xnew;
            y(c1+1,a1)=ynew;
            theta(c1+1,a1)=thetanew;
        end
        
        figure(1)
        imagesc(NEWMAP)
        colormap('gray')
        title(num2str(c1))
        axis image;
        hold on;
        if (c1>10)
            for a1=1:NROBOTS
                plot(y((c1-10):c1,a1),x((c1-10):c1,a1),'Color',colours(a1,:))
                plot(y(c1,a1),x(c1,a1),'o','Color',colours(a1,:))
            end
        else
            for a1=1:NROBOTS
                plot(y(1:c1,a1),x(1:c1,a1),'Color',colours(a1,:))
            end
        end
        drawnow;
        if (mod(c1,100)==0)
            fprintf('%d\n',c1);
        end
        c1=c1+1;
    end
end


function [xnew,ynew,thetanew,dx,dtheta]=odometryMotion(x,y,theta,MAP,a1,signum)


    signum=(-1)^signum;
    thetanew=theta;
    c1=1;
    multiplier=1;
    if (a1<50 | a1>500)
        multiplier=0;
    end
    
    while (true)
        dx=6;%5*rand+1;
        dtheta=multiplier*(-pi/12)+randn*pi/90;
        thetanew=thetanew+signum*dtheta;
        
        xnew=x+dx*cos(thetanew);
        ynew=y+dx*sin(thetanew);
        
        if (MAP(round(xnew),round(ynew))==0)
            break;
        else
            dtheta=-3*dtheta-2*randn*pi/90;
            thetanew=thetanew+signum*dtheta;
        end
        c1=c1+1;
        
    end

    dtheta=thetanew-theta;
    
end



function [xnew,ynew,thetanew,v,omega]=velocityMotionModel(x,y,theta,MAP,a1,signum,dt)


    signum=(-1)^signum;
    c1=1;
    multiplier=1;
    if (a1<25 | a1>2000)
        multiplier=0;
    end
    omega=0;
    
    while (true)
        v=100;%5*rand+1;
        omega=-signum*(multiplier*pi/24+(multiplier-1)*pi/90+randn(1)/75)+omega;
        dtheta=omega*dt;
        
        ds=v/omega;
        xnew=x+ds*(-sin(theta)+sin(theta+dtheta));
        ynew=y+ds*(cos(theta)-cos(theta+dtheta));
        thetanew=theta+dtheta;
        if (MAP(round(xnew),round(ynew))==0)
            break;
        end
        c1=c1+1;
    end 
end



function [x,y,theta]=MYpath()

    x=[];
    y=[];
    theta=[];
    
%     %Diagonal
%     x=[x linspace(950,10,1000)];
%     y=[y linspace(950,10,1000)];
%     theta=[theta linspace(-5*pi/4,-5*pi/4,1000)];
%     
%     
%     %Right
%     x=[x linspace(10,1000,1000)];
%     y=[y linspace(10,10,1000)];
%     theta=[theta linspace(0,0,1000)];

    theta=linspace(0,10*2*pi,1000);
    x=480+linspace(0,500,1000).*cos(theta);
    y=500+linspace(0,500,1000).*sin(theta);


end



function MU=measurementToPosition(STATE,Z)

    MU=STATE(1:2)+[Z(1)*cos(STATE(3)+Z(2));Z(1)*sin(STATE(3)+Z(2))];
end