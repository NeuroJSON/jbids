function bidssub2json(bidssubpath, outputfolder, varargin)
%
%    bidssub2json(bidssubpath, outputfolder)
%       or
%    bidssub2json(bidssubpath, outputfolder, 'param1',value1, 'param2',value2,...)
%
%    Extract searchable, queryable data and metadata stored in the data
%    files inside a BIDS (brain imaging data structure) subject data folder
%    into JSON files for easy human/machine readability, file or database
%    queries, and extended interoperability; non-searchable binary data are
%    also stored as `attachments' to accompany the output searchable files.
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        bidssubpath: the path to a BIDS subject folder inside a BIDS
%                     dataset
%        outputfolder: the root folder in which all converted JSON files
%                     are written; the output files are organized in the
%                     same folder structure as in the source folder; the
%                     non-searchable binary data are stored inside the
%                     attachment folder, which is by default located at
%                     [outputfolder '/.att/'], unless changed by user
%                     options, see below/
%        options: (optional) for additional 'param',value pairs are passed
%                     to savejson function in the JSONLab toolbox to
%                     control output JSON file formats; in addition to
%                     savejson options, the below options are also
%                     supported
%
%             attfolder: a string, defines the folder name of the
%                     attachment folder, if not given, use '.att'
%             attroot: a path specifying the output attachment output
%                     folder; if not given, uses [outputfolder '/.att/']
%             attachdata: [1|0], if set to 1 (default), the imaging data
%                     stored inside .nii.gz files are extracted and saved
%                     as an attachment; if set to 0, only nifti headers are
%                     parsed and coverted (faster).
%             compression: the compression method used for compressing the
%                     binary attachment data (internally based on the JData
%                     specification), default is 'zlib' (see 'help savejson')
%             compressarraysize: [200|integer]: savejson applies
%                     compression to the binary data array if the total
%                     element number exceeds this number
%
%    examples:
%        bidssub2json('sub-01', '../digest/sub-01');
%        bidssub2json('/full/path/ds1/sub-01', '/tmp/sub-01', 'compact', 1, 'niidata', 0, 'attroot', '/tmp/attachments');
%
%    license:
%        BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details
%
% -- this function is part of JBIDS toolbox (https://neurojson.org/#software)
%

if (nargin < 2)
    error('one must provide both input BIDS data folder and output folder');
end

opt = varargin2struct(varargin{:});

attachmentlimit = jsonopt('compressarraysize', 200, opt);
attachmentfolder = jsonopt('attfolder', '.att', opt);
attachmentroot = jsonopt('attroot', outputfolder, opt);
attachdata = jsonopt('attachdata', {}, opt);
converters = jsonopt('converters', {'snirf', 'snirf2jbids'}, opt);
converters = struct(converters{:});

try
    bids = recursivelist(bidssubpath);
catch
    error('failed to open bids folder %s', bidssubpath);
end

[fpath, subjectid] = fileparts(bidssubpath);

if (~isempty(bids) && strcmp(bids(1).name, '.'))
    bidssubpath = bids(1).folder;
end

for i = 1:length(bids)
    if (bids(i).isdir)
        continue
    end
    fname = bids(i).name;
    fullname = fullfile(bids(i).folder, bids(i).name);
    fprintf(1, 'processing %d [%s]\n', i, fullname);

    [fpath, fn, fext] = fileparts(fullname);
    relpath = bids(i).folder(length(bidssubpath) + 1:end);
    if (exist(fullfile(outputfolder, relpath), 'dir') == 0 && mkdir(fullfile(outputfolder, relpath)) == 0)
        error('failed to create output folder %s', fullfile(outputfolder, relpath));
    end

    pathhash = relpath;
    if (isempty(pathhash) || pathhash(1) ~= filesep)
        pathhash = [filesep, relpath];
    end
    pathhash = [filesep subjectid pathhash];
    pathhash = jdatahash(regexprep([pathhash, filesep, bids(i).name], '\\', '/'), 'md5');

    try
        if (strcmpi(fext, '.json'))
            if (~copyfile(fullname, fullfile(outputfolder, relpath, bids(i).name)))
                error('failed to copy file %s', fullname);
            end
        elseif (~isempty(regexp(lower(fname), '\.nii(\.gz)*$', 'once')))
            if (bids(i).bytes == 0)
                continue
            end
            if (ismember('.nii', attachdata))
                nii = nii2jnii(fullname);
            else
                nii = nii2jnii(fullname, 'niiheader');
                nii = niiheader2jnii(nii);
                nii.NIFTIData = [];
            end
            if (numel(nii.NIFTIData) > attachmentlimit)
                if (exist(fullfile(attachmentroot, attachmentfolder), 'dir') == 0 && mkdir(fullfile(attachmentroot, attachmentfolder)) == 0)
                    error('failed to create output folder %s', fullfile(attachmentroot, attachmentfolder));
                end
                savebj('', nii.NIFTIData, 'filename', fullfile(attachmentroot, attachmentfolder, [pathhash, '.jdb']), 'compression', 'zlib', opt);
                nii.NIFTIData = struct(encodevarname('_DataLink_'), ['/' attachmentfolder '/' pathhash '.jdb']);
            end
            savejson('', nii, 'filename', fullfile(outputfolder, relpath, [fname, '.jnii']), opt);
            clear nii;
        elseif (~isempty(regexp(lower(fname), '\.tsv(\.gz)*$', 'once')))
            savejson('', loadbidstsv(fullname), 'filename', fullfile(outputfolder, relpath, [fname, '.json']), opt);
        elseif (strcmpi(fext, '.jpg') || strcmpi(fext, '.tif'))
            if (exist(fullfile(attachmentroot, attachmentfolder), 'dir') == 0 && mkdir(fullfile(attachmentroot, attachmentfolder)) == 0)
                error('failed to create output folder %s', fullfile(attachmentroot, attachmentfolder));
            end
            if (~copyfile(fullname, fullfile(attachmentroot, attachmentfolder, [pathhash fext])))
                error('failed to copy file %s', fullname);
            end
            info = struct;
            if (strcmp(fext, '.jpg'))
                filetype = 'JPEG';
            else
                filetype = 'TIFF';
            end
            info.([filetype, 'Header']) = imfinfo(fullname);
            info.([filetype, 'Data']) = struct(encodevarname('_DataLink_'), ['/' attachmentfolder '/' pathhash fext]);

            savejson('', info, 'filename', fullfile(outputfolder, relpath, [fname, '.json']), opt);
        elseif (strcmpi(fext, '.jbids')) % ignore previously generated digest files
            continue
        elseif (isfield(converters, regexprep(fext, '^\.', '')))
            fh = str2func(converters.(regexprep(fext, '^\.', '')));
            fopts = opt;
            fopts.pathhash = [attachmentfolder '/' pathhash];
            if (ismember(fext, attachdata))
                [filedigest, fileattach] = fh(fullname, fopts);
                if (~isempty(fileattach))
                    if (exist(fullfile(attachmentroot, attachmentfolder), 'dir') == 0 && mkdir(fullfile(attachmentroot, attachmentfolder)) == 0)
                        error('failed to create output folder %s', fullfile(attachmentroot, attachmentfolder));
                    end
                    savebj('', fileattach, 'filename', fullfile(attachmentroot, attachmentfolder, [pathhash, '.jdb']), 'compression', 'zlib', opt);
                end
                clear fileattach;
            else
                filedigest = fh(fullname, fopts);
            end
            if (~isempty(filedigest))
                savejson('', filedigest, 'filename', fullfile(outputfolder, relpath, [fname, '.json']), opt);
            end
            clear filedigest fh;
        else
            warning('file format unsupported: %s\nplease use the "converters" parameter to add plug-in to format-specific parsers', fullname);
        end
    catch ME
        error('faile to convert file %s, with error\n\t"%s"', fullname, ME.message);
    end
end

%%
function files = recursivelist(rootdir)

files = dir(rootdir);
if (~isfield(files, 'folder')) % for old matlab
    files = arrayfun(@(x) setfield(x, 'folder', rootdir), files);
end
for i = 1:length(files)
    if (files(i).isdir && ~ismember(files(i).name, {'.', '..'}))
        files = [files; recursivelist(fullfile(files(i).folder, files(i).name))];
    end
end
