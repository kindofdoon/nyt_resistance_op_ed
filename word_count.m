function wdct = word_count(Word)

    % Word count
    wdct = 0;
    for s = 1:length(Word) % for each sentence
        wdct = wdct + length(Word{s});
    end

end