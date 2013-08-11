for lambda = [5e-6, 1.5e-5, 3.5e-5, 5.5e-5, 6.5e-5, 0.00015, 0.00025, 0.00035, 0.0006, 0.0001, 0.01, 0.1, 0.9, 40]
    for s = 1:length(sections)
        sections(s).params.montageFilename = [waferFolder filesep num2str(lambda) filesep sectionNames{s} '.tif'];
    end
    params.lambda = lambda;
    sections = tikOptim(sections, params);
    mkdir([waferFolder filesep num2str(lambda)])
    renderSections(sections, params);
end