
testImageRaw = double(rgb2gray(imread('maze_1.jpg'))); 

testImageRawField = [testImageRaw(1:2:end,:); testImageRaw(2:2:end,:)];

pathRead = 'C:\Users\metel\QuartusProjects\v.1.0\SIM\part\';
fileID2 = fopen([pathRead, 'ProcData.dat']);
C = textscan(fileID2, '%d');
fclose(fileID2); 
dataFPGA = C{1,1};
vsize = 576;
hsize = 702;
nShots = 2; 
procImageHF = double(zeros(nShots,vsize,hsize));
outImage = testImageRawField;
for z = 1:nShots
    for i = 1:vsize
        for j = 1:hsize
            procImageHF(z,i,j) = squeeze(dataFPGA((i-1)*hsize+j+(z-1)*hsize*vsize));
        end
    end
    outImage = horzcat(outImage,squeeze(procImageHF(z,:,:)));
end

figure, imshow(outImage, [0 255]);  