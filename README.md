# RangeHandling

## Description

RangeHandling is a Perl library whose main goal is to provide an easy way to deal with *time-aligned* data. In essence, it provides an interface for dealing with sequences of data structures organized by numerical stamps that enclose such data within a range or an interval, as commonly seen in labeled or annotated audio corpuses. 

Internally, the library is structured by objects called `Range`, `Node` and `Chain`. A `Range` object holds the numerical stamps that will enclose data. A `Node` object, on the other hand, stores such data along with a corresponding `Range` object, thus providing the notion that "*data begins at this stamp and ends at this other one*". Data stored by a `Node` object may be either of Perl's `HASH`, `ARRAY` or `SCALAR` kind. Finally, a `Chain` object is a collection of `Node` objects and is responsible for having them neatly organized by their `Range` objects. It can be seen as a time-line.

### Use case

Although not being specifically intended for it, a typical use case of this library comes when dealing with Praat's interval-tier `.TextGrid` files, as the library provides a way to parse and convert such files into the corresponding `Range`, `Node` and `Chain` output objects. Parsers for other interval-tier file types written on demand will work fine with the output objects they might produce. 

## License

RangeHandling is provided as an open source utility. Use it at will in as many projects or computing devices as desired. However, do clearly link to the repository [https://gitlab.com/SantiagoYepez/RangeHandling](https://gitlab.com/SantiagoYepez/RangeHandling) as following in case of any full or partial use of the library:

```
@software {yepezRangeHandling,
    author = {Yépez, Edgar},
    title = {RangeHandling},
    url = {https://gitlab.com/SantiagoYepez/RangeHandling},
    year = {2018}
}
```

It is allowed to use the software for commercial purposes. 

**RangeHandling is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.**

In case of having any comments, suggestions or finding issues, send an e-mail to [edgaryepezec@gmail.com](edgaryepezec@gmail.com).

## Installation

By the moment, the only way to get the library is by manually downloading it from or cloning the [https://gitlab.com/SantiagoYepez/RangeHandling](https://gitlab.com/SantiagoYepez/RangeHandling) repository. Once downloaded, copy the `YERangeHandling` directory either into a Perl module's directory, so that it is globally available, or into a directory in where its usage is expected.

The library was written and tested in Perl 5, version 26, subversion 1 (`v5.26.1`). It is not warrantied it will work in any other Perl version (not even in `v5.26.1`). 

## Usage

Visit the [Usage page](https://gitlab.com/SantiagoYepez/RangeHandling/wikis/Usage/Main).

## Examples

Refer to the `Examples` directory.