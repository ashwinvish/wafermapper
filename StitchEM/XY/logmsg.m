function logmsg(message, filename)
% LOGMSG Prints the message to console and optionally appends it to a file
% as well.

% params = evalin('base', 'params');
% if nargin < 2 && ~isempty(params.LogFile)
%     filename = params.LogFile;
% end

if nargin < 2
    filename = 'stitch.log';
end

% Write to file
fh = fopen(filename, 'a');
fprintf(fh, message);
fclose(fh);

% Write to console
fprintf(message)

end

