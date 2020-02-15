# COVID-19 Genomic Data and GenBank GBFF File to JSON Converter

* Author: Qianqian Fang <q.fang at neu.edu>
* License: Data files in the data folder are in the public domain; BSD License for codes in the src folder
* Version: 0.5
* URL: http://github.com/fangq/covid19

**Table of content**
- [Overview](#overview)
- [How to parse genomic data files](#how-to-parse-genomic-data-files)
  * [Using data in Python](#using-data-in-python)
    + [JSON files](#json-files)
    + [JData files](#jdata-files)
    + [Pickle files](#pickle-files)
    + [HDF5 files](#hdf5-files)
    + [MessagePack files](#messagepack-files)
    + [How to access individual data records in Python](#how-to-access-individual-data-records-in-python)
  * [Using data in MATLAB/Octave](#using-data-in-matlaboctave)
    + [JSON files](#json-files-1)
    + [JData files](#jdata-files-1)
    + [MAT files](#mat-files)
    + [HDF5 files](#hdf5-files-1)
    + [MessagePack files](#messagepack-files-1)
    + [How to access individual data records in MATLAB/Octave](#how-to-access-individual-data-records-in-matlaboctave)
- [How to use the gbff2json converter](#how-to-use-the-gbff2json-converter)
- [Contribute to this project](#contribute-to-this-project)

## Overview

We provide a GenBank *.gbff* file to JSON converter and various converted 
formats for the recently sequenced COVID-19 coronavirus genomic data, with 
a hope to facilitate automated processing in computer programs using Python, 
MATLAB, Javascript etc.

The source of the COVID-19 gemonic data is downloaded from NIH NCBI GenBank
repository:

https://www.ncbi.nlm.nih.gov/nuccore/NC_045512

The follow data formats are provided:

- **\*.gbff**: original GenBank gbff data format (https://www.ncbi.nlm.nih.gov/Sitemap/samplerecord.html)
- **\*.json**: text-based JSON file (http://json.org)
- **\*.mat**: MATLAB/GNU Octave .mat format (https://www.mathworks.com/help/pdf_doc/matlab/matfile_format.pdf)
- **\*.pickle**: Python pickle format (https://docs.python.org/3/library/pickle.html)
- **\*.jdt**: text-based JData (JSON compatible) format (http://openjdata.org)
- **\*.jdb**: binary JData (UBJSON compatible) format (http://openjdata.org and http://ubjson.org)
- **\*.h5**: HDF5 format (https://www.hdfgroup.org/solutions/hdf5/)
- **\*.msgpk**: MessagePack format (https://msgpack.org)

Most of the above data formats are widely supported data exchange formats, and can be 
loaded and processed in a variety of programming environments. Among these data formats,
we strongly recommend .json and .jdt formats because they are both human-readable and
easy to parse/convert.


## How to parse genomic data files

### Using data in Python

To load the data in python, one can use the below sample codes

#### JSON files
```
import json
from collections import OrderedDict

with open('datafile.json') as f:
    covid19= json.load(f,object_pairs_hook=OrderedDict);
```
if you do not attach `object_pairs_hook=OrderedDict` in the above command, the generated
`dict` object may have random orders in the subfields.


#### JData files

First, install the pyjdata package via
```
pip install jdata
```

then open python, and run
```
import jdata
from collections import OrderedDict
covid19=jdata.loadt('datafile.jdt',object_pairs_hook=OrderedDict);
```
to load the text-based JData file, or first install the py-ubjson package
```
pip install py-ubjson
```
and then load the binary jdata file using
```
import jdata
covid19=jdata.loadb('datafile.jdb');
```
to load the binary-version of the jdata file.

#### Pickle files
```
import pickle
covid19=pickle.load( open( "datafile.pickle", "rb" ) )
```

#### HDF5 files
```
import h5py
covid19=h5py.File('datafile.h5','r')
```


#### MessagePack files

First, install the msgpack package via
```
pip install msgpack
```

then open python, and run
```
import msgpack
with open('datafile.msgpack') as fd:
    covid19 = msgpack.unpack(fd)
```

#### How to access individual data records in Python

Once the data is loaded in Python, the full data structured is typically stored as a nested `dict` object.
One can access the individual subfields via python's standard object indexing and reference methods. For 
example, 

```
  covid19('Version')   # this prints the Version subfield in the top level
  covid19['Features']['Location/Qualifiers']['gene'].keys()         # print the gene positions
  covid19['Features']['Location/Qualifiers']['gene']['266..21555']  # print the gene between positions 266 and 21555
  len(covid19['Origin'])     # print the genome sequence length
  covid19['Origin'][0:10]    # print the first 10 nucleotide bases
```

### Using data in MATLAB/Octave

To load the data in MATLAB/Octave, one should first download and install JSONLab toolbox from

https://github.com/fangq/jsonlab

To read the compressed JData files in Octave (not needed in MATLAB), one shall also
install the ZMat toolbox from 

https://github.com/fangq/zmat

If you use Fedora Linux, these toolboxes can be installed via

```
sudo dnf install octave-jsonlab
```

#### JSON files
```
covid19=loadjson('datafile.json');
```

If you do not have JSONLab, in MATLAB 2018a or newer, you can also use the below command to load the JSON data

```
covid19=jsondecode(fileread('datafile.json'));
```

#### JData files

The text-based JData file is directly supported by JSONLab
```
covid19=loadjson('datafile.jdt');
```
similarly, the binary JData file can be loaded as
```
covid19=loadubjson('datafile.jdb');
```

#### MAT files

Loading the .mat file does not need any additional toolboxes as it is the native
format for MATLAB. One can simply
```
load GCF_009858895.2_ASM985889v3_genomic.gbff_matlab.mat
```
This will produce a struct variable named `covid19` in the 'base' workspace.

#### HDF5 files

To load the hdf5 file in MATLAB using a single command, you need to download
the EasyH5 toolbox from the below links

https://github.com/fangq/easyh5

then you can load the file using

```
covid19=loadh5('datafile.h5');
```

#### MessagePack files

The MessagePack-format is also supported by JSONLab
```
covid19=loadmsgpack('datafile.msgpack');
```
#### How to access individual data records in MATLAB/Octave

Once the data is loaded in Python, the full data structured is typically stored as a nested `dict` object.
One can access the individual subfields via python's standard object indexing and reference methods. For 
example, 

```
  covid19.Version   # this prints the Version subfield in the top level
  fieldnames(covid19.Features.Location_Qualifiers.gene)         # print the gene positions
  covid19.Features.Location_Qualifiers.gene.From_266_to_21555   # print the gene between positions 266 and 21555
  length(covid19.Origin)     # print the genome sequence length
  covid19.Origin(1:10)    # print the first 10 nucleotide bases
```

## How to use the gbff2json converter

The `gbff2json` converter is a Perl script that converts GenBank gbff files to a JSON file.
To see the help information, simply type `gbff2json.pl` without any parameter. The below 
help info will be printed

```
gbff2json.pl - converting GenBank database file to a JSON/JData file
	Format: gbff2json.pl <options> input.gbff > output.json
The supported options include (multiple parameters can be used, separated by spaces)
	-m	convert key names to MATLAB friendly forms, otherwise, keeps the original key names
	-C	use all-caps for top-level key names, otherwise, capitalize only the first letter
	-c	print JSON in compact form, otherwise, print in the indented form
```

Example commands using this script include
```
gbff2json.pl datafile.gbff                    # print the JSON output to the terminal
gbff2json.pl datafile.gbff > datafile.json    # print the JSON output to a file
echo datafile.gbff | gbff2json.pl -m          # read from pipe and convert key names to remove special letters
echo datafile.gbff | gbff2json.pl -c >out.json# read from pipe and output compact JSON format
```

For better readability and easy extension, `gbff2json` makes the below minor changes
to the original gbff data entry names:

- the top-level keys (`LOCUS, VERSION, ORIGIN` ...) are converted to keep only capital form 
  for the first letter. One can revert to the all-caps version by adding the `"-C"` flag
- the _matlab.json file contains a JSON structure with converted key-names to facilitate 
  data manipulation in MATLAB/Octave. Because special characters can not be used as structure
  field names, we converted range operators `xxxxx..xxxxx` to `From_xxxxx_to_xxxxx`, and replaced
  "/", "(", ")" and "," to "_"

## Contribute to this project

Please submit your bug reports, feature requests and questions to the Github Issues page at

https://github.com/fangq/covid19/issues

Please feel free to fork our software, making changes, and submit your revision back
to us via "Pull Requests". gbff2json is open-source and welcome to your contributions!

