function minkowski_view
%% ============================================================
%  Interactive Minkowski diagram
%
%  本次改动:
%   1. 光锥上再加 (ct=3,x=3) 和 (ct=3,x=-3), 并画出 ct=3 横线
%   2. 黄/绿参考系刻度点使用各自参考系内的整数 1,2,3,
%      经正确洛伦兹变换画到 view 系 (ct_view 随视角连续变化)
%   3. 双曲线等值线 s = 0.5,1,1.5,2,2.5,3 (过 ct 轴上的 1,2,3)
% =============================================================

clc; close all;

%% 1. 参考系参数
beta_K  = 0.00;  beta_K1 = 0.30;  beta_Kp = 0.60;
eta_K   = atanh(beta_K);
eta_K1  = atanh(beta_K1);
eta_Kp  = atanh(beta_Kp);

color_K  = [0.12 0.40 0.80];
color_K1 = [0.90 0.45 0.10];
color_Kp = [0.15 0.60 0.35];

%% 2. 紫色参考点 (K 系下的 [ct, x])
lightPoints_K = [
    1   1;    % L+ 上
    2   2;    % L+ 上
    3   3;    % L+ 上  (新增)
    1  -1;    % L- 上
    2  -2;    % L- 上
    3  -3     % L- 上  (新增)
];

%% 3. 轴刻度值
axisValues = [1 2 3];

%% 4. 画布
fig = figure('Color','w','Position',[150 80 1050 820], ...
             'Name','Minkowski coordinate viewpoint');

ax = axes('Parent',fig,'Position',[0.10 0.13 0.82 0.78]);
hold(ax,'on'); axis(ax,'equal');
xlim(ax,[-3.8 3.8]);
ylim(ax,[-0.5 4.2]);
set(ax,'FontName','Times New Roman','FontSize',14, ...
       'LineWidth',1.0,'TickLabelInterpreter','latex');
xlabel(ax,'$x_{\rm view}$','Interpreter','latex', ...
       'FontName','Times New Roman','FontSize',19);
ylabel(ax,'$ct_{\rm view}$','Interpreter','latex', ...
       'FontName','Times New Roman','FontSize',19);

%% 5. 滑块
slider = uicontrol('Parent',fig,'Style','slider', ...
    'Units','normalized','Position',[0.30 0.055 0.43 0.025], ...
    'Min',-0.999,'Max',0.999,'Value',0.0, ...
    'SliderStep',[0.005 0.05],'Callback',@updatePlot);

uicontrol('Parent',fig,'Style','text', ...
    'Units','normalized','Position',[0.275 0.015 0.04 0.025], ...
    'String','-1','FontName','Times New Roman','FontSize',13, ...
    'BackgroundColor','w');
uicontrol('Parent',fig,'Style','text', ...
    'Units','normalized','Position',[0.725 0.015 0.04 0.025], ...
    'String','+1','FontName','Times New Roman','FontSize',13, ...
    'BackgroundColor','w');

%% 6. 首次绘制
updatePlot();

