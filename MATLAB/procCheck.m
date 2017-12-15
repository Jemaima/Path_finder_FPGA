function [ checkValue ] = procCheck( mode, type )

testImageRaw = double(rgb2gray(imread('mazeImage.jpg'))); 

testImageRawField = [testImageRaw(1:2:end,:); testImageRaw(2:2:end,:)];

if (strcmp(mode, 'write'))
    pathWrite = 'C:\Users\metel\QuartusProjects\v.1.0\SIM\part\';    
    testImageRawFieldRot = testImageRawField.';
    fileID1 = fopen([pathWrite, 'TestData.dat'],'w');
    fprintf(fileID1,'%02x \r\n',testImageRawFieldRot);
    fclose(fileID1);
    checkValue = 0;
elseif (strcmp(mode, 'read'))
    pathRead = 'C:\Users\metel\QuartusProjects\v.1.0\SIM\part\';
    fileID2 = fopen([pathRead, 'ProcData.dat']);
    C = textscan(fileID2, '%d');
    fclose(fileID2); 
    dataFPGA = C{1,1};
    vsize = 576;
    hsize = 702;
    procImageHF1 = double(zeros(vsize,hsize));
    procImageHF2 = double(zeros(vsize,hsize));    
    for i = 1:vsize
        for j = 1:hsize
            procImageHF1(i,j) = dataFPGA((i-1)*hsize+j);
            procImageHF2(i,j) = dataFPGA((i-1)*hsize+j+hsize*vsize);
        end
    end

    % student part
    
%     if (type == 1)
%         procImageMatlab = 255 - testImageRawField;
%         subImage = [abs(procImageMatlab - procImageHF1); abs(procImageMatlab - procImageHF2)];
%     elseif (type == 2)
%         se = strel('square',3);
%         procImageMatlab = [imdilate(testImageRaw(1:2:end,:), se); imdilate(testImageRaw(2:2:end,:), se)];
%         subImage = [abs(procImageMatlab(1:end-1,1:end-3) - procImageHF1(2:end,4:end)); abs(procImageMatlab(end+1:end-1,1:end-3) - procImageHF1(end+2:end,4:end))];
%     elseif (type == 3)
%         h = fspecial('average', [3 3]);
%         procImageMatlab = floor([imfilter(testImageRaw(1:2:end,:), h); imfilter(testImageRaw(2:2:end,:), h)]);
%         subImage = [abs(procImageMatlab(1:end-1,1:end-3) - procImageHF1(2:end,4:end)); abs(procImageMatlab(end+1:end-1,1:end-3) - procImageHF1(end+2:end,4:end))];
%     elseif (type == 4)
%         procImageMatlab = [medfilt2(testImageRaw(1:2:end,:), [3 3]); medfilt2(testImageRaw(2:2:end,:), [3 3])];
%         subImage = [abs(procImageMatlab(1:end-1,1:end-3) - procImageHF1(2:end,4:end)); abs(procImageMatlab(end+1:end-1,1:end-3) - procImageHF1(end+2:end,4:end))];
%     elseif (type == 5)    
%         h = [0 -1 0; -1 4 -1; 0 -1 0];
%         filterImage = floor([imfilter(testImageRaw(1:2:end,:), h); imfilter(testImageRaw(2:2:end,:), h)]);
%         procImageMatlab = double(uint8(filterImage + testImageRawField));
%         subImage = [abs(procImageMatlab(1:end-1,1:end-6) - procImageHF2(2:end,7:end)); abs(procImageMatlab(end+1:end-1,1:end-6) - procImageHF2(end+2:end,7:end))];
%     end
    % 
      
    outImage = horzcat(testImageRawField,procImageHF1);
 
    figure, imshow(outImage, [0 255]);  
end
   
end

