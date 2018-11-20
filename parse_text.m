function [Sent, Word, Dict] = parse_text(text)

    exp_sent = ';\s{0,}([A-Z]?[Ia-z \-'']+)'; % sentence fragment
    
    % Prepare text for parsing
    text = regexprep(text,'[,0-9\%\$\#\:]+[a-zA-Z]{0,}',';'); % break up fragments
    text = regexprep(text,'’','''');            % replace angled apostrophes with straight ones
    text = regexprep(text,'Mrs?.','');          % remove titles, which look like ends of sentences
    text = regexprep(text,'[\,\.\?\!§]',';');   % standardize punctuation
    text = regexprep(text,'\.{1,}',';');        % ellipses
    text = regexprep(text, '-{2,}',';');        % multi-dashes
    text = regexprep(text, '—{1,}',';');        % emdashes
    text = regexprep(text, '"[^"]+"',';');      % symmetrical quotes
    text = regexprep(text, '“[^“”]+”',';');     % asymmetrical quotes
    
    % Delete proper nouns
    [cap_start, cap_end] = regexp(text,'([A-HJ-Z][a-z''-]{0,})','start','end'); % location of capitalized words
    sent_break = regexp(text,'[.;?!]'); % location of sentence-break punctuation
    for c = size(cap_start,2):-1:1 % for each capital word detected
        pp = cap_start(c)-sent_break;
        pp = find(pp<0, 1 ,'first')-1; % index of preceding punctuation
        if cap_start(c)-sent_break(pp) > 4 % if this capitalized word is sufficient displaced from its preceding punctuation
            text(cap_start(c):cap_end(c)) = ';';
        end
    end
    
    % Final preparations before parsing
    text = regexprep(text, '[\(\)\[\]]',';'); % parentheses
    text = regexprep(text,'[;\s-]{2,}',';'); % clean up whitespace and demarcators
    
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
        Word(s) = regexp(lower(Sent(s)),'([a-z\-'']+)','tokens');
    end
    
%     disp('Extracting dictionary...')
    
    word_count = 0;
    for s = 1:size(Word,1)
        word_count = word_count + length(Word{s});
    end
    
    r = 1; % row counter
    Dict = cell(word_count,1); % pre-allocate
    for s = 1:length(Word) % for each sentence
        for w = 1:length(Word{s}) % for each word
            Dict(r) = Word{s}{w};
            r = r+1;
        end
    end
    
    Dict = unique(Dict);

end













































