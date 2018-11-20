function text_authorship

%     clear
    clc
    close all

    precision = int32(1000); % recommended: 1000
    
    %%
    
    load('candidates','Cndt','Cndt_Hedr')
    bar_width = 0.75;
    bar_color = 0.75 + zeros(1,3);
    
    %%
    
    col_name = 1;  % candidate name: First Last (no middle names or initials)
    col_posn = 2;  % position in administration
    col_deny = 3;  % whether candidate has denied authorship
    col_text = 4;  % raw text
    col_sent = 5;  % sentences
    col_word = 6;  % words
    col_wdct = 7;  % word count
    col_mrkv = 8;  % Markov matrix
    col_wdpn = 9;  % word position
    col_mmsm = 10; % Markov matrix similarity
    col_mmsn = 11; % Markov matrix similarity, normalized to linear fit
    col_dist = 12; % distribution
    col_dssm = 13; % distribution similarity
    col_dssn = 14; % distribution similarity, normalized to linear fit
    col_smoa = 15; % similarity, overall (sum of col_mmsn and col_dssn)
    
	% Prepare target text
    Trgt{col_name} = 'Anonymous';
    Trgt{col_posn} = 'Senior Administration Official';
    Trgt{col_deny} = 'n/a';
    Trgt{col_text} = load_text('resistance.txt');
    [Trgt{col_sent}, Trgt{col_word}, Dict] = parse_text(Trgt{col_text});
    Trgt{col_wdct} = word_count(Trgt{col_word});
    
    disp('Parsing text...')
    
    for cndt = size(Cndt,1):-1:1
        
        filename = [regexprep(lower(Cndt{cndt,1}),' ','_') '.txt'];
        if exist(filename) ~= 0
            disp(['  ' Cndt{cndt,col_name}])
            Cndt{cndt,col_text} = load_text(filename);
            [Cndt{cndt,col_sent}, Cndt{cndt,col_word}, Dict_add] = parse_text(Cndt{cndt,col_text});
            Dict = [Dict; Dict_add]; % append
        else
            Cndt(cndt,:) = [];
            warning([filename ' not found; skipping candidate'])
            continue
        end
        
    end
    
    disp('Generating matrices...')

    % Generate a master dictionary
    Dict = unique(Dict);
    Dict = containers.Map(Dict,uint32(1:length(Dict)));
    
    [Trgt{col_mrkv}, Trgt{col_wdpn}] = markov_matrix(Trgt{col_word},Dict); % Markov for target text
    Trgt{col_wdct} = word_count(Trgt{col_word}); % word count
    Trgt{col_dist} = int32(sum(Trgt{col_wdpn},2)); % distribution of word counts
    
    for cndt = 1:size(Cndt) % for each candidate
        disp(['  ' Cndt{cndt,col_name}])
        [Cndt{cndt,col_mrkv}, Cndt{cndt,col_wdpn}] = markov_matrix(Cndt{cndt,col_word},Dict); % Markov matrix
        Cndt{cndt,col_wdct} = word_count(Cndt{cndt,col_word}); % word count
        Cndt{cndt,col_dist} = int32(sum(Cndt{cndt,col_wdpn},2)); % distribution of word counts
    end
    
    %% Compare target and candidates
    
    disp('Scaling results...')
    
    % Normalize matrices to word counts
    for col = [col_mrkv, col_wdpn, col_dist]
        scale = precision / max(Trgt{col}(:));
        Trgt{col} = Trgt{col} * scale; % scale to [0 precision]
        for cndt = 1:size(Cndt,1)
            disp(['  ' Cndt{cndt,col_name}])
            scale = precision / max(Cndt{cndt,col}(:));
            Cndt{cndt,col} = Cndt{cndt,col} * scale;
        end
    end
    
    disp('Comparing matrices...')
    
    % Compare Markov matrices
    for cndt = 1:size(Cndt,1)
        disp(['  ' Cndt{cndt,col_name}])
        
        % Markov matrices
        Cndt{cndt,col_mmsm} = -sum(sum(abs(Trgt{col_mrkv} - Cndt{cndt,col_mrkv}))); % sum and invert for "similarity" signal
        
        % Distributions
        Cndt{cndt,col_dssm} = -sum(sum(abs(Trgt{col_dist} - Cndt{cndt,col_dist}))); % sum and invert for "similarity" signal
        
    end
    
    disp('Normalizing results...')
    
    % Matrices
    mmsm = cell2mat(Cndt(:,col_mmsm));
    Cndt(:,col_mmsm) = num2cell((mmsm-min(mmsm))/(max(mmsm)-min(mmsm)));
    
    % Distributions
    dssm = cell2mat(Cndt(:,col_dssm));
    Cndt(:,col_dssm) = num2cell((dssm-min(dssm))/(max(dssm)-min(dssm)));
    
    %% Perform linear fits to account for word-count effects
    
    % Markov matrices
    p_mrkv = polyfit(cell2mat(Cndt(:,col_wdct)),cell2mat(Cndt(:,col_mmsm)),1); % linear regression
    x_arry = min(cell2mat(Cndt(:,col_wdct))):max(cell2mat(Cndt(:,col_wdct)));
    y_mrkv = p_mrkv(1)*x_arry + p_mrkv(2);
    for cndt = 1:size(Cndt,1)
        Cndt{cndt,col_mmsn} = Cndt{cndt,col_mmsm} - (p_mrkv(1)*Cndt{cndt,col_wdct}+p_mrkv(2)); % vertical distance to linear regression 
    end
    a = cell2mat(Cndt(:,col_mmsn));
    Cndt(:,col_mmsn) = num2cell((a-min(a))/(max(a)-min(a)));
    
    % Distributions
    p_dist = polyfit(cell2mat(Cndt(:,col_wdct)),cell2mat(Cndt(:,col_dssm)),1); % linear regression
    y_dist = p_dist(1)*x_arry + p_dist(2);
    for cndt = 1:size(Cndt,1)
        Cndt{cndt,col_dssn} = Cndt{cndt,col_dssm} - (p_dist(1)*Cndt{cndt,col_wdct}+p_dist(2)); % vertical distance to linear regression 
    end
    a = cell2mat(Cndt(:,col_dssn));
    Cndt(:,col_dssn) = num2cell((a-min(a))/(max(a)-min(a)));
    
    for cndt = 1:size(Cndt,1)
        Cndt{cndt,col_smoa} = Cndt{cndt,col_mmsn} + Cndt{cndt,col_dssn};
    end
    smoa = cell2mat(Cndt(:,col_smoa)); % normalize overall similarity
    Cndt(:,col_smoa) = num2cell((smoa-min(smoa))/(max(smoa)-min(smoa)));
    
    %% Plot results
    
    disp('Plotting results...')
    
    for f = 1:7
        figure(f)
        clf
        hold on
        set(gcf,'color','white')
        set(gcf,'position',[2000 100 800 800])
        title('Authorship of NYT ''Resistance'' Op-Ed Based On Linguistic Similarity')
    end
    
    figure(1)
    Cndt = sortrows(Cndt,col_mmsm);
    barh(1:size(Cndt,1),cell2mat(Cndt(:,col_mmsm)), bar_width, 'facecolor',bar_color)
    grid on
    set(gca,'ytick',1:size(Cndt,1)); 
    set(gca,'yticklabel',Cndt(:,col_name))
    xlabel('Markov matrix similarity, normalized to field')
    
    figure(2)
    scatter(cell2mat(Cndt(:,col_wdct)),cell2mat(Cndt(:,col_mmsm)),'k+')
    for c = 1:size(Cndt,1)
        text(Cndt{c,col_wdct},Cndt{c,col_mmsm},['  ' Cndt{c,col_name}],'fontsize',8)
    end
    xlabel('Word count')
    ylabel('Markov matrix similarity, normalized to field')
    grid on
    plot(x_arry,y_mrkv,'color',bar_color)
    
    figure(3)
    Cndt = sortrows(Cndt,col_mmsn);
    barh(1:size(Cndt,1),cell2mat(Cndt(:,col_mmsn)), bar_width, 'facecolor',bar_color)
    xlabel('Markov matrix similarity, normalized to field and word count')
    grid on
    set(gca,'ytick',1:size(Cndt,1)); 
    set(gca,'yticklabel',Cndt(:,col_name))
    
    figure(4)
    Cndt = sortrows(Cndt,col_dssm);
    barh(1:size(Cndt,1),cell2mat(Cndt(:,col_dssm)), bar_width, 'facecolor',bar_color)
    xlabel('Word distribution similarity, normalized to field')
    grid on
    set(gca,'ytick',1:size(Cndt,1)); 
    set(gca,'yticklabel',Cndt(:,col_name))
    
    figure(5)
    scatter(cell2mat(Cndt(:,col_wdct)),cell2mat(Cndt(:,col_dssm)),'k+')
    for c = 1:size(Cndt,1)
        text(Cndt{c,col_wdct},Cndt{c,col_dssm},['  ' Cndt{c,col_name}],'fontsize',8)
    end
    xlabel('Word count')
    ylabel('Word distribution similarity, normalized to field')
    grid on
    plot(x_arry,y_dist,'color',bar_color)
    
    figure(6)
    Cndt = sortrows(Cndt,col_dssn);
    barh(1:size(Cndt,1),cell2mat(Cndt(:,col_dssn)), bar_width, 'facecolor',bar_color)
    xlabel('Word distribution similarity, normalized to field and word count')
    grid on
    set(gca,'ytick',1:size(Cndt,1)); 
    set(gca,'yticklabel',Cndt(:,col_name))
    
    figure(7)
    Cndt = sortrows(Cndt,col_smoa);
    barh(1:size(Cndt,1),cell2mat(Cndt(:,col_smoa)), bar_width, 'facecolor',bar_color)
    xlabel('Overall normalized similarity, including Markov matrix and word distribution')
    grid on
    set(gca,'ytick',1:size(Cndt,1)); 
    set(gca,'yticklabel',Cndt(:,col_name))

end












































