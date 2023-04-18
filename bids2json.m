function bids2json(datasetpath, outputfolder, varargin)
%
%    bids2json(datasetpath, outputfolder)
%       or
%    bids2json(datasetpath, outputfolder, 'param1',value1, 'param2',value2,...)
%
%    Converting a BIDS (brain imaging data structure) dataset, including
%    all subject folders, into searchable, human-readable and
%    easily-interoperable JSON files; non-searchable binary data are
%    also stored as `attachments' to accompany the output searchable files.
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        datasetpath: the root-folder to a BIDS dataset; the required
%                     root-level files such as README/LICENSE and
%                     dataset_description.json and participants.* are
%                     merged and stored in a single json file as
%                     bids_dataset_info.json inside outputfolder
%        outputfolder: the root folder in which all converted JSON files
%                     are written; the output files are organized in the
%                     same folder structure as in the source folder; the
%                     non-searchable binary data are stored inside the
%                     attachment folder, which is by default located at
%                     [outputfolder '/.att/'], unless changed by user
%                     options, see below/
%        options: (optional) for additional 'param',value pairs are passed
%                     to bidssub2json and savejson functions control the
%                     behavior of the conversion and output JSON formats.
%                     Please see the help info for bidssub2json and
%                     savejson for all supported options; bids2json
%                     specific options include
%
%             filter: a regular-expression string that allows users to
%                     convert a specific set of subject folders.
%             digest: [1|0] if set to 1 (default), a .jbids file will be
%                     generated for each subject data folder scanned.
%             digestfile: the JSON digest file (.jbids) that includes
%                     dataset-level metadata (such as
%                     README/LICENSE/CHANGES). If not given,
%                     'bids_dataset_info' is used.
%             skipexisting: [1|0] if set to 1 (default), a subject folder
%                     with a previously generated .jbids digest file will
%                     be skipped
%
%    examples:
%        bids2json('ds001', '../digest/ds001');
%        json=bids2json('/full/path/ds1', '/tmp/ds1', 'filter', '^sub-0[3-5]$');
%
%    license:
%        BSD license, see LICENSE_BSD.txt files for details
%
% -- this function is part of JBIDS toolbox (https://neurojson.org/#software)
%

if (nargin < 2)
    error('one must provide both input BIDS dataset folder and output folder');
end

opt = varargin2struct(varargin{:});
subfilter = jsonopt('filter', '', opt);
createdigest = jsonopt('digest', 1, opt);
skipexisting = jsonopt('skipexisting', 1, opt);

try
    bids = dir(datasetpath);
catch ME
    error('failed to open bids folder %s due to error\n\t"%s"', datasetpath, ME.message);
end

if (exist(fullfile(outputfolder), 'dir') == 0 && mkdir(fullfile(outputfolder)) == 0)
    error('failed to create output folder %s', fullfile(outputfolder));
end

if (~isfield(bids, 'folder')) % for old matlab
    bids = arrayfun(@(x) setfield(x, 'folder', datasetpath), bids);
end

info = containers.Map;

% scan and index dataset top-level data files

for i = 1:length(bids)
    if (bids(i).isdir)
        continue
    end

    fname = bids(i).name;
    fullname = fullfile(bids(i).folder, bids(i).name);
    fprintf(1, 'processing %d [%s]\n', i, fullname);

    try
        if (ismember(fname, {'README', 'CHANGES', 'LICENSE', 'README.md', 'CITATION.cff'}))
            info(fname) = fileread(fullname);
        elseif (~isempty(regexp(fname, '\.json$', 'once')))
            info(fname) = loadjson(fullname, opt);
        elseif (regexp(fname, '\.tsv(\.gz)*$'))
            info(fname) = loadbidstsv(fullname);
        else
            warning('file format unsupported: %s', fullname);
        end
    catch ME
        error('faile to convert file %s, with error\n\t"%s"', fullname, ME.message);
    end
end

% save dataset information to bids_dataset_info.jbids

if (~isempty(info))
    savejson('', info, 'filename', fullfile(outputfolder, [jsonopt('digestfile', 'bids_dataset_info', opt) '.jbids']), opt);
end

% scan and process all or selected subject folders

for i = 1:length(bids)
    if (bids(i).isdir && ~ismember(bids(i).name, {'.', '..', '.git', '.github'}))
        fname = bids(i).name;
        if ((isempty(subfilter) || ~isempty(regexp(fname, subfilter, 'once'))) && ...
            ~(skipexisting && ~isempty(dir([outputfolder filesep fname '.jbids']))))
            fprintf(1, 'processing %d [%s]\n', i, fname);
            bidssub2json(fullfile(bids(i).folder, fname), [outputfolder filesep fname], 'attroot', outputfolder, varargin{:});
            if (createdigest)
                bidsdigest(fullfile(outputfolder, fname), [outputfolder filesep fname '.jbids']);
            end
        end
    end
end
