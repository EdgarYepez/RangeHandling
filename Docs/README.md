# RangeHandling - Usage guide *(under development)*

## Introduction

RangeHandling provides an interface for performing operations on sequences of data structures that are enclosed within ranges or intervals. Its core is made up of three classes: `Range`, `Node` and `Chain`. An object of the `Range` class holds the numerical stamps that create the range/interval within which data structures will be enclosed. An object of the `Node` class, on the other hand, stores such data structures along with the corresponding `Range` object. Data stored by a `Node` object may be either of Perl's `HASH`, `ARRAY` or `SCALAR` kind. Finally, an object of the `Chain` class stores a collection of `Node` objects and is responsible for having them neatly organized by their `Range` objects. The following picture shows a graphical representation of the mentioned objects:

![](.\img\explain graph.svg)

Additionally, the library provides a parser for Praat's interval-tier `.TextGrid` files that convert them into the corresponding `Range`, `Node` and `Chain` output objects.

The following paragraphs describe each class, its methods and how to use them.

### First steps

#### Installation

Download the library's source code from the [https://gitlab.com/SantiagoYepez/RangeHandling](https://gitlab.com/SantiagoYepez/RangeHandling) repository and copy the `YERangeHandling` directory either into a Perl module's directory, so that it is globally available, or into a directory in where its usage is expected. Then, add the following reference to the library inside the corresponding main script:

```perl
use YERangeHandling::Chain;
```

This instruction will make the `Range`, `Node` and `Chain` classes available throughout the script.

**Note 1:** By adding the mentioned reference to the main script, a helper class called `esylio` will also be made available. Such class is intended to be used exclusively by the library's classes; and its methods should not be directly called from the main script.