%% ============================================================
%  嵌套函数
% ============================================================

    function updatePlot(~,~)
        beta_view = get(slider,'Value');
        eta_view  = atanh(beta_view);
        ch = cosh(eta_view);
        sh = sinh(eta_view);

        cla(ax); hold(ax,'on'); axis(ax,'equal');
        xlim(ax,[-3.8 3.8]);
        ylim(ax,[-0.5 4.2]);

        %% A. 不变量双曲线
        %   类时: ct^2 - x^2 = s^2   (U 形上下两支, 过 ct 轴 ±s)
        %   类空: x^2 - ct^2 = s^2   (C 形左右两支, 过 x 轴 ±s)
        gridCol = [0.82 0.87 0.93];

        xh  = linspace(-3.7, 3.7, 1000);   % 用于类时双曲线的 x 采样
        cth = linspace(-0.5, 4.2, 1000);   % 用于类空双曲线的 ct 采样

        for s = [0.5 1 1.5 2 2.5 3]

            % ---- 类时双曲线: ct = ±sqrt(x^2 + s^2) ----
            plot(ax, xh,  sqrt(xh.^2 + s^2), 'Color',gridCol,'LineWidth',1.0);
            plot(ax, xh, -sqrt(xh.^2 + s^2), 'Color',gridCol,'LineWidth',1.0);

            % ---- 类空双曲线: x = ±sqrt(ct^2 + s^2) ----
            plot(ax,  sqrt(cth.^2 + s^2), cth, 'Color',gridCol,'LineWidth',1.0);
            plot(ax, -sqrt(cth.^2 + s^2), cth, 'Color',gridCol,'LineWidth',1.0);
        end
        
        %% B. 光锥
        L = 4.0;
        lightColor = [0.55 0.30 0.72];
        plot(ax,[-L L],[L -L],'--','Color',lightColor,'LineWidth',1.7);
        plot(ax,[-L L],[-L L],'--','Color',lightColor,'LineWidth',1.7);

        %% C. 三个参考系
        drawFrame(eta_K,  'K',       '',   color_K,  eta_view, axisValues);
        drawFrame(eta_K1, 'K_1',     '1',  color_K1, eta_view, axisValues);
        drawFrame(eta_Kp, 'K^\prime','''', color_Kp, eta_view, axisValues);

        %% D. 紫色点 + 同 ct 横线 (随视角旋转)
        Np = size(lightPoints_K,1);
        ptsView = zeros(Np,2);
        for i = 1:Np
            ct = lightPoints_K(i,1);
            x  = lightPoints_K(i,2);
            ptsView(i,1) = -sh*ct + ch*x;   % x_view
            ptsView(i,2) =  ch*ct - sh*x;   % ct_view
        end

        % 同 ct 或同 x 的两点连紫色虚线
        for i = 1:Np-1
            for j = i+1:Np
                sameCt = abs(lightPoints_K(i,1) - lightPoints_K(j,1)) < 1e-9;
                sameX  = abs(lightPoints_K(i,2) - lightPoints_K(j,2)) < 1e-9;
                if sameCt || sameX
                    plot(ax, ...
                        [ptsView(i,1) ptsView(j,1)], ...
                        [ptsView(i,2) ptsView(j,2)], ...
                        '--','Color',lightColor,'LineWidth',1.6);
                end
            end
        end

        % 紫色菱形点
        for i = 1:Np
            plot(ax, ptsView(i,1), ptsView(i,2), 'd', ...
                 'MarkerSize',9,'MarkerFaceColor',lightColor, ...
                 'MarkerEdgeColor','w','LineWidth',0.8);
        end

        %% E. 光锥标签
        text(ax, 3.05,3.20,'$L_{+}$','Interpreter','latex', ...
            'FontName','Times New Roman','FontSize',16,'Color',lightColor);
        text(ax,-3.15,3.20,'$L_{-}$','Interpreter','latex', ...
            'FontName','Times New Roman','FontSize',16,'Color',lightColor);

        %% F. 视角坐标轴 (始终水平/垂直)
        currentColor = [0.12 0.12 0.12];
        plot(ax,[-3.8 3.8],[0 0],'-','Color',currentColor,'LineWidth',2.8);
        plot(ax,[0 0],[-0.5 4.2],'-','Color',currentColor,'LineWidth',2.8);

        %% G. 标题
        if abs(beta_view-beta_K) < 0.025
            currentName = '$K$';
        elseif abs(beta_view-beta_K1) < 0.025
            currentName = '$K_1$';
        elseif abs(beta_view-beta_Kp) < 0.025
            currentName = '$K^\prime$';
        else
            currentName = '$K_{\rm view}$';
        end
        title(ax,['Current coordinate view: ' currentName], ...
              'Interpreter','latex','FontName','Times New Roman', ...
              'FontSize',20,'FontWeight','normal');

        %% H. beta_view 数值 (LaTeX)
        text(ax, -3.68, -0.40, ...
             sprintf('$\\beta_{\\rm view}=%.3f$', beta_view), ...
             'Interpreter','latex','FontName','Times New Roman', ...
             'FontSize',16,'Color','k');

        drawnow;
    end

    % --------------------------------------------------------
    %  drawFrame: 主轴 + 刻度 (正确洛伦兹变换)
    %
    %  K_j 系里 ct_j=a, x_j=0 的点  --->  view 系
    %       (x_view, ct_view) = (sinh(Δη)·a, cosh(Δη)·a)
    %  K_j 系里 ct_j=0, x_j=a 的点  --->  view 系
    %       (x_view, ct_view) = (cosh(Δη)·a, sinh(Δη)·a)
    %
    %  其中 Δη = η_j − η_view.
    %  这就是为什么 ct_view 会随 β_view 连续变化, 不再固定为 a.
    % --------------------------------------------------------
    function drawFrame(etaFrame, namePlain, suffix, col, eta_view, axisValues)

        deltaEta     = etaFrame - eta_view;
        sh           = sinh(deltaEta);
        ch           = cosh(deltaEta);
        betaRelative = tanh(deltaEta);

        % ---- 两条主轴 ----
        ctAxis = linspace(-4,4,400);
        plot(ax, betaRelative.*ctAxis, ctAxis, '-', ...
             'Color',col,'LineWidth',2.4);

        xAxis = linspace(-3.8,3.8,400);
        plot(ax, xAxis, betaRelative.*xAxis, '-', ...
             'Color',col,'LineWidth',2.4);

        % ---- 刻度标记 (正确洛伦兹变换) ----
        for q = 1:length(axisValues)
            a = axisValues(q);

            % ct_j 轴上点: (x_j,ct_j) = (0,a)
            plot(ax, sh*a, ch*a, 'o','MarkerSize',7, ...
                 'MarkerFaceColor',col,'MarkerEdgeColor','w');

            % x_j 轴上点: (x_j,ct_j) = (a,0)
            plot(ax, ch*a, sh*a, 's','MarkerSize',7, ...
                 'MarkerFaceColor',col,'MarkerEdgeColor','w');
        end

        % ---- 轴标签 ----
        text(ax, betaRelative*3.45 + 0.05, 3.45, ...
             ['$ct_{' suffix '}$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',16,'Color',col);
        text(ax, 3.15, betaRelative*3.15 + 0.05, ...
             ['$x_{' suffix '}$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',16,'Color',col);

        % ---- 参考系名字 ----
        text(ax, 0.10, 0.10 + 0.16*(abs(etaFrame)/0.7), ...
             ['$' namePlain '$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',15,'Color',col);
    end

end