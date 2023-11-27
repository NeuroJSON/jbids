function [digestdata, attachdata] = snirf2jbids(fullname, varargin)
%
%    digestdata=snirf2jbids(fullname)
%      or
%    [digestdata, attachdata]=snirf2jbids(fullname, 'param1', value1, 'param2', value2, ...)
%
%    Parse a SNIRF (for fNIRS) data file to extract lightweight metadata
%    digest for easy query, along with optional organized bulk measurement
%    data for saving to non-searchable attachment files in a NoSQL database
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        fullname: the path of the snirf data file
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
%        [snirfheader, snirfdata]= snirf2jbids('/path/bs001/subj01/nirs/subj01_test.snirf');
%
%    license:
%        BSD license, see LICENSE_BSD.txt files for details
%
% -- this function is part of JBIDS toolbox (https://neurojson.org/#software)
%

opt = varargin2struct(varargin{:});
pathhash = jsonopt('pathhash', fullname, opt);
attachproto = jsonopt('attachproto', 'attach:', opt);

try
    snirf = struct('SNIRFData', loadsnirf(fullname, opt));
catch
    warning('encountered an error when processing %s', fullname);
    digestdata = [];
    attachdata = [];
    return
end

if (nargout > 1)
    attachdata = struct('data', snirf.SNIRFData.nirs.data);
    snirf.SNIRFData.nirs.data = struct(encodevarname('_DataLink_'), [attachproto pathhash '.jdb:$.data']);
    if (isfield(snirf.SNIRFData.nirs, 'aux'))
        attachdata.aux = snirf.SNIRFData.nirs.aux;
        snirf.SNIRFData.nirs.aux = struct(encodevarname('_DataLink_'), [attachproto pathhash '.jdb:$.aux']);
    end
else
    snirf.SNIRFData.nirs.data = [];
    if (isfield(snirf.SNIRFData.nirs, 'aux'))
        snirf.SNIRFData.nirs.aux = [];
    end
end

if (nargout >= 1)
    digestdata = snirf;
end