**Note 2:** In case the `YERangeHandling` directory is not located inside one of the paths kept by the `@INC` variable (Perl modules' paths), it may be desired to add the following instruction before referencing the library:

```perl
use lib <path>;
```

where `<path>` corresponds to the directory where the `YERangeHandling` directory lies. Thus and if the `YERangeHandling` directory lies alongside the main script, the complete reference should look like:

```perl
use lib '.';
use YERangeHandling::Chain;
```

**Note 3 - For users of `.TextGrid` files:** In case the usage of the library's parser for `.TextGrid` files is required, instead of adding the reference mentioned above, do add the following one which will also make a class called `TextGrid` available throughout the main script:

```perl
use YERangeHandling::TextGrid;
```

Statements exposed in both **Note 1** and **Note 2** still apply.

### Guide organization

Description of classes and their methods are presented in the following order:

1. `Range` class
2. `Node` class
3. `Chain` class
4. `TextGrid` class

In some cases, samples of code might be given.

## `Range` class

The `Range` class is responsible for storing and managing two numerical stamps, minimum and maximum. Thus, this class provides the boundaries for further enclosing data structures.

### Methods

#### `new`

It creates a new instance of the class.

```perl
my $range = Range->new($min, $max, $trimFunction);
```
##### Arguments

| Name            | Description                                                  | Mandatoriness | Default value               |
| :-------------- | :----------------------------------------------------------- | ------------- | --------------------------- |
| `$min`          | Numerical value that represents the minimum stamp. See **Note 1**. | Mandatory     |                             |
| `$max`          | Numerical value that represents the maximum stamp. See **Note 1**. | Mandatory     |                             |
| `$trimFunction` | `CODE` reference for trimming decimals. See **Note 2**.      | Optional      | `sub { return 0 + shift; }` |

**Note 1:** The `$max` argument must be greater than or equal to the `$min` argument, or else the following error will be thrown:

```
Maximum value must be greater than or equal to minimum value.
```

Either positives, negatives, integers, decimals, and zero are allowed values to take place in the `$min` and `$max` arguments.

**Note 2:** The `$trimFunction` argument is used for trimming both the minimum and maximum stamps as well as the result of any internal operation made with/to those stamps. Mandatorily, the `CODE` reference passed to it must return a numerical value.

It is suggested that the `CODE` reference be of the form:

```perl
my $trimFunction = sub { return 0 + sprintf '%.3f', shift; };
```

Therefore, a stamp such as `3.4579` will be treated as `3.458`.

##### Samples

**I 1:**

```perl
my $range = Range->new(0, 18.5);
```
**I 2:**

```perl
my $range = Range->new(-2.3333, 251, sub { return 0 + sprintf '%.3f', shift; });
```

------

#### `toString`

It returns the string representation of the current `Range` object.

```perl
my $str = $range->toString;
```

##### Samples

**I 1:**

```perl
print "Range: " . Range->new(1, 4)->toString;
```

**O 1:**

```
Range: 1 -> 4
```

------

#### `min`

It retrieves or sets the value for the minimum stamp of the current `Range` object.

**`min` as its retrieve behavior:**

```perl
my $min = $range->min;
```

**`min` as its set behavior:**

```perl
$range->min($stamp);
```

##### Arguments

| Name     | Description                                                  | Mandatoriness                   | Default value |
| -------- | ------------------------------------------------------------ | ------------------------------- | ------------- |
| `$stamp` | Numerical value that represents the new minimum stamp. See **Note 1** and **Note 2**. | Mandatory for the set behavior. |               |

**Note 1:** Only by passing a value to the `$stamp` argument will it make the `min` method act as its set behavior, still, it will always return a value. Either positives, negatives, integers, decimals, and zero are allowed values to take place in the `$stamp` argument. Note that passing `undef` will throw an error. Additionally, the `$trimFunction` argument attached to the current `Range` object (see the `new` method) is automatically applied on `$stamp`.

**Note 2:** **Using the `min` method as its set behavior is discouraged since it may cause logic errors when working alongside `Node` or `Chain` objects. Future versions of the library are meant to solve this issue.**

##### Samples

**I 1:**

```perl
my $range = Range->new(-40, 35.7);
print "Minimum value: " . $range->min . "\n";

$range->min(35);
print "Minimum value: " . $range->min;
```

**O 1:**

```
Minimum value: -40
Minimum value: 35
```

------

#### `max`

It retrieves or sets the value for the maximum stamp of the current `Range` object.

**`max` as its retrieve behavior:**

```perl
my $max = $range->max;
```

**`max` as its set behavior:**

```perl
$range->max($stamp);
```

##### Arguments

| Name     | Description                                                  | Mandatoriness                   | Default value |
| -------- | ------------------------------------------------------------ | ------------------------------- | ------------- |
| `$stamp` | Numerical value that represents the new maximum stamp. See **Note 1** and **Note 2**. | Mandatory for the set behavior. |               |

**Note 1:** Only by passing a value to the `$stamp` argument will it make the `max` method act as its set behavior, still, it will always return a value. Either positives, negatives, integers, decimals, and zero are allowed values to take place in the `$stamp` argument. Note that passing `undef` will throw an error. Additionally, the `$trimFunction` argument attached to the current `Range` object (see the `new` method) is automatically applied on `$stamp`.

**Note 2:** **Using the `max` method as its set behavior is discouraged since it may cause logic errors when working alongside `Node` or `Chain` objects. Future versions of the library are meant to solve this issue.**

##### Samples

**I 1:**

```perl
my $range = Range->new(6, 405);
print "Maximum value: " . $range->max . "\n";

$range->max(4000);
print "Maximum value: " . $range->max;
```

**O 1:**

```
Maximum value: 405
Maximum value: 4000
```

------

#### `trimDecimalFunction`

It retrieves or sets the decimal trimming `CODE` reference of the current `Range` object.

**`trimDecimalFunction` as its retrieve behavior:**

```perl
my $trimFunction = $range->trimDecimalFunction;
```

**`trimDecimalFunction` as its set behavior:**

```perl
$range->trimDecimalFunction($trimFunction);
```

##### Arguments

| Name            | Description                                                  | Mandatoriness                   | Default value               |
| --------------- | ------------------------------------------------------------ | ------------------------------- | --------------------------- |
| `$trimFunction` | The new `CODE` reference for trimming decimals. See **Note 1** and **Note 2**. | Mandatory for the set behavior. | `sub { return 0 + shift; }` |

**Note 1:** Only by passing a value to the `$trimFunction` argument will it make the `trimDecimalFunction` method act as its set behavior, still, it will always return a value. Mandatorily, the `CODE` reference passed must return a numerical value. Note that passing `undef` will set the default value.

It is suggested that `$trimFunction` be of the form:

```perl
my $trimFunction = sub { return 0 + sprintf '%.3f', shift; };
```

**Note 2:** When a new `CODE` reference is set, it is automatically applied on the minimum and maximum stamps of the current `Range` object.

##### Samples

**I 1:**

```perl
my $trimFunction1 = sub { return 0 + sprintf '%.3f', shift; };
my $trimFunction2 = sub { return 0 + sprintf '%.1f', shift; };

my $range = Range->new(13.5638, 42.43101, $trimFunction1);
print "Range: " . $range->toString . "\n";

$range->trimDecimalFunction($trimFunction2);
print "Range: " . $range->toString;
```

**O 1:**

```
Range: 13.564 -> 42.431
Range: 13.6 -> 42.4
```

------

#### `raw`

It returns both minimum and maximum stamps of the current `Range` object as an `ARRAY`.

```perl
my ($min, $max) = $range->raw;
```

##### Samples

**I 1:**

```perl
my $range = Range->new(14, 24);
my ($min, $max) = $range->raw;

print "Minimum stamp: $min\n"
print "Maximum stamp: $max";
```

**O 1:**

```
Minimum stamp: 14
Maximum stamp: 24
```

**I 2:**

```perl
my $range = Range->new(10, 45.6);
my @stamps = $range->raw;

my $sum = 0;
$sum += $_ for @stamps;

print "Sum of range's stamps: $sum";
```
**O 2:**

```
Sum of range's stamps: 55.6
```

------

#### `clone`

It returns a full cloned instance of  the current `Range` object.

```perl
my $rangeCopy = $range->clone;
```

##### Samples

**I 1:**

```perl
my $trimFunction = sub { return 0 + sprintf '%.3f', shift; };

my $range1 = Range->new(-100.234, 100.234, $trimFunction);
my $range2 = $range1->clone;

print "Range 1: " . $range1->toString . "\n";
print "Range 2: " . $range2->toString;
```

**O 2:**

```
Range 1: -100.234 -> 100.234
Range 2: -100.234 -> 100.234
```

------

#### `moveTo`

It displaces the minimum and maximum stamps so that the minimum one matches a given stamp.

```perl
$range->moveTo(
	$stamp # Mandatory numerical value to which the beginning stamp will match.
);
```

##### Arguments



##### Samples



------

#### `moveBy`

It displaces the beginning and ending stamps by a certain value.

```perl
$range->moveBy(
	$lapse # Mandatory numerical value by which to displace the beginning and ending stamps.
);
```

------

#### `scale`

It scales the beginning and ending stamps by a certain factor.

```perl
$range->scale(
	$factor # Mandatory numerical value to scale the beginning and ending stamps.
);
```

------

#### `difference`

It returns the numerical difference between the beginning and ending stamps.

```perl
my $diff = $range->difference;
```

------

#### `equals`

It returns whether the current `Range` object is equal to another `Range` object.

```perl
my $isEqual = $range->equals(
	$rangeObj # Mandatory `Range` object with which to compare.
);
```

------



## `Node` objects

A `Node` object represents labels or data structures within an interval. It is formed by some content and a `Range` object. Therefore, one can interpret `Node` objects as a representation of "content goes from this stamp to this other stamp".

#### Construction

```perl 
my $node = Node->new(
	$content, # Content to be stored within the `Node` object.
	$range # Mandatory `Range` object.
);
```

`$content` might be of either `HASH`, `ARRAY` or `SCALAR` type.

`$range` should be exclusive for each `Node` object.

#### Methods

##### `value`

It retrieves o sets the content of the `Node` object.

###### Retrieve

```perl
my $content = $node->value;
```

###### Set

```perl
$node->value(
	$content # Content to be stored within the `Node` object.
);
```

------

##### `range`

It retrieves the `Range` object of the `Node`.

```perl
my $range = $node->range;
```

------

##### `clone`

It returns a cloned instance of  the current `Node` object.

```perl
my $nodeCopy = $node->clone;
```

------

##### `equals`

It returns whether the current `Node` object is equal to another `Node` object in terms of content and `Range`.

```perl
my $isEqual = $node->equals(
	$nodeObj # Mandatory `Node` object with which to compare.
);
```

------

##### `toString`

It returns a string associated to the current `Node` object.

```perl
my $str = $node->toString;
```

#### Constants

##### `VOID`

It represents "no content".

```perl
Node->VOID
```

A `Node` object with "no content" might be constructed as:

```perl
my $node = Node->new(Node->VOID, $range);
```



## `Chain` objects

A `Chain` object stores a collection of `Node` objects sorted by their associated `Range` object. It can be understood as a sequence of `Node` objects.

**When a `Node` object is part of a `Chain` object, it is encouraged not to manually call the `min` nor the `max` methods of the `Node`'s `Range` object by their "set" functionality since they might cause logic errors. Future versions of the library are meant to solve this issue.**

#### Construction

```perl
my $chain = Chain->new(
	$name, # Mandatory `String` value that represents the name by which to identify the current `Chain` object.
	$allowNullLength, # Mandatory `Boolean` value that represents whether to keep `Node` objects whose associated `Range` has `difference` equal to zero.
	$defaultSafe, # Mandatory `Boolean` value that represents whether to automatically clone `Node` objects before performing any external operation with them. 
	$trimFunction # Optional `CODE` reference for trimming decimal stamps (defaults to: `sub { return 0 + shift; }`).
);
```

`$name` may be repeated among different `Chain` objects.

If a `$trimFunction` is provided, then it will override the `trimDecimalFunction` value of each `Node`'s `Range` object that exists or is inserted in the `Chain` object.

#### Methods

##### `name`

It retrieves o sets the name of the `Chain` object.

###### Retrieve

```perl
my $name = $chain->name;
```

###### Set

```perl
$chain->name(
	$name # Mandatory value that represents the name by which to identify the current `Chain` object.
);
```

**Using the `name` method as its "set" functionality when the `Chain` object is part of a `TextGrid` object is discouraged since it may cause errors of logic. Future versions of the library are meant to solve this issue.**

------

##### `allowNullLength`

It retrieves o sets whether to allow `Node` objects whose associated `Range` has the `difference` value equal to zero.

###### Retrieve

```perl
my $allowsZeroLength = $chain->allowNullLength;
```

###### Set

```perl
$chain->allowNullLength(
	$value # Mandatory `Boolean` value that represents whether to keep `Node` objects whose associated `Range` has `difference` equal to zero.
);
```

When `$value` is `0`, all `Node` objects with `difference` equals to zero will be automatically removed from the `Chain` object.

------

##### `defaultSafe`

It retrieves or sets whether to automatically clone `Node` objects before performing any external operation with them.

###### Retrieve

```perl
my $defaultSafe = $chain->defaultSafe;
```

###### Set

```perl
$chain->defaultSafe(
	$value # Mandatory `Boolean` value that represents whether to automatically clone `Node` objects before performing any external operation with them. 
);
```

------

##### `trimDecimalFunction`

It retrieves o sets a value for the decimal trimming function.

###### Retrieve

```perl
my $trimFunction = $chain->trimDecimalFunction;
```

###### Set

```perl
$chain->trimDecimalFunction(
	$value # Mandatory `CODE` reference to be the new decimal trimming `CODE` reference.
);
```

When a new trimming function is set, it gets automatically set in `Range` objects of  all `Node` objects in the Chain. If `allowNullLength` is `0` and, after applying the new trimming function, any `Node`'s `Range` object ends up having the `difference` value equal to zero, then that `Node` is automatically removed from the `Chain`.

------

##### `nodes`

It returns the collection of `Node` objects in a `Chain` as an `ARRAY`.

```perl
my @nodes = $chain->nodes;
```

------

##### `boundaries`

It returns a `Range` object composed of the beginning stamp of the first `Node` in the `Chain` and the ending stamp of the last `Node` in the `Chain`. If the `Chain` contains no `Node` objects, then it returns `undef`.

```perl
my $boundaries = $chain->boundaries;
```

------

##### `count`

It returns the number of `Node` objects in the `Chain`.

```perl
my $count = $chain->count;
```

------

##### `nodeAtIndex`

It returns the corresponding `Node` object at a certain index.

```perl
my $node = $chain->nodeAtIndex(
	$index, # Mandatory numerical value that represents the index.
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `indexAtStamp`

It returns the `Node`'s index at a certain stamp. It performs a binary search on the `Chain`'s `Node` objects, thus, it can receive optional left and right indexes to bound the lookup.

```perl
my $index = $chain->indexAtStamp(
	$stamp, # Mandatory numerical value that represents the stamp at which to find the index.
	$left, # Optional numerical value that represents the value to limit the lookup on the left (defaults to: `0`).
	$right # Optional numerical value that represents the value to limit the lookup on the right (defaults to: `$chain->count - 1`).
);
```

------

##### `nodeAtStamp`

It returns the `Node` at a certain stamp. If no `Node` is found, then `undef` is returned.

```perl
my $node = $chain->nodeAtStamp(
	$stamp, # Mandatory numerical value that represents the stamp at which to find a `Node` object.
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `indexesWithinRange`

It returns an `ARRAY` containing the first and last indexes within a given `Range` object.

```perl
my @indexes = $chain->indexesWithinRange(
	$range # Mandatory `Range` object within which to retrieve the indexes.
);
```

```perl
my ($firstIndex, $lastIndex) = $chain->indexesWithinRange($range);
```

------

##### `first`

It returns the first `Node` object in the `Chain`.

```perl
my $node = $chain->first(
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `last`

It returns the last `Node` object in the `Chain`.

```perl
my $node = $chain->last(
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `iterate`

It returns a `CODE` reference that, when executed, returns one `Node` object at a time. The returned `CODE` reference acts like an iterator.

```perl
my $iterator = $chain->iterate(
	$condition, # Optional `CODE` reference to filter the `Node` objects that get returned (defaults to: `sub { return 1; }`).
	$safe, # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
	@indexes # Optional numerical value `ARRAY` that represents the indexes of the `Node` objects to return (defaults to: `0 .. $chain->count - 1`).
);
```

`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # Candidate `Node` object to be returned by the iterator.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If $`node` should be returned by the iterator.
    $match = 0 # If $`node` should not be returned by the iterator.
    return $match;
};
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

###### Using the iterator

The iterator returned by this method should be executed by using one the following ways.

- To return only the next `Node` object:

```perl
my $node = $iterator->();
```

- To return the next `Node` object as well as its index and even override the `$safe` value:

```perl
my ($node, $index) = $iterator->(
	$returnIndex, # Optional `Boolean` value that represents whether to return the `Node`'s index (defaults to: `0`).
	$newSafe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `undef`).
);
```

If provided, `$newSafe` overrides the value of `$safe` within the scope of the iterator.

The iterator will return `undef` when no other `Node` object is left to return.

------

##### `iterateBackwards`

It returns a `CODE` reference that, when executed, returns one `Node` object at a time in reverse order. The returned `CODE` reference acts like an iterator.

```perl
my $iterator = $chain->iterateBackwards(
	$condition, # Optional `CODE` reference to filter the `Node` objects that get returned (defaults to: `sub { return 1; }`).
	$safe, # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
	@indexes # Optional numerical value `ARRAY` that represents the indexes of the `Node` objects to return (defaults to: `0 .. $chain->count - 1`).
);
```

Refer to the `iterate` method for how to use the returned iterator.

If the `@indexes` parameter is provided, then its contents will be reversed within the method.

------

##### `iterateWithinRange`

It returns a `CODE` reference that, when executed, returns one `Node` object at a time within a given `Range`. The returned `CODE` reference acts like an iterator.

```perl
my $iterator = $chain->iterateWithinRange(
	$range, # Optional `Range` object within which to return the `Node` objects (defaults to: `$chain->boundaries`).
	$condition, # Optional `CODE` reference to filter the `Node` objects that get returned (defaults to: `sub { return 1; }`).
	$goBackwards, # Optional `Boolean` value that represents whether to iterate in reverse order (defaults to: `0`).
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

Refer to the `iterate` method for details on the `$condition` and `$safe` parameters as well as for how to use the returned iterator.

------

##### `fillAndIterateWithinRange`

It returns a `CODE` reference that, when executed, returns one `Node` object at a time within a given `Range`. The returned `CODE` reference acts like an iterator. Such iterator will additionally return `Node` objects with filling content from intervals where no actual `Node` lies.

```perl
my $iterator = $chain->fillAndIterateWithinRange(
	$filling, # Mandatory value that represents the content with which to fill intervals where no `Node` object lies.
	$range, # Optional `Range` object to return the `Node` objects (defaults to: `$chain->boundaries`).
	$condition, # Optional `CODE` reference to filter the `Node` objects that get returned (defaults to: `sub { return 1; }`).
	$goBackwards, # Optional `Boolean` value that represents whether to iterate in reverse order (defaults to: `0`).
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before returning it (defaults to: `$chain->defaultSafe`).
);
```

When the iterator returns a `Node` of filling content, the corresponding index of such node is `-1`. Refer to the `iterate` method for details on the `$condition` and `$safe` parameters as well as for how to use the returned iterator.

------

##### `iterateAsMask`

It returns a `CODE` reference that, when executed, applies a mask on `Node` objects and then returns them one at a time.

```perl
my $iterator = $chain->iterateAsMask(
	$maskFunction, # Mandatory `CODE` reference that masks `Node` objects before they get returned.
	$condition # Optional `CODE` reference to filter the `Node` objects that get masked and returned (defaults to: `sub { return 1 }`).
);
```

 `$maskFunction` must be a `CODE` reference of the form:

```perl
$maskFunction = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    my $maskValue; 
    
    # ...
    # Stuff to do with $`node` and $index (actual masking).
    # ...
    
    return $maskValue; # Either `SCALAR`, `ARRAY` reference or `HASH` reference.
};
```

Refer to the `iterate` method for details on the `$condition` parameter as well as for how to use the returned iterator.

------

##### `yield`

It executes a given `CODE` reference on every `Node` object that matches a condition in the current `Chain` object.

```perl
$chain->yield(
	$function, # Mandatory `CODE` reference that gets executed on every `Node` object.
	$condition, # Optional `CODE` reference to filter the `Node` objects on which $function is executed (defaults to: `sub { return 1; }`).
	$safe, # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before $function is executed on it (defaults to: `$chain->defaultSafe`).
	@indexes # Optional numerical value `ARRAY` that represents the indexes of the `Node` objects on which to execute $function (defaults to: `0 .. $chain->count - 1`).
);
```

 `$function` must be a `CODE` reference of the form:

```perl
$function = sub {
    my (
    	$node, # `Node` object.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    return 1; # If it is desired to stop the yielding process.
    return 0; # If it is desired to continue the yielding process.
};
```

`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # Candidate `Node` object to be returned by the iterator.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If $function should be applied on $`node`.
    $match = 0 # If $function should not be applied on $`node`.
    return $match;
};
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `yieldBackwards`

It executes a given `CODE` reference on every `Node` object that matches a condition in the current `Chain` object in reverse order.

```perl
$chain->yieldBackwards(
	$function, # Mandatory `CODE` reference that gets executed on every `Node` object.
	$condition, # Optional `CODE` reference to filter the `Node` objects on which $function is executed (defaults to: `sub { return 1; }`).
	$safe, # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before $function is executed on it (defaults to: `$chain->defaultSafe`).
	@indexes # Optional numerical value `ARRAY` that represents the indexes of the `Node` objects on which to execute $function (defaults to: `0 .. $chain->count - 1`).
);
```

Refer to the `yield` method for details on the `$function`, `$condition` and `$safe` parameters.

If the `@indexes` parameter is provided, then its contents will be reversed within the method.

------

##### `yieldWithinRange`

It automatically executes a given `CODE` reference on every `Node` object returned by the iterator of the `iterateWithinRange` method.

```perl
$chain->yieldWithinRange(
	$function, # Mandatory `CODE` reference that gets executed on every `Node` object.
	$range, # Optional `Range` object within which to yield the `Node` objects (defaults to: `$chain->boundaries`).
	$condition, # Optional `CODE` reference to filter the `Node` objects that get yielded (defaults to: `sub { return 1; }`).
	$goBackwards, # Optional `Boolean` value that represents whether to yield in reverse order (defaults to: `0`).
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before yielding it (defaults to: `$chain->defaultSafe`).
);
```

Refer to the `yield` method for details on the `$function`, `$condition` and `$safe` parameters.

------

##### `fillAndYieldWithinRange`

It automatically executes a given `CODE` reference on every `Node` object returned by the iterator of the `fillAndIterateWithinRange` method.

```perl
$chain->fillAndYieldWithinRange(
	$function, # Mandatory `CODE` reference that gets executed on every `Node` object.
	$filling, # Mandatory value that represents the content with which to fill intervals where no `Node` object lies.
	$range, # Optional `Range` object within which to yield the `Node` objects (defaults to: `$chain->boundaries`).
	$condition, # Optional `CODE` reference to filter the `Node` objects that get yielded (defaults to: `sub { return 1; }`).
	$goBackwards, # Optional `Boolean` value that represents whether to yield in reverse order (defaults to: `0`).
	$safe # Optional `Boolean` value that represents whether to clone the corresponding `Node` object before yielding it (defaults to: `$chain->defaultSafe`).
);
```

Refer to the `yield` method for details on the `$function`, `$condition` and `$safe` parameters.

------

##### `yieldAsMask`

It automatically executes a given `CODE` reference on every `Node` object returned by the iterator of the `iterateAsMask` method.

```perl
$chain->yieldAsMask(
	$function, # Mandatory `CODE` reference that gets executed on every `Node` object.
	$maskFunction, # Mandatory `CODE` reference that masks `Node` objects before they get yielded.
	$condition # Optional `CODE` reference to filter the `Node` objects that get masked and yielded (defaults to: `sub { return 1; }`).
);
```

`$maskFunction` must be a `CODE` reference of the form:

```perl
$maskFunction = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    my $maskValue; 
    
    # ...
    # Stuff to do with $`node` and $index (actual masking).
    # ...
    
    return $maskValue; # Either `SCALAR`, `ARRAY` reference or `HASH` reference.
};
```

Refer to the `yield` method for details on the `$function` and `$condition` parameters.

------

##### `maskAs`

It returns a new instance of the current `Chain` object with a mask `CODE` reference applied on its `Node` objects.

```perl
my $maskChain = $chain->maskAs(
	$maskFunction, # Mandatory `CODE` reference that masks `Node` objects.
	$condition # Optional `CODE` reference to filter the `Node` objects that get masked (defaults to: `sub { return 1; }`).
);
```

`$maskFunction` must be a `CODE` reference of the form:

```perl
$maskFunction = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    my $maskValue; 
    
    # ...
    # Stuff to do with $`node` and $index (actual masking).
    # ...
    
    return $maskValue; # Either `SCALAR`, `ARRAY` reference or `HASH` reference.
};
```

`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If $maskFunction should be applied on $`node`.
    $match = 0 # If $maskFunction should not be applied on $`node`.
    return $match;
};
```

------

##### `maskAsNumber`

It returns a `Chain` object whose `Node` objects contain, each, numbers in order starting from a certain value.

```perl
$numberedChain = $chain->maskAsNumber(
	$start # Mandatory numerical value from which to start counting.
);
```

------

##### `maskAsAlphabet`

It counts the `Node` objects of the current `Chain` by using a given alphabet and returns a new `Chain` object whose `Node` objects contain the said count.

```perl
my $numberedChain = $chain->maskAsAlphabet(
	@alphabet # Mandatory `ARRAY` of numerical or `String` values that conform the alphabet with which to count.
);
```

`@alphabet` must contain at least two elements.

As an example, if it is desired to perform a hexadecimal count, the following instruction should be specified.

```perl
my $hexadecimalChan = $chain->maskAsAlphabet(0 .. 9, map { chr (65 + $_) } 0 .. 5);
```

------

##### `select`

It returns an `ARRAY` of all `Node` objects in the current `Chain` that match a given condition.

```perl
my @nodes = $chain->select(
	$condition, # Mandatory `CODE` reference to match the `Node` objects.
	$safe # Optional `Boolean` value that represents whether to clone the `Node` object (defaults to: `$chain->defaultSafe`).
);
```

`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If it is desired to select $`node`.
    $match = 0 # If it is not desired to select $`node`.
    return $match;
};
```

If provided, `$safe` overrides the value of `defaultSafe` within the scope of the method.

------

##### `splitAtStamp`

It splits a `Node` object in a `Chain` at a given stamp, thus producing two different `Node` objects that store the same content.

```perl
$chain->splitAtStamp(
	$stamp # Mandatory numerical value at which to perform the split.
);
```

------

##### `removeByIndexes`

It removes from the `Chain` the `Node` objects that lie at a given set of indexes.

```perl
$chain->removeByIndexes(
	@indexes # Mandatory numerical value `ARRAY` that represents the indexes of the `Node` objects to be removed.
);
```

------

##### `removeAll`

It removes all `Node` objects in the `Chain`.

```perl
$chain->removeAll;
```

------

##### `removeAs`

It removes from the current `Chain` all `Node` objects that match a given condition within a `Range`.

```perl
$chain->removeAs(
	$condition, # Mandatory `CODE` reference to match the `Node` objects that will be removed.
	$range, # Optional `Range` object within which to match the `Node` (defaults to: `$chain->boundaries`).
	$split # Optional `Boolean` value that represents whether to split `Node` objects at the stamps given by $`range` (defaults to: `0`).
);
```

`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If it is desired to remove $`node`.
    $match = 0 # If it is not desired to remove $`node`.
    return $match;
};
```

------

##### `clone`

It returns a cloned instance of  the current `Chain` object. If specified, `Node` objects of the `Chain` may be also cloned.

```perl
my $chainCopy = $chain->clone(
	$cloneNodes # Optional `Boolean` value that represents whether to also clone `Chain`'s `Node` objects (defaults to: `0`).
);
```

------

##### `insert`

It inserts a new `Node` object in the current `Chain`. If it is needed, existing `Node` objects will be removed so that the new one may accurately fit in the `Chain` and respect the order given by the contained `Range` objects.

```perl
$chain->insert(
	@nodes # Mandatory `ARRAY` of either `Node` objects, `Chain` objects, `Node` iterators or even a mixture of those that represents the `Node` objects to be inserted.
);
```

The provided `Node` objects will be inserted as given; no cloning operation is performed on them.

------

##### `fill`

It inserts `Node` objects into intervals of the current `Chain` where no `Node` objects lie.

```perl
$chain->fill(
	$filling, # Mandatory value that represents the content with which to fill up. 
	@ranges # Optional `Range` object `ARRAY` within which to fill up (defaults to: `$chain->boundaries`).
);
```

------

##### `merge`

It merges consecutive close Node objects with the same content.

```perl
$chain->merge(
	$type, # Optional merging type. Either Merging->INNER, Merging->BOUNDARIES or Merging->BOUNDARIES_INNER (defaults to Merging->INNER).
	@ranges # Optional `Range` object `ARRAY` within which to merge (defaults to: `$chain->boundaries`).
);
```

###### Constants of merging

- `Merging->INNER`: It specifies that the merging should be performed exclusively among `Node` objects inside the corresponding `Range`'s stamps.
- `Merging->BOUNDARIES`: It specifies that the merging should be performed exclusively with the `Node` objects at the corresponding `Range`'s stamps.
- `Merging->BOUNDARIES_INNER`: It specifies that the merging should be performed both among `Node` objects inside the corresponding `Range`'s stamps and with the `Node` objects at said `Range`'s stamps.

------

##### `subChain`

It returns a new `Chain` object that contains a clone of the current `Chain`'s `Node` objects that match a certain condition in a given `Range`.

```perl
my $subChan = $chain->subChain(
	$condition, # Optional `CODE` reference to match the `Node` objects that will be cloned (defaults to: `sub { return 1; }`).
	$range, # Optional `Range` object within which to match the `Node` objects (defaults to: `$chain->boundaries`).
	$split # Optional `Boolean` value  that represents whether to split `Node` objects at the stamps given by $`range` (defaults to: `0`).
);
```
`$condition` must be a `CODE` reference of the form:

```perl
$condition = sub {
    my (
    	$node, # `Node` object to be masked.
    	$index # Index of the `Node` object.
    ) = @_;
    
    # ...
    # Stuff to do with $`node` and $index.
    # ...
    
    my $match;
    $match = 1 # If it is desired to clone $`node` into $subChan.
    $match = 0 # If it is not desired to clone $`node` into $subChan.
    return $match;
};
```

------

##### `moveBy`

It iteratively calls the `moveBy` method of each `Range` object contained in the current `Chain`.

```perl
$chain->moveBy(
	$lapse # Mandatory numerical value to pass to `Range` objects' `moveBy` method.
);
```

------

##### `moveTo`

It iteratively calls the `moveTo` method of each `Range` object contained in the current `Chain`.

```perl
$chain->moveTo(
	$stamp # Mandatory numerical value to pass to the `Range` objects' `moveTo` method.
);
```

------

##### `scale`

It iteratively calls the `scale` method of each `Range` object contained in the current `Chain`.

```perl
$chain->scale(
	$factor # Mandatory numerical value to pass to the `Range` objects' `scale` method.
);
```

------

##### `toString`

It returns a string associated to the current `Chain` object.

```perl
my $str = $chain->toString;
```

------

##### `compare`

It performs a comparison between a given `Chain` object and the current one. The output consists of a new `Chain` composed of `Node` objects created by some given rules.

```perl
my $comparisonChain = $chain->compare(
	$target, # Mandatory `Chain` object against which to compare.
	@rules # Mandatory `ARRAY` of Rule objects to apply.
);
```

Every `Rule` object in `@rules` is executed until any of them returns a positive match.

###### Rules

A `Rule` object compares two `Node` objects as defined by a `CODE` reference and takes an action based on it.

A Rule object is created as follows:

```perl
$rule = Rule->new(
	$value, # Mandatory value to apply when the rule definition is positive.
	$ruleFunction # Mandatory `CODE` reference that represents the rule definition.
);
```

`$value` may be either a `SCALAR`, an `ARRAY` reference, a `HASH` reference or a `CODE` reference. If `$value` is a `CODE` reference, it must be of the form:

```perl
$value = sub {
    my (
    	$currentNode, # The `Node` object of the current `Chain`.
    	$targetNode # The `Node` object of the `Chain` against which it is being compared.
    ) = @_;
    
    # ...
    # Stuff to do with $currentNode and $targetNode.
    # ...
    
    my $decisionValue;
    return $decisionValue # Result of the comparison;
};
```

`$ruleFunction` must be of the form:

```perl
$ruleFunction = sub {
    my (
    	$currentNode, # The `Node` object of the current `Chain`.
    	$targetNode # The `Node` object of the `Chain` against which it is being compared.
    ) = @_;
    
    # ...
    # Stuff to do with $currentNode and $targetNode.
    # ...
    
    return 1; # If the rule applies.
    return 0; # If the rule does not apply.
};
```



## `TextGrid` objects

The `TextGrid` class offers an interface to parse Praat's Interval-Tier TextGrid files and to represent them as a collection of `Chain` objects. It currently supports only the Interval-Tier type. Within this class, a `Chain` object is called a `Tier`.

#### Construction

```perl
my $textGrid = TextGrid->new(
	$tgString, # Mandatory `String` value of either the path to a TextGrid file or its content itself.
	$trimFunction, # Optional `CODE` reference for trimming decimal stamps (defaults to: `sub { return 0 + shift; }`).
	$tiersToRead # Optional `CODE` reference for filtering the tiers to be read (defaults to: `sub { return 1; }`).
);
```

`$trimFunction` should be of the form:

```perl
$trimFunction = sub { return 0 + sprintf '%.3f', shift; };
```

`$tiersToRead` should be of the form:

```perl
$tiersToRead = sub {
    my (
    	$name, # Current `Tier`'s name.
    	$tierClass, # Current `Tier`'s type.
    	$tg # The current `TextGrid` object containing every tier that has been read.
    ) = @_;
    
    return 1; # If the $name `Tier` should be read.
    return 1; # If the $name `Tier` should not be read.
};
```

#### Methods

##### `count`

It returns the total number of  `Tier`s.

```perl
my $count = $textGrid->count;
```

------

##### `tierNames`

It returns an `ARRAY` of the `Tier` names.

```perl
my @names = $textGrid->tierNames;
```

------

##### `contains`

It checks whether the `TextGrid` object contains a `Tier` with a specified name.

```perl
my $contains = $textGrid->contains(
	$tierName # Mandatory `String` value that represents the name of the `Tier` object for which to check.
);
```

------

##### `relocate`

It changes the order of the `Tier` objects present in the `TextGrid`.

```perl
$textGrid->relocate(
	@names # Mandatory `String` `ARRAY` containing the `Tier` names in the desired order.
);
```

------

##### `tierAt`

It returns the `Tier` object (actually a `Chain` object) present at an index.

```perl
my $chain = $textGrid->tierAt(
	$index # Mandatory numerical value that represents the index at which to locate a `Tier`.
);
```

------

##### `tier`

It returns a `Tier` object (actually a `Chain` object) by its name.

```perl
my $chain = $textGrid->tier(
	$name # Mandatory `String` value that represents the name of the `Tier` to return.
);
```

------

##### `extract`

It removes and returns a `Tier` object (actually a `Chain` object) by its name from the current `TextGrid`.

```perl
my $chain = $textGrid->extract(
	$name # Mandatory `String` value that represents the name of the `Tier` to remove and return.
);
```

------

##### `yield`

It applies a given `CODE` reference on every `Tier` object of the current `TextGrid`.

```perl
$textGrid->yield(
	$function, # Mandatory `CODE` reference to be applied on the `Tier` objects.
	@names # Optional `String` `ARRAY` that represents the names of the tiers to yield (defaults to: `$textGrid->tierNames`).
);
```

 `$function` must be a `CODE` reference of the form:

```perl
$function = sub {
    my (
    	$chain, # Current `Chain` object.
    	$index # Index of the current `Chain` object.
    ) = @_;
    
    # ...
    # Stuff to do with $chain and $index.
    # ...
    
    return 1; # If it is desired to stop the yielding process.
    return 0; # If it is desired to continue the yielding process.
};
```

------

##### `tiers`

It returns an `ARRAY` containing all the Tier objects (actually `Chain` objects) in the current `TextGrid`.

```perl
my @tiers = $textGrid->tiers;
```

------

##### `remove`

It removes the specified `Tier` objects from the `TextGrid`.

```perl
$textGrid->remove(
	@names # Mandatory `String` `ARRAY` containing the names of the `Tier` objects to remove.
);
```

------

##### `removeAll`

It removes the all  `Tier` objects from the `TextGrid`.

```perl
$textGrid->removeAll;
```

------

##### `add`

It adds a set of `Tier` objects (actually `Chain` objects) at the end of the current `TextGrid`.

```perl
$textGrid->add(
	@tiers # Mandatory `ARRAY` of `Chain` objects containing the `Tier` objects to add.
);
```

------

##### `addAt`

It adds a  `Tier` object (actually `Chain` object) at a given index in the current `TextGrid`.

```perl
$textGrid->addAt(
	$tiers, # Mandatory `Tier` (`Chain`) object to add.
	$index # Mandatory numerical value that represents the index at which to add the `Tier`.
);
```

------

##### `boundaries`

It returns a `Range` object composed of the minimum of all the beginning stamps and the maximum of all the ending stamps among the `Tier` objects. If the `TextGrid` contains no `Tier` objects, then it returns `undef`.

```perl
$textGrid->boundaries;
```

------

##### `moveBy`

It iteratively calls the `moveBy` method of each `Tier` object contained in the current `TextGrid`.

```perl
$chain->moveBy(
	$lapse # Mandatory numerical value to pass to the `Tier` (`Chain`) objects' `moveBy` method.
);
```

------

##### `moveTo`

It iteratively calls the `moveTo` method of each `Tier` object contained in the current `TextGrid`.

```perl
$chain->moveTo(
	$stamp # Mandatory numerical value to pass to the `Tier` (`Chain`) objects' `moveTo` method.
);
```

------

##### `scale`

It iteratively calls the `scale` method of each `Tier` object contained in the current `TextGrid`.

```perl
$chain->scale(
	$factor # Mandatory numerical value to pass to the `Tier` (`Chain`) objects' `scale` method.
);
```

------

##### `merge`

It iteratively calls the `merge` method of each `Tier` object contained in the current `TextGrid` with `$type` equals to `Merging->INNER`.

```perl
$chain->merge;
```

------

##### `flash`

It creates a TextGrid file and saves it in the disk.

```perl
$textGrid->flash(
	$fileName, # Mandatory `String` value that represents the path to the TextGrid file.
    $longText, # Optional `Boolean` value that represents whether to write a 'long text' or 'short text' TextGrid file (defaults to: `0`).
    $value2TextFunction, # Optional `CODE` reference to convert `Node` objects' values into `String` (defaults to some `print` code).
    $codif, # Optional `String` value that represents the codification of the final file (defaults to: `utf-8`).
    @tierNames # Optional `String` `ARRAY` that represents the names of the `Tier`s to write into the TextGrid file (defaults to: `$textGrid->tierNames`).
);
```

`$value2TextFunction` must be of the form:

```perl
$value2TextFunction = sub {
    my $node = shift;
    
    # ...
    # Stuff to do with $`node`.
    # ...
    
    my $nodeString;
    return $nodeString;
};
```

`$codif` takes any of the Perl's codification string constants.

------

##### `toString`

It returns the text representation of a TextGrid file from the current `TextGrid` object.

```perl
$textGrid->toString(
	$longText, # Optional `Boolean` value that represents whether to write a 'long text' or 'short text' TextGrid file (defaults to: `0`).
    $value2TextFunction, # Optional `CODE` reference to convert `Node` objects' values into `String` (defaults to some `print` code).
    @tierNames # Optional `String` `ARRAY` that represents the names of the `Tier`s to write into the TextGrid file (defaults to: `$textGrid->tierNames`).
);
```

------

##### `clone`

It returns a cloned instance of  the current `TextGrid` object.

```perl
my $textGridCopy = textGrid->clone;
```