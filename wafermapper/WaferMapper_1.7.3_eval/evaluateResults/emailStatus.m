logFile = 'D:\LGNs1\rawMontages\logBooks\LogBook_w034.mat';
lastReportedSec = 0;


mail = 'jmdatawatcher@gmail.com'; %Your GMail email address
password = 'jmDataWatcher37'; %Your GMail password
setpref('Internet','SMTP_Server','smtp.gmail.com');

setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

% Send the email. Note that the first input is the address you are sending the email to
while 1
    %% Get data
    try load(logFile);
    catch err
        
    end
    
    %% Time
    tileNams = cat(1,logBook.sheets.imageConditions.data{:,1});
    tileTimes = cat(1,logBook.sheets.imageConditions.data{:,32});
    secPos = regexp(tileNams(1,:),'_sec');
    secs = str2num(tileNams(:,secPos+4:secPos+6));
    uSecs = unique(secs);
    tileNumTimes = datenum(tileTimes);
    
    
    %% Quality
    tileNamsQual = cat(1,logBook.sheets.quality.data{:,1});
    tileNamsQualCell = {logBook.sheets.quality.data{:,1}};
    
    tileQual = cat(1,logBook.sheets.quality.data{:,3});
    qualSecs = str2num(tileNamsQual(:,secPos+4:secPos+6));
    
    for i = 1:length(uSecs)
        sec = uSecs(i);
        sectionList(i) = sec;
        secNumTimes = tileNumTimes(secs == sec);
        startTimes(i) = min(secNumTimes);
        secNamsQuals = tileNamsQualCell(qualSecs == sec);
        [uSecNams uList] = unique(secNamsQuals);
        secQuals = tileQual(qualSecs == sec);
        sectionQuality(i) = min(secQuals(uList));
        sectionTakes(i) = length(secQuals);
    end
    
    
    
    durations = (startTimes(2:end)-startTimes(1:end-1))*24 * 60;
    % [sortedTimes sortOrder] = sort(startTimes,'ascend');
    % durations = durations(sortOrder)
    
    %% IBSC
    secNams3 = cat(1,logBook.sheets.IBSC.data{:,1});
    secMerit = cat(1,logBook.sheets.IBSC.data{:,5});
    secMaxShift = max(abs([cat(1,logBook.sheets.IBSC.data{:,2}) cat(1,logBook.sheets.IBSC.data{:,3})]),[],2);
    
%     %% Current
%     secNames4 = cat(1,logBook.sheets.specimenCurrent.data{:,1});
%     for i = 1:size(logBook.sheets.specimenCurrent.data,1)
%         secCurrents(i) = max(cat(1,logBook.sheets.specimenCurrent.data{i,2:end}))*1000000000;
%     end
%     
    %% progress
    
    prog = logBook.waferProgress;
    sectionsLeft = sum(logBook.waferProgress.do);
    %% Report
    checkTime = datestr(clock);
    lastTime = tileTimes(end,:);
    disp(' ')
    disp(' ')
    disp(' ')
    minutesSinceLast = (datenum(checkTime) - datenum(lastTime))*24*60;
    disp(sprintf('Updated %.1f minutes ago.',minutesSinceLast))
    disp(['Last Section Quals = ' sprintf('%3.0f ',fliplr(secQuals(uList)))])
    lastQuals = fliplr(round(tileQual(end-min(length(tileQual),15)+1:end)'));
    disp(['Last tile quals: ' num2str(lastQuals)])
    disp(['Last Sections Taken =',...
        sprintf('%3.0f ',sectionList(max(1,length(sectionList)-9):end))]);
    lastMerit = fliplr(secMerit(end - min(length(secMerit),10)+1:end)');
    %disp(['Last Merits: ' sprintf('%0.2f  ', lastMerit')])
    lastShift = fliplr(abs(secMaxShift(end - min(length(secMaxShift),10)+1:end))');
    disp(['Last Shift : ' sprintf('%.1f  ', lastShift)])
    lastCurrent = fliplr(secCurrents(end-min(length(secCurrents),10):end));
    disp(['Last currents were ' sprintf('%.3f ',lastCurrent) ])
    lastDurations = fliplr(durations(end - min(length(durations),10)+1:end));
    disp(['Last durations: ' sprintf('%.1f ', lastDurations)]);
    hoursLeft =( median(lastDurations) * sectionsLeft)/60;
    disp(['Hours Left: ' num2str(hoursLeft)])
    
    
    checkSections = sectionList>lastReportedSec;
    reportFail = 0;
    if min(sectionQuality(lastReportedSec+1:end))< 230
        reportFail = 1;
    end
    if minutesSinceLast >60
        reportFail = 1;
    end
    
    if reportFail
        disp('Sending Report Email')
        messageLastMinQual = ['Lowest quality of last 10 sections = \n'...
            sprintf('%3.0f ',  sectionQuality(max(1,length(sectionQuality)-9):end))];
        
        messageLastSecs = ['Last Sections Taken = \n',...
            sprintf('%3.0f ',sectionList(max(1,length(sectionList)-9):end))];
        messageLastTime = sprintf( 'Last image taken %4.1f minutes ago.', minutesSinceLast);
        messageTakeNum = ['Number of images take per sec = \n'...
            sprintf('%3.0f ',  sectionTakes(max(1,length(sectionQuality)-9):end))];
        
        message = sprintf([messageLastTime '\n\n' messageLastSecs '\n\n'...
            messageLastMinQual '\n\n'  messageTakeNum]);
        disp(message)
        sendmail('chilopod@gmail.com','low section quality',message)
        lastReportedSec = length(sectionQuality);
        pause(5)
    end
    pause(5)
end