function count = sample_count(filename)

    % Determines how many writing samples exist for each candidate by
    % counting URL demarcators

    %% Import text
    fileID = fopen(filename,'r','n','UTF-8');
    text = [];
    while ~feof(fileID)
        text = [text,' ', fgetl(fileID)];
    end
    fclose(fileID);
    
    URL = 'http\S*\s'; % regular expression for URL
    URL_ind = regexp(text,URL); % delete URLs
    count = length(URL_ind);

end