function text_authorship_validation

    %% Attempts to validate text_authorship.m by pretending that an
    % authored writing sample is actually anonymous, and comparing the most
    % likely author (computed) to the actual author. Repeats this process
    % for each writing sample of each author
    
    % Author: Daniel W. Dichter
    % Date: 2018-12-04
    
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
    col_scnt = 5;  % sample count
    col_sent = 6;  % sentences
    col_word = 7;  % words
    col_wdct = 8;  % word count
    col_mrkv = 9;  % Markov matrix
    col_wdpn = 10; % word position
    col_mmsm = 11; % Markov matrix similarity
    col_mmsn = 12; % Markov matrix similarity, normalized to linear fit
    col_dist = 13; % distribution
    col_dssm = 14; % distribution similarity
    col_dssn = 15; % distribution similarity, normalized to linear fit
    col_smoa = 16; % similarity, overall (sum of col_mmsn and col_dssn)
    
    %% Determine how many writing samples there are
    
    for cndt = size(Cndt,1):-1:1
        filename = [regexprep(lower(Cndt{cndt,1}),' ','_') '.txt'];
        if exist(filename) ~= 0
            Cndt{cndt,col_scnt} = sample_count(filename);
        else
            disp(['Deleted: ' Cndt{cndt,col_name}])
            Cndt(cndt,:) = [];
        end
    end
    Cndt_blank = Cndt;
    
    sample_quantity = sum(cell2mat(Cndt(:,col_scnt)));
    disp(['Found ' num2str(sample_quantity) ' samples from ' num2str(size(Cndt,1)) ' candidates'])
    disp(['Validation is expected to take ' num2str(round(sample_quantity*28.5/60)) ' min; press Ctrl+C to break if desired'])
    
    samples_processed = 0;
    
    Cndt
    
    for author = 34:size(Cndt,1) % for each candidate/author
        
        Cndt = Cndt_blank; % reset candidates
        
        for sample = 1:Cndt{author,col_scnt} % for each writing sample
            
            Cndt = Cndt_blank; % reset candidates
            disp('==========')
            disp([num2str(round(samples_processed/sample_quantity*100*10)/10) '% complete'])
            disp('==========')
            disp(['Author ' num2str(author) ': ' Cndt{author,col_name}])
            disp(['Sample number: ' num2str(sample)])
            
%             continue
            
%             disp('Parsing text...')

            Dict = {}; % initialize blank dictionary

            for cndt = 1:size(Cndt,1)

                filename = [regexprep(lower(Cndt{cndt,col_name}),' ','_') '.txt'];
                if cndt==author
                    Cndt{cndt,col_text} = load_text(filename,-sample); % load everything except the target text
                else
                    Cndt{cndt,col_text} = load_text(filename,0); % load normally
                end

                [Cndt{cndt,col_sent}, Cndt{cndt,col_word}, Dict_add] = parse_text(Cndt{cndt,col_text});
                Dict = [Dict; Dict_add]; % append

            end

            % Prepare target text
            Trgt{col_name} = Cndt{author,col_name};
            Trgt{col_posn} = Cndt{author,col_posn};
            Trgt{col_deny} = Cndt{author,col_deny};
            filename = [regexprep(lower(Cndt{author,col_name}),' ','_') '.txt'];
            Trgt{col_text} = load_text(filename,sample);
            
            disp(['"' Trgt{col_text}(2:75) '..."']) % show the first few words for debug purposes
            
            [Trgt{col_sent}, Trgt{col_word}, Dict_add] = parse_text(Trgt{col_text});
            Dict = [Dict; Dict_add]; % append
            Trgt{col_wdct} = word_count(Trgt{col_word});

%                 disp('Generating matrices...')

            % Generate a master dictionary
            Dict = unique(Dict);
            Dict = containers.Map(Dict,uint32(1:length(Dict)));

            [Trgt{col_mrkv}, Trgt{col_wdpn}] = markov_matrix(Trgt{col_word},Dict); % Markov for target text
            Trgt{col_wdct} = word_count(Trgt{col_word}); % word count
            Trgt{col_dist} = int32(sum(Trgt{col_wdpn},2)); % distribution of word counts

            for cndt = 1:size(Cndt) % for each candidate
%                     disp(['  ' Cndt{cndt,col_name}])
                [Cndt{cndt,col_mrkv}, Cndt{cndt,col_wdpn}] = markov_matrix(Cndt{cndt,col_word},Dict); % Markov matrix
                Cndt{cndt,col_wdct} = word_count(Cndt{cndt,col_word}); % word count
                Cndt{cndt,col_dist} = int32(sum(Cndt{cndt,col_wdpn},2)); % distribution of word counts
            end

            %% Compare target and candidates

%                 disp('Scaling results...')

            % Normalize matrices to word counts
            for col = [col_mrkv, col_wdpn, col_dist]
                scale = precision / max(Trgt{col}(:));
                Trgt{col} = Trgt{col} * scale; % scale to [0 precision]
                for cndt = 1:size(Cndt,1)
%                     disp(['  ' Cndt{cndt,col_name}])
                    scale = precision / max(Cndt{cndt,col}(:));
                    Cndt{cndt,col} = Cndt{cndt,col} * scale;
                end
            end

%                 disp('Comparing matrices...')

            % Compare Markov matrices
            for cndt = 1:size(Cndt,1)
%                 disp(['  ' Cndt{cndt,col_name}])

                % Markov matrices
                Cndt{cndt,col_mmsm} = -sum(sum(abs(Trgt{col_mrkv} - Cndt{cndt,col_mrkv}))); % sum and invert for "similarity" signal

                % Distributions
                Cndt{cndt,col_dssm} = -sum(sum(abs(Trgt{col_dist} - Cndt{cndt,col_dist}))); % sum and invert for "similarity" signal

            end

%                 disp('Normalizing results...')

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
            
            %% Assess and output results
            
            Cndt = sortrows(Cndt,-col_smoa);
            disp('Authorship similarity:')
            for cndt = 1:size(Cndt,1)
                disp(['  ' num2str(cndt) '. ' Cndt{cndt,col_name} ': ' num2str(Cndt{cndt,col_smoa})])
            end
            target_index = find(strcmp(Cndt(:,col_name),Trgt{col_name}));
            if target_index == 1
                disp(['Correct: actual author ranked in position ' num2str(target_index)])
            else
                disp(['Incorrect: actual author ranked in position ' num2str(target_index)])
            end
            
            samples_processed = samples_processed+1;
            
        end % all samples complete
        
    end % all authors complete

end












































