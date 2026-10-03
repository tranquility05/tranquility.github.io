function galileo_view
%% ============================================================
%  Interactive Galilean diagram
%
%  与洛伦兹版本相同布局, 但使用伽利略变换:
%      ct_view = ct
%      x_view  = x - beta_view * ct
%
%  伽利略的核心特点:
%    * 时间绝对  ->  同 ct 的紫线永远水平 (同时绝对)
%    * 空间轴全部重合于 ct_view = 0 (所有参考系共享同时面)
%    * ct_j 轴的斜率 = beta_j - beta_view (线性叠加)
%    * 光锥不再是不变结构, 但作为视觉参考仍保留
% =============================================================

clc; close all;

%% 1. 参考系参数
beta_K  = 0.00;  beta_K1 = 0.30;  beta_Kp = 0.60;

color_K  = [0.12 0.40 0.80];
color_K1 = [0.90 0.45 0.10];
color_Kp = [0.15 0.60 0.35];

%% 2. 紫色参考点 (K 系下的 [ct, x])
lightPoints_K = [
    1   1;
    2   2;
    3   3;
    1  -1;
    2  -2;
    3  -3
];

%% 3. 轴刻度值
axisValues = [1 2 3];

%% 4. 画布
fig = figure('Color','w','Position',[150 80 1050 820], ...
             'Name','Galilean coordinate viewpoint');

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

        cla(ax); hold(ax,'on'); axis(ax,'equal');
        xlim(ax,[-3.8 3.8]);
        ylim(ax,[-0.5 4.2]);

        %% A. 双曲线背景 (与洛伦兹版视觉一致)
        gridCol = [0.82 0.87 0.93];
        xh  = linspace(-3.7, 3.7, 1000);
        cth = linspace(-0.5, 4.2, 1000);
        for s = [0.5 1 1.5 2 2.5 3]
            plot(ax, xh,  sqrt(xh.^2+s^2), 'Color',gridCol,'LineWidth',1.0);
            plot(ax, xh, -sqrt(xh.^2+s^2), 'Color',gridCol,'LineWidth',1.0);
            plot(ax,  sqrt(cth.^2+s^2), cth, 'Color',gridCol,'LineWidth',1.0);
            plot(ax, -sqrt(cth.^2+s^2), cth, 'Color',gridCol,'LineWidth',1.0);
        end

        %% B. 光锥 (视觉参考)
        L = 4.0;
        lightColor = [0.55 0.30 0.72];
        plot(ax,[-L L],[L -L],'--','Color',lightColor,'LineWidth',1.7);
        plot(ax,[-L L],[-L L],'--','Color',lightColor,'LineWidth',1.7);

        %% C. 三个参考系 (伽利略)
        % 先画三个参考系 (x 轴重合), 最后画视角轴, 保证黑轴在上
        drawFrame(beta_K,  'K',       '',   color_K,  beta_view, axisValues, 0.05);
        drawFrame(beta_K1, 'K_1',     '1',  color_K1, beta_view, axisValues, 0.15);
        drawFrame(beta_Kp, 'K^\prime','''', color_Kp, beta_view, axisValues, 0.25);

        %% D. 紫色点 (伽利略变换) + 同 ct / 同 x 虚线
        Np = size(lightPoints_K,1);
        ptsView = zeros(Np,2);
        for i = 1:Np
            ct = lightPoints_K(i,1);
            x  = lightPoints_K(i,2);
            ptsView(i,1) = x - beta_view*ct;   % x_view
            ptsView(i,2) = ct;                 % ct_view
        end

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
        title(ax,['Current coordinate view (Galilean): ' currentName], ...
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
    %  drawFrame (伽利略版)
    %
    %  K_j 相对于 K 运动速度为 beta_j.
    %  在视角系中相对速度:   u = beta_j - beta_view
    %
    %  ct_j 轴:  x_view = u * ct_view       (直线, 过原点)
    %  x_j  轴:  ct_view = 0                (与水平轴重合)
    %
    %  刻度:
    %    (x_j,ct_j) = (0, a)  ->  (x_view, ct_view) = (u*a, a)
    %    (x_j,ct_j) = (a, 0)  ->  (x_view, ct_view) = (a,   0)
    % --------------------------------------------------------
    function drawFrame(betaFrame, namePlain, suffix, col, beta_view, ...
                       axisValues, yLabelOffset)

        u = betaFrame - beta_view;

        % ---- ct_j 轴 ----
        ctAxis = linspace(-4,4,400);
        plot(ax, u.*ctAxis, ctAxis, '-', 'Color',col,'LineWidth',2.4);

        % ---- x_j 轴 (与水平轴重合, 只画在水平轴附近一小段)
        %      用略粗的短线段表示, 避免遮住视角轴
        plot(ax, [-3.8 3.8], [0 0], '-', 'Color',col, 'LineWidth',2.4);

        % ---- 刻度标记 ----
        for q = 1:length(axisValues)
            a = axisValues(q);
            % ct_j 轴上的刻度
            plot(ax, u*a, a, 'o','MarkerSize',7, ...
                 'MarkerFaceColor',col,'MarkerEdgeColor','w');
            % x_j 轴上的刻度
            plot(ax, a, 0, 's','MarkerSize',7, ...
                 'MarkerFaceColor',col,'MarkerEdgeColor','w');
        end

        % ---- 轴标签 ----
        text(ax, u*3.45 + 0.05, 3.45, ...
             ['$ct_{' suffix '}$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',16,'Color',col);
        text(ax, 3.15, yLabelOffset, ...
             ['$x_{' suffix '}$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',16,'Color',col);

        % ---- 参考系名字 ----
        if strcmp(namePlain,'K')
            dy = 0;
        elseif strcmp(namePlain,'K_1')
            dy = 0.16;
        else
            dy = 0.32;
        end
        text(ax, 0.10, 0.10 + dy, ...
             ['$' namePlain '$'],'Interpreter','latex', ...
             'FontName','Times New Roman','FontSize',15,'Color',col);
    end

end