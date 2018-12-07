% function validation_plots

    % Extracts data from text log in validation_results.txt
    % Outputs graph for understanding the data
    
    clear
    clc
    
    filename = 'validation_results.txt';
    load('authorship_results_nyt','resistance_authors','resistance_scores')
    
    author_count = 37;
    
    certainty = 0.80;
    
    %%
    
    rank = '(\d+). (\w+ \w+): ([\d.]+)\s+';
    r = '';
    for a = 1:author_count
        r = [r rank];
    end
    rank = r;
    clear r
    
    entry = [': (\w+ \w+)\sSample number: (\d+)\s("[^"]+")[^\d]+' rank];
    
    fileID = fopen(filename,'r','n','UTF-8');
    text = [];
    while ~feof(fileID)
        text = [text,' ', fgetl(fileID)];
    end
    fclose(fileID);
    
    data = regexp(text,entry,'tokens')';
    Data = cell(size(data,1),length(data{1}));
    for a = 1:size(data,1)
        Data(a,:) = data{a};
    end
    
    Data = sortrows(Data,1); % sort by author
    
    Authors = unique(Data(:,1));
    Rank = zeros(size(Data,1),1);
    
    for r = 1:size(Rank,1)
        Rank(r) = str2num(Data{r,max(find(strcmp(Data(r,:),Data{r,1})))-1});
    end
    
    %% Prepare figures
    
    for f = 1:4
        figure(f)
        clf
        hold on
        set(gcf,'color','white')
    end
    
    %% PDF and CDF of rankings
    
    figure(1)
    
    pdf = zeros(1,length(Authors));
    pdf_null = zeros(1,length(Authors)) + 1/length(Authors);
    
    for n = 1:length(Authors)
        pdf(n) = length(find(Rank==n));
    end
    pdf = pdf ./ sum(pdf);
    
    cdf = cumsum(pdf);
    cdf_null = cumsum(pdf_null);
    
    subplot(2,1,1)
    hold on
    bar(pdf,      1, 'edgecolor','none','facealpha',0.5,'facecolor',[0 0 1])
    bar(pdf_null, 1, 'edgecolor','none','facealpha',0.5,'facecolor',[1 0 0])
    legend('Per linguistic analysis','Null, i.e. random guess','location','northeast')
    grid on
    title('Probability density (PDF) of authorship ranking')
    
    subplot(2,1,2)
    hold on
    plot(cdf,     'color',[0 0 1],'linewidth',2)
    plot(cdf_null,'color',[1 0 0],'linewidth',2)
    legend('Per linguistic analysis','Null, i.e. random guess','location','southeast')
    grid on
    title('Cumulative density function (CDF) of authorship ranking')
    xlabel('Rank of actual author as predicted by linguistic analysis')
    
    set(gcf,'position',[100 100 600 700])
    
    %% Rank by author, all samples
    
    Rank_Author = zeros(size(Data,1),length(Authors));
    
    for r = 1:size(Data,1)
        for a = 1:length(Authors)
            Rank_Author(r,a) = str2num(Data{r,max(find(strcmp(Data(r,:),Authors{a})))-1});
        end
    end
    
    figure(2)
    
    Rank_author_average = [Authors, num2cell(mean(Rank_Author,1)')];
    Rank_author_average = sortrows(Rank_author_average,-2);
    
    bar_width = 0.75;
    bar_color = 0.75 + zeros(1,3);
    
    barh(1:length(Authors),cell2mat(Rank_author_average(:,2)), bar_width, 'facecolor',bar_color)
    grid on
    set(gca,'ytick',1:length(Authors)); 
    set(gca,'yticklabel',Rank_author_average(:,1))
    xlabel('Similarity rank, average, across all writing samples')
    title({'False positives and negatives: comparison of average rankings'
            '\fontsize{10}\rmLower rank: author is frequently mistaken for others, i.e. a generic style'
                           'Higher rank: author is infrequently mistaken for others, i.e. a unique style'
          })
    
    set(gcf,'position',[150 100 700 750])
      
    %% Accuracy by author
    
    Accuracy_By_Author = zeros(length(Authors),1);
    
    for a = 1:length(Authors)
        a_i = find(strcmp(Data(:,1),Authors{a})); % author indices
        c_c = 0; % correct counter
        for ind = 1:length(a_i) % for each writing sample by this author
            if strcmp(Data{a_i(ind),5},Authors{a}) % if candidate was identified correctly
                c_c = c_c + 1;
            end
        end
        Accuracy_By_Author(a) = c_c/length(a_i);
    end
    
    Rank_accuracy_author = [Authors, num2cell(Accuracy_By_Author)];
    Rank_accuracy_author = sortrows(Rank_accuracy_author,[2,-1]);
    
    figure(3)
    
    barh(1:length(Authors),cell2mat(Rank_accuracy_author(:,2))*100, bar_width, 'facecolor',bar_color)
    grid on
    set(gca,'ytick',1:length(Authors)); 
    set(gca,'yticklabel',Rank_accuracy_author(:,1))
    xlabel('Authorship prediction accuracy, percent')
    title({'Authorship prediction accuracy by author'
            '\fontsize{10}\rmi.e. pecentage of time that samples by specified author were correctly attributed'
%                            'Higher rank: author is infrequently mistaken for others, i.e. a unique style'
          })
    
    set(gcf,'position',[200 100 700 750])
    
    %% Accuracy by author
    
    Rank_By_Author = zeros(length(Authors),1);
    
    for a = 1:length(Authors)
        a_i = find(strcmp(Data(:,1),Authors{a})); % author indices
        ranks = [];
        for ind = 1:length(a_i) % for each writing sample by this author
            ranks(end+1) = str2num(Data{a_i(ind),max(find(strcmp(Data(a_i(ind),:),Authors{a})))-1});
        end
        Rank_By_Author(a) = mean(ranks);
    end
    
    Rank_By_Author = [Authors, num2cell(Rank_By_Author)];
    Rank_By_Author = sortrows(Rank_By_Author,-2);
    
    figure(4)
    
    barh(1:length(Authors),cell2mat(Rank_By_Author(:,2)), bar_width, 'facecolor',bar_color)
    grid on
    set(gca,'ytick',1:length(Authors)); 
    set(gca,'yticklabel',Rank_By_Author(:,1))
    xlabel('Authorship rank for samples by specified author')
    title({'Authorship prediction accuracy by author'
            '\fontsize{10}\rmi.e. lower rankings indicate greater success at identifying linguistic style'
          })
    
    set(gcf,'position',[250 100 700 750])
    
    %% Apply certainty threshold

    [pdf_sort, pdf_inds] = sort(pdf,'descend');
    
    cdf_sort = cumsum(pdf_sort);
    
    threshold = min(find(cdf_sort>certainty));
    
    Scores = [resistance_authors, num2cell(resistance_scores)];
    Scores = sortrows(Scores,-2);
    
    Scores_sort = Scores(pdf_inds,:);
    
    disp(['With ' num2str(round(certainty*100)) '% confidence, author is one of:'])
    
    for i = 1:threshold
        disp([ num2str(i) '. ' Scores_sort{i,1}])
    end
    
    if threshold < length(Scores_sort)
        
        disp(' ')
        disp(['With ' num2str(round(certainty*100)) '% confidence, author is none of:'])

        for i = threshold+1:length(Scores_sort)
            disp([ num2str(i) '. ' Scores_sort{i,1}])
        end
    
    end
    
% end













































