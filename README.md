# RangeHandling

RangeHandling is a Perl library for handling sequences of labels or data structures sorted by numerical stamps that represent ranges. It can be used as a tool for dealing with Praat's Interval-Tier TextGrid files.

## Description

It represents internally a data structure formed by objects called `Range`, `Node` and `Chain`. In essence, a `Chain` object contains a collection of `Node` objects. A `Node` object contains a `Range` object and stores a value (either a `HASH` reference, an `ARRAY` reference or a `SCALAR`). A `Range` object represents numerical stamps. Additionally, the library provides a way for reading and editing Praat's Interval-Tier TextGrid files. Such functionality is implemented by using `TextGrid` objects.

## License

RangeHandling is provided as an open source utility. Use it as you please in as many projects or computing devices as you want. However, do clearly link to this repository ([https://gitlab.com/SantiagoYepez/RangeHandling](https://gitlab.com/SantiagoYepez/RangeHandling)) in case of any full or partial use of the software as:

```
@software {yepezRangeHandling,
    author = {Yépez, Edgar},
    title = {RangeHandling},
    url = {https://gitlab.com/SantiagoYepez/RangeHandling},
    year = {2018}
}
```

It is allowed to use the software for commercial purposes. 

RangeHandling is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

In case of having any comments, suggestions or even finding issues, send an e-mail to [edgaryepezec@gmail.com](edgaryepezec@gmail.com).

## Install

By the moment, the only way to get the library is by manually downloading or cloning this repository. Once downloaded, copy the `YERangeHandling` directory either into a Perl module's directory, so that it is globally available, or into a directory in where its usage is expected.

The library was programed and tested in Perl 5, version 26, subversion 1 (v5.26.1). It is no warrantied it will work in any other Perl versions (not even in v5.26.1 :-) ).

A `cpan` link is coming soon. 

## Usage

Refer to the  `USAGE.md` file.
