![](https://neurojson.org/wiki/upload/neurojson_banner_long.png)

BIDS-to-JSON Converter for MATLAB/Octave
========================================================================================

* Maintainer: Qianqian Fang <q.fang at neu.edu>
* License: BSD License, see LICENSE_BDS.txt
* Version: 0.8
* URL: https://neurojson.org/
* Compatibility: MATLAB R2010b or newer, GNU Octave 4.4 or newer
* Acknowledgement: This project is supported by US National Institute of Health (NIH) 
  grant [U24-NS124027](https://neurojson.org)


This toolbox extracts searchable data and metadata and creates
both human and machine-readable "digest" in the form of JSON
(JavaScript Object Notation) files. These JSON based dataset digests
can be used for version control, local query (using `jq`), scale-up
via document-oriented/hierarchical databases or easy integration and
automation between data analysis pipelines.


## Installation

The BIDS JSON-digest (JBIDS) toolbox has the below lightweight toolboxes as
dependencies (also provided as submodules inside the `tools` subfolder)

- JSONLab toolbox: https://neurojson.org/jsonlab
- JNIFTY toolbox: https://github.com/NeuroJSON/jnifty
- JSNIRF toolbox: https://github.com/NeuroJSON/jsnirfy
- EasyH5 toolbox: https://github.com/NeuroJSON/easyh5
- ZMat toolbox (https://github.com/NeuroJSON/zmat) - not needed for MATLAB,
  required for Octave (to unzip .nii.gz files)

## How to use

This toolbox can create JSON digests for subject-level data folders as well
as BIDS datasets. It can be done in just a few function calls

```matlab
%% Step 1: scan and extract searchable information and convert to JSON
bids2json('/path/to/bids/dataset', '/path/to/outputfolder');

%% Step 2: merge all extracted JSON digest files into a single JSON file
bidsdigest('/path/to/outputfolder', '/path/to/digest.json');

%% Optional step: upload the JSON digest file to NoSQL database for query
json2couch('/path/to/digest.json', 'https://example.com:5984', 'dbname', 'ds001', options)

%% Optional step: dataset local query via jq (output can be parsed by loadjson)
! jq '.bids_dataset_info."participants.tsv".age' digest.json
```

## Supported formats

Currently, this toolbox provides built-in metadata/digest extraction from
a number of BIDS formats, including

| Format       | Header data (searchable)                         | Attachment |
| ------------ | ------------------------------------------------ | ---------- |
| .json sidecar| directly copy to output                          | N/A        |
| .nii/.nii.gz | call nii2jnii to extract JNIFTI header           | must enable|
| .tsv         | call loadbidstsv to conver to JSON               | N/A        |
| .tsv.gz      | call loadbidstsv to conver to JSON (must enable) | N/A        |
| .jpg/.tif    | call img2jbids/imfinfo to extract core header    | must enable|
| .png/.bmp    | call img2jbids/imfinfo to extract core header    | must enable|
| .snirf       | call snirf2jbids/loadsnirf to extract most fields| must enable|
|README/LICENSE| stored as a JSON string                          | N/A        |
|README.md     | stored as a JSON string                          | N/A        |
|CHANGES       | stored as a JSON string                          | N/A        |
|CITATION.cff  | stored as a JSON string                          | N/A        |

## Why JSON

The JBIDS toolbox is developed by the NeuroJSON project
(https://neurojson.org). The core mission of the NeuroJSON project is 
to make scientific data, including multi-modal neuroimaging data, both
human and machine-readable, self-explanatory, easy-to-reuse, scalable, 
and easy-to-share between programming environments and software pipelines.

We believe that human-readability is the key to ensure the long-term
reusability of complex datasets and, as a result, we strongly advocate the
use of **standardized container data formats**, such as JSON and binary
JSON, to store hierachical data and metadata, as opposed to using
vendor, modality, software specific data formats that may lead to
prohibitive maintenance cost in the long term.

The JSON format is internationally standardized (ISO/IEC 21778:2017),
human-readable, ubiquitously supported with a large ecosystem that permits
fast parsing, databasing capabilities, easy query and web-readiness. It has
been the _de facto_ standard for data exchange in today's IT industry with
numerous tools and resources.

It is our vision that adopting JSON and binary JSON for neuroimaging data
sharing can greatly simplify data parsing and exchange in the increasingly 
complex neuroimaging data acquisition and data analysis, and can readily
benefit from the highly efficient modern database and parsers for storage
of large, complex neuroimaging datasets.

## How to contribute

Please submit your bug reports, feature requests and questions to the
Github issues page at

https://github.com/NeuroJSON/jbids/issues

Please feel free to fork our software, making changes, and submit your
revision back to us via "Pull Requests". JBIDS toolbox is open-source and
we welcome your contributions!
