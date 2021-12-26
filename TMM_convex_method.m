function [target,modelPara] = TMM_convex_method(GQstep,CQstep,Geo_Bits,Col_Bits,MSE,targetRate)
% -----------------------------------------------------------------------------------
% input:
% GQstep: 1 x 3 vector Ԥ����ļ�����������
% CQstep: 1 x 3 vector Ԥ�����������������
% Geo_Bits: 1 x 3 vector Ԥ����ļ��α���(bits per million points)
% Col_Bits: 1 x 3 vector Ԥ��������Ա���(bits per million points)
% MSE: 1 x 3 vector Ԥ�����ʧ�� ��ɫ�ͼ���ʧ���ܺ� normal
% targetRange: ������Ŀ�����ʵ����� eg. targetRange = linspace(62000,690000,315)
% -----------------------------------------------------------------------------------
% output:
% target: m x n vector ÿһ�б�ʾ Ŀ������ Ŀ��QP Ŀ����������
% modelPara: 1 x 4 vector ģ�Ͳ��� ˳��Ϊa b c d
% -----------------------------------------------------------------------------------
target = [];
QP=[22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42];
Qstep=[8 9 10 11.25 12.75 14.25 16 18 20 22.5 25.5 28.5 32 36 40 45 51 57 64 72 80];
Model_GQstep=Qstep;
Model_CQstep=Qstep;
clear g c;
%%%%% %�ⷽ��
%Alex��Geo_R=a*power(GQstep,b) ʹ��(28.5,11.25),(32,36)��
geo_p=[28.5 Geo_Bits(1)
    32 Geo_Bits(2)];
geo_x0=[300000,-1];
option=optimset('MaxIter',100000,'MaxFunEvals',1000000);
%geo_x(1)��Ӧ����a;geo_x(2)��Ӧ����b.
[geo_x,geo_fval,geo_exitflag,geo_output]=fsolve(@(x)seperateratefun(x,geo_p),geo_x0,option);

%Alex��Col_R=c*power(CQstep,d) ʹ��(28.5,11.25),(32,36)��
col_p=[11.25 Col_Bits(1)
    36 Col_Bits(2)];
col_x0=[10000000,-2];
option=optimset('MaxIter',100000,'MaxFunEvals',1000000);
%col_x(1)��Ӧ����c;col_x(2)��Ӧ����d.
[col_x,col_fval,col_exitflag,col_output]=fsolve(@(x)seperateratefun(x,col_p),col_x0,option);

%Alex��D=d*GQstep+e*CQstep+fʹ��(28.5,11.25),(32,36),(10,28.5),
syms d e f d1 d2 d3;
d1=MSE(1);
d2=MSE(2);
d3=MSE(3);
equ4=d*28.5+e*11.25+f-d1;
equ5=d*32+e*36+f-d2;
equ6=d*10+e*28.5+f-d3;
[d,e,f]=solve(equ4,equ5,equ6);
d=vpa(d);
e=vpa(e);
f=vpa(f);
%%%%% %�ⷽ��
modelPara = [geo_x(1)  geo_x(2) col_x(1) col_x(2) d e f]; %Geo_R=a*power(GQstep,b) ; Col_R=c*power(CQstep,d); D=d*GQstep+e*CQstep+f
%Model data optimal convex operation with Interior-point
for j = 1 : length(targetRate)
    options = optimoptions('fmincon','Algorithm','interior-point', 'MaxIter',1000000, 'MaxFunEvals',1000000);
    A_value=[]; b_value=[];Aeq=[];beq=[];lb=[8,8];ub=[80,80];
    n=[geo_x(1),geo_x(2),col_x(1),col_x(2),targetRate(j)];
    m=[double(d),double(e),double(f)];
    %x(1)��ʾGeometry Qstep;x(2)��ʾColor Qstep.
    [x,fval,exitflag] = fmincon(@(x) fmincon_dis(x,m),[8,8],A_value,b_value,Aeq,beq,lb,ub,@(x) fmincon_rate(x,n),options); %x(1)��ʾGQstep��x(2)��ʾCQstep
    %�ҵ���ɢ�ģ�GQstep,CQstep)�������ŵ㣨x(1),x(2))����ĵ���Ϊ���ŵ�
    %��ʼ�����ŵ�ĳ�ʼֵ
    min_dis=sqrt(power((80-8),2)+power((80-8),2));
    convex_GQstep=0;
    convex_CQstep=0;
    for GQstep_index=1:21
        for CQstep_index=1:21
            if sqrt(power((Model_GQstep(GQstep_index)-x(1)),2)+power((Model_CQstep(CQstep_index)-x(2)),2))<=min_dis
                min_dis=sqrt(power((Model_GQstep(GQstep_index)-x(1)),2)+power((Model_CQstep(CQstep_index)-x(2)),2));
                convex_GQstep=Model_GQstep(GQstep_index);
                convex_CQstep=Model_CQstep(CQstep_index);
            end
        end
    end
    % �˴���ÿ��target rate�õ��ļ��� ��������������Ϣ�����Ž���� �ɲο�����ĸ�ʽ
    g_i=find(Qstep==convex_GQstep);
    gQP=QP(g_i);
    c_i=find(Qstep==convex_CQstep);
    cQP=QP(c_i);
    temp= [targetRate(j), gQP, cQP]; %������
    target = [target; temp]; %���в��뵽�����
    clear g_i gQP c_i cQP convex_GQstep convex_CQstep;
end
clear Model_GQstep Model_CQstep n m x convex_CQstep convex_GQstep;