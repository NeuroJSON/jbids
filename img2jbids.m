function [digestdata, attachdata] = img2jbids(fullname, varargin)
%
%    digestdata=img2jbids(fullname)
%      or
%    [digestdata, attachdata]=img2jbids(fullname, 'param1', value1, 'param2', value2, ...)
%
%    Load an image file to extract lightweight metadata
%    digest for easy query, along with optional organized bulk measurement
%    data for saving to non-searchable attachment files in a NoSQL database
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        fullname: the path of the image data file
%        optional 'param'/'value' pairs: additional parameters to be passed
%        to the data file parser function
%
%    output:
%        digestdata: a struct containing only lightweight metadata for each
%             query and storage; if attachdata is not requested
%        attachdata: optional output, storing a separated copy of the bulky
%             binary data, can be used to lossly save the data to an
%             attachment file
%
%    examples:
%        [imgheader, imgdata] = img2jbids('/path/bs001/subj01/nirs/subj01_test.jpg');
%
%    license:
%        BSD license, see LICENSE_BSD.txt files for details
%
% -- this function is part of JBIDS toolbox (https://neurojson.org/#software)
%

opt = varargin2struct(varargin{:});
attachmentfolder = jsonopt('attfolder', '.att', opt);
outputfolder = jsonopt('outputfolder', '', opt);
attachmentroot = jsonopt('attroot', outputfolder, opt);
pathhash = jsonopt('pathhash', fullname, opt);

[fpath, fn, fext] = fileparts(fullname);

if (nargout > 1)
    if (exist(fullfile(attachmentroot, attachmentfolder), 'dir') == 0 && mkdir(fullfile(attachmentroot, attachmentfolder)) == 0)
        error('failed to create output folder %s', fullfile(attachmentroot, attachmentfolder));
    end
    if (~copyfile(fullname, fullfile(attachmentroot, [pathhash fext])))
        error('failed to copy file %s', fullname);
    end
    attachdata = [];
end

imgheader = struct;

try
    info = imfinfo(fullname);
    info.Filename = [fn fext];
    fn = fieldnames(info);
    for i = 1:min(length(fn), 9) % first 9 fields of imfinfo are the same
        imgheader.ImageHeader.(fn{i}) = info.(fn{i});
    end
    if (nargout > 1)
        imgheader.ImageData = struct(encodevarname('_DataLink_'), ['attach:' pathhash fext]);
    end
catch ME
    warning('failed to load image file: %s\nerror: %s', fullname, ME.message);
    digestdata = [];
    attachdata = [];
    return
end

if (nargout >= 1)
    digestdata = imgheader;
end
