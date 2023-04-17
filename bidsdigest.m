function data = bidsdigest(jbidsfolder, outputfile, rootname, varargin)
%
%    bidsdigest(jbidsfolder, outputfile, rootname)
%         or
%    data = bidsdigest(jbidsfolder, outputfile, rootname, 'param1', value1, 'param2', value2, ...)
%
%    Merging all JSON-wrapped searchable BIDS data files into a single
%    JSON-formatted BIDS digest file for automation and integration
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        jbidsfolder: the folder storing bidssub2json or bids2json outputs
%        outputfile: the output BIDS digest JSON file name; if missing,
%               returns data in memory; one can also set the file extension
%               to .jbd/.bjd to save the output to a binary JSON file
%               (https://neurojson.org/bjdata/draft2), .h5 to an HDF5
%               (https://hdfgroup.org) file, .msgpack to a messagepack file
%               or a .ubj to a UBJSON (https://ubjson.org) file
%        rootname: the root object name; if not given, use ''
%        optional param/value pairs: these additional param/value pairs
%               will be passed to loadjd and savejd functions provided by
%               JSONLab (https://neurojson.org/jsonlab) to customize
%               loading/saving options
%
%    output:
%        data: a struct containing the parsed JSON-encoded data/metadata of
%              the specified BIDS folder
%
%    examples:bids2json(', '/tmp/ds1', 'filter', '^sub-0[3-5]$');
%        bidsdigest('/path/to/ds1/sub-01', '/tmp/bids/sub-01.json')
%        bidsdigest('/path/to/ds1/sub-02', '/tmp/bids/sub-02.json', 'sub-02', 'compact', 1)
%        data = bidsdigest('/path/to/ds1')
%        disp(data.README)
%
%    license:
%        BSD license, see LICENSE_BSD.txt files for details
%
% -- this function is part of JBIDS toolbox (https://neurojson.org/#software)
%

if (nargin < 3)
    rootname = '';
end

opt = varargin2struct(varargin{:});
if (~isfield(opt, 'usemap'))
    opt.usemap = 1;
end

json = parsefolder(jbidsfolder, opt);

if (nargin > 1)
    savejd(rootname, json, 'filename', outputfile, opt);
end

if (nargout >= 1 || nargin < 2)
    data = json;
end

%%
function json = parsefolder(foldername, varargin)

jbids = dir(foldername);
if (~isfield(jbids, 'folder')) % for old matlab
    jbids = arrayfun(@(x) setfield(x, 'folder', foldername), jbids);
end
json = containers.Map;

for i = 1:length(jbids)
    fname = jbids(i).name;
    if (~isempty(regexp(jbids(i).folder, ['\' filesep '\.att$'], 'once')))
        continue
    end
    if (jbids(i).isdir)
        % if foldername.json exist, it is a previously generated digest and
        % the folder will not be scanned again
        if (~isempty(dir(fullfile(jbids(i).folder, jbids(i).name, '.jbids'))))
            continue
        end
        if (isempty(regexp(fname, '^\.', 'once')))
            json(fname) = parsefolder(fullfile(jbids(i).folder, fname));
        end
        continue
    end
    fullname = fullfile(jbids(i).folder, fname);
    fprintf(1, 'merging %d [%s]\n', i, fullname);

    origfile = regexprep(fname, '\.jbids$|\.jnii$', '');
    origfile = regexprep(origfile, '\.tsv.json$', '.tsv');

    json(origfile) = loadjd(fullname, 'jdatadecode', 0, varargin{:});
end
