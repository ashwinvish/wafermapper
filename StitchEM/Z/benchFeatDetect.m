totalTimeSIFT = 0; totalTimeSURF = 0; totalPtsSIFT = 0; totalPtsSURF = 0; i = 0;
for r = 1:4
    for c = 1:4
        img = imread(['E:\EMdata\2000px\S2-W002_Sec100_Montage\Tile_r' num2str(r) '-c' num2str(c) '_S2-W002_sec100.tif']);

        tic;
        [f1, d1] = vl_sift(single(img), 'Octaves', 3, 'Levels', 4);
        totalTimeSIFT = totalTimeSIFT + toc;
        totalPtsSIFT = totalPtsSIFT + length(f1);
        
        tic;
        SURFPoints = detectSURFFeatures(img, 'MetricThreshold', 1100, 'NumOctaves', 3, 'NumScaleLevels', 4);
        totalTimeSURF = totalTimeSURF + toc;
        totalPtsSURF = totalPtsSURF + length(SURFPoints);
        
        i = i + 1;
    end
end
avgPtsSIFT = totalPtsSIFT / i;
avgTimeSIFT = totalTimeSIFT / i;
avgPtsSURF = totalPtsSURF / i;
avgTimeSURF = totalTimeSURF / i;

fprintf('SIFT features found: %d (avg) | %fs\n', avgPtsSIFT, avgTimeSIFT)
fprintf('SURF features found: %d (avg) | %fs\n', avgPtsSURF, avgTimeSURF)