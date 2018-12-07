% function accuracy_plot

    % OBSOLETE: use validation_plots.m instead

    clear
    clc

    rank = [6, 21, 4, 4, 16, 1, 3, 4, 4, 1, 32, 1, 27, 35, 37, 15, 14, 22, 10, 28, 3, 2, 1, 1, 3, 25, 30, 35, 35, 4, 6, 11, 5, 4, 7, 2, 16, 11, 14, 9, 10, 5, 17, 11, 8, 8, 4, 30, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 7, 21, 23, 1, 31, 31, 32, 1, 10, 15, 5, 8, 7, 31, 7, 30, 13, 17, 8, 19, 1, 10, 7, 4, 5, 3, 1, 21, 2, 5, 4, 3, 2, 22, 18, 6, 11, 20, 4, 34, 33, 3, 31, 12, 1, 1, 1, 1, 1, 36, 1, 1, 1, 7, 5, 7, 5, 4, 7, 15, 17, 5, 4, 26, 1, 4, 1, 1, 1, 16, 23, 17, 7, 26, 11, 4, 4, 13, 7, 9, 4, 1, 10, 12, 7, 4, 8, 4, 10, 6, 4, 4, 4, 3, 6, 4, 2, 1, 2, 6, 6, 6, 5, 3, 7, 6, 9, 4, 6, 11, 4, 16, 8, 5, 12, 11, 10, 11, 17, 21, 4, 12, 7, 11, 6, 6, 6, 3, 4, 4, 5, 5, 6, 5, 7, 13, 9, 13, 21, 10, 15, 12, 10, 13, 10, 6, 11, 8, 4, 10, 8, 8, 10, 10, 28, 33, 20, 32, 22, 32, 9];

    figure(1)
    clf
    hold on
    set(gcf,'color','white')
    
    cndt_qty = 37;
    
    pdf = zeros(1,cndt_qty);
    pdf_null = zeros(1,cndt_qty) + 1/cndt_qty;
    
    for n = 1:cndt_qty
        pdf(n) = length(find(rank==n));
    end
    pdf = pdf ./ sum(pdf);
    
    cdf = cumsum(pdf);
    cdf_null = cumsum(pdf_null);
    
    subplot(2,1,1)
    hold on
    bar(pdf,      1, 'edgecolor','none','facealpha',0.5,'facecolor',[0 0 1])
    bar(pdf_null, 1, 'edgecolor','none','facealpha',0.5,'facecolor',[1 0 0])
    legend('Per linguistic analysis','Null, e.g. random guess','location','northeast')
    grid on
    title('Probability density (PDF) of authorship ranking')
    
    subplot(2,1,2)
    hold on
    plot(cdf,     'color',[0 0 1],'linewidth',2)
    plot(cdf_null,'color',[1 0 0],'linewidth',2)
    legend('Per linguistic analysis','Null, e.g. random guess','location','southeast')
    grid on
    title('Cumulative density function (CDF) of authorship ranking')
    xlabel('Rank of actual author as predicted by linguistic analysis')
    
% end