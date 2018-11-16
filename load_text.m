function text = load_text(filename)

    %% Import text
    fileID = fopen(filename,'r','n','UTF-8');
    text = [];
    while ~feof(fileID)
        text = [text,' ', fgetl(fileID)];
    end
    fclose(fileID);
    
    text = regexprep(text,'http\S*\s',';'); % delete URLs
    text = regexprep(text,'\s{2,}',' ');    % clean up whitespace

end