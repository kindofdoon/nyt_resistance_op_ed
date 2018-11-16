% function markov_generator

%     clear
%     clc

    %% Inputs

    filename = 'alex_azar';
    
    %%
    
    load(filename,'Mrkv','Dict','Word_Posn')

    %% Generate a sentence
    
    disp('Generating a sentence...')
    
    Mrkv     (Mrkv==0)      = 1e-10;
    Word_Posn(Word_Posn==0) = 1e-10;
    
    sent_len = round(sum(Word_Posn(:))/sum(Word_Posn(:,1)));
    
    S = [];
    
    % Pick a first word
    prob_dist = [0; cumsum(Word_Posn(:,1)/sum(Word_Posn(:,1)))];
    samp = rand;
    prev = min(find(samp<prob_dist)) - 1;
    
    S = [Dict{prev} ' '];
    S(1) = upper(S(1));
    
    for w = 2:10%sent_len
        
        prob_dist = [0; cumsum(Mrkv(:,prev)/sum(Mrkv(:,prev)))];
        samp = rand;
        next = min(find(samp<prob_dist)) - 1;

%         [~, best] = max(Mrkv(:,prev)); % most likely next word
        
%         disp(Word_List{prev})
%         disp(['  ' Word_List{best} ' (best)'])
%         disp(['  ' Word_List{next} ' (sampled)'])
        
        S = [S, Dict{next}, ' '];
        prev = next;
        
    end
    
    S(end) = '.';
    
    disp(S)
    
    
% end



















































