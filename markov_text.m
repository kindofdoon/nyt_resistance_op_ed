% function markov_text

    clear
    clc

    %% Inputs
    
    disp('Importing text...')
    
    filename = 'alex_azar.txt';
    
    text = load_text(filename);
    
    %% Pre-process
    
    disp('Parsing input into sentences and words...')
    
    text = regexprep(text,'http\S*\s',''); % delete URLs
    text = regexprep(text,'\s+',' '); % replace linebreaks with spaces
    text = regexprep(text,'[“”''_]','');
    text = regexprep(text,'\-{2,}',';'); % convert multi-dashes to semicolons
    text = regexprep(text,'\.{2,}',';'); % convert multi-periods to semicolons
    text = regexprep(text,'([A-Z][a-z'',-]{0,4})\.','$1'); % replace abbreviations like Mr. and Mrs. with Mr and Mrs
    
%     return
    
    %% Parse
    exp_sent = '([^.;?!]+[.;?!])';        % extracts sentences
    exp_word = '([a-zA-Z''-]+)[, .;?!]';  % extracts words
    
    % Break up text into sentences
    Sent = regexp(text,exp_sent,'tokens')';
    for s = 1:length(Sent)
        Sent{s} = Sent{s}{1}; % squeeze
    end
    
    % Clean up sentences
    for s = 1:length(Sent)
        Sent{s} = regexprep(Sent{s},'^[^a-zA-Z0-9]+',''); % leading punctuation
        Sent{s} = regexprep(Sent{s},'[^a-zA-Z0-9.;?!]+$',''); % trailing punctuation
%         Sent{s} = regexprep(Sent{s},'"','');
%         Sent{s} = regexprep(Sent{s},'\s+',' ');
    end
    
    % Break up sentences into words
    Word = cell(length(Sent),1);
    for s = 1:length(Sent)
        Word(s) = regexp(Sent(s),exp_word,'tokens');
    end
    
    %% Determine unique word list
    
    disp('Extracting dictionary...')
    
    word_count = 0;
    for s = 1:length(Sent)
        word_count = word_count + length(Word{s});
    end
    
    r = 1; % row counter
    Dict = cell(word_count,1); % pre-allocate
    for s = 1:length(Sent) % for each sentence
        for w = 1:length(Word{s}) % for each word
            Dict(r) = lower(Word{s}{w});
            r = r+1;
        end
    end
    Dict = unique(Dict);
    
    %% Make Markov matrix
    
    disp('Generating Markov matrix...')
    
    % Size and initialize hit counter
    sent_len_max = 0;
    for s = 1:length(Word)
        sent_len_max = max([sent_len_max, length(Word{s})]);
    end
    Word_Posn = zeros(length(Dict),sent_len_max);
    
    Mrkv = zeros(length(Dict));
    for s = 1:length(Sent) % for each sentence
        for w = 1:length(Word{s})-1 % for each word
            word_1 = find(strcmpi(Word{s}{w}{:},  Dict));
            word_2 = find(strcmpi(Word{s}{w+1}{:},Dict));
            Mrkv(word_2,word_1) = Mrkv(word_2,word_1)+1;
            Word_Posn(word_1,w) = Word_Posn(word_1,w) + 1;
        end
        Word_Posn(word_2,w+1) = Word_Posn(word_2,w+1) + 1;
    end
    
    %% Display most popular pairings

    Mrkv_Copy = Mrkv;
    disp('Top pairs:')
    for top = 1:30
        [val, ind] = max(Mrkv_Copy(:));
        [val1, val2] = ind2sub(size(Mrkv_Copy),ind);
        disp(['  ' num2str(top) ': ' Dict{val2} ' ' Dict{val1} ' (' num2str(Mrkv_Copy(val1,val2)) ')'])
        Mrkv_Copy(val1,val2) = 0;
    end
    
    filename_out = regexprep(filename,'\.txt','');
    
    save(filename_out,'Mrkv','Dict','Word_Posn','-v7.3')

% end


















































