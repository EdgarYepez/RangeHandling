# RangeHandling

## Description

RangeHandling is a Perl library for dealing with sequences of data structures organized by numerical stamps. Timelines or time-aligned data, like labelled or annotated media corpuses, are common instances of such sequences.

### Use case

Although not being specifically intended for it, a typical use case of this library comes when dealing with Praat's interval-tier `.TextGrid` files, as the library provides a way to parse and convert such files into the corresponding library's output objects. However, library's output objects from parsers written on demand for other interval-tier file types, such as `.mlf` or `.xra`, will work fine. 

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

**RangeHandling is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. It was written and tested in Perl 5, version 26, subversion 1 (`v5.26.1`) and there are no warranties that it might work in any other Perl version, not even in `v5.26.1`.**

In case of having any comments, suggestions or finding issues, send an e-mail to edgaryepezec@gmail.com.

## Installation and usage

Visit the [usage page](https://gitlab.com/SantiagoYepez/RangeHandling/wikis/Usage).