function [Mrkv, Word_Posn] = markov_matrix(Word,Dict)

    %% Make Markov matrix
    
%     disp('Generating Markov matrix...')

    container = 'int32'; % recommend: int32
    
    % Size and initialize hit counter
    sent_len_max = 0;
    for s = 1:length(Word)
        sent_len_max = max([sent_len_max, length(Word{s})]);
    end
    
    Word_Posn = zeros(length(Dict),sent_len_max,container);
    Mrkv = zeros(length(Dict),container);
    
    for s = 1:length(Word) % for each sentence
        
        if length(Word{s})==1 % only one word in this fragment
            word_1 = find(strcmpi(Word{s}{1}{:}, Dict));
            % Cannot increment Markov matrix, because there is no next word
            Word_Posn(word_1,1) = Word_Posn(word_1,1) + 1;
            continue
        end
        
        if length(Word{s})==0 % only one word in this fragment
            warning(['fragment ' num2str(s) ' is sparse or empty'])
            continue
        end
        
        for w = 1:length(Word{s})-1 % for each word
            word_1 = find(strcmpi(Word{s}{w}{:},  Dict));
            word_2 = find(strcmpi(Word{s}{w+1}{:},Dict));
            Mrkv(word_2,word_1) = Mrkv(word_2,word_1)+1;
            Word_Posn(word_1,w) = Word_Posn(word_1,w) + 1;
        end
        Word_Posn(word_2,w+1) = Word_Posn(word_2,w+1) + 1;
        
    end
    
end