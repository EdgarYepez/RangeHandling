package Chain;

	use utf8;
	use POSIX;
	use strict;
	use warnings;
	use YERangeHandling::Node;
	use YERangeHandling::esylio;

	sub new {
		my $class = shift;
		my ($id, $allowNullLength, $defaultSafe, $trimDecimalFunction) = @_;
		my $self = bless {
			nodes => [ ],
			id => undef,
			allowNullLength => $allowNullLength,
			defaultSafe => $defaultSafe,
			trimDecimalFunction => undef
		}, $class;
		$self->id($id);
		$self->trimDecimalFunction($trimDecimalFunction);
		return $self;
	}

	sub id {
		my $self = shift;
		if (@_) {
			my ($id) = @_;
			$self->{id} = $id;
		}
		return $self->{id};
	}

	sub name { return shift->id(@_); }

	sub allowNullLength {
		my $self = shift;
		if (@_) {
			my ($val) = @_;
			$val = 0 unless defined $val;
			$self->{allowNullLength} = $val;
			$self->removeAs(sub { return shift->range->difference == 0; }) unless $val;
		}
		return $self->{allowNullLength};
	}

	sub defaultSafe {
		my $self = shift;
		if (@_) {
			my ($val) = @_;
			$val = 1 unless defined $val;
			$self->{defaultSafe} = $val;
		}
		return $self->{defaultSafe};
	}

	sub trimDecimalFunction {
		my $self = shift;
		if (@_) {
			my ($code) = @_;
			$code = sub { return 0 + shift; } unless defined $code;
			esylio->assertRef2($code, "CODE", 1);
			$self->{trimDecimalFunction} = $code;
			$self->yieldByIndexes(sub {
				my ($node, $index) = @_;
				$node->range->trimDecimalFunction($code);
				return 0;
			}, undef, 0);
			$self->allowNullLength($self->allowNullLength);
		}
		return $self->{trimDecimalFunction};
	}

	sub nodes { return @{shift->{nodes}}; }

	sub boundaries {
		my $self = shift;
		return $self->count ? Range->new($self->first(0)->range->min, $self->last(0)->range->max, $self->trimDecimalFunction) : undef;
	}

	sub bounds { return shift->boundaries; }

	sub count { return 0 + shift->nodes; }

	sub nodeAtIndex {
		my $self = shift;
		my ($index, $safe) = @_;
		esylio->customDie("Empty node collection.") unless $self->count;
		esylio->customDie("No node at index $index. The node collection contains " . $self->count . " node" . ($self->count == 1 ? "" : "s") . "." ) if $index < 0 || $index >= $self->count;
		$safe = $self->defaultSafe unless defined $safe;
		my $node = $self->{nodes}->[$index];
		return $safe ? $node->clone : $node;
	}

	sub indexAtStamp {
		my $self = shift;
		my ($stamp, $izq, $der) = @_;
		esylio->customDie("Numeric value expected for 'value'.") unless esylio->isNumber($stamp);
		$izq = 0 unless defined $izq;
		$der = $self->count - 1 unless defined $der;
		esylio->customDie("Numeric value expected for 'left'.") unless esylio->isNumber($izq);
		esylio->customDie("Numeric value expected for 'right'.") unless esylio->isNumber($der);
		my $list = $self->{nodes};
		return $izq if $der < 0 || $stamp <= $list->[$izq]->range->min;
		return $der if $stamp >= $list->[$der]->range->min;
		my $mid = undef;
		my $midGeter = sub {
			return POSIX::floor(($izq + $der) / 2) if !defined $mid || $izq != $der - 1;
			return $izq if $izq == $der - 1 && $mid == $der;
			return $der;
		};
		$mid = $midGeter->();
		while ($izq != $der) {
			my $midRange = $list->[$mid]->range;
			last if $stamp >= $midRange->min && $stamp < $midRange->max;
			last if $stamp >= $midRange->max && $mid < $self->count - 1 && $stamp < $list->[$mid + 1]->range->min;
			$izq = $mid if $list->[$mid]->range->min <= $stamp;
			$der = $mid if $list->[$mid]->range->min >= $stamp;
			$mid = $midGeter->();
		}
		return $mid;
	}

	sub nodeAtStamp {
		my $self = shift;
		my ($stamp, $safe) = @_;
		return undef unless $self->count;
		my $node = $self->nodeAtIndex($self->indexAtStamp($stamp), $safe);
		return $stamp >= $node->range->min && $stamp <= $node->range->max ? $node : undef;
	}

	sub indexesWithinRange {
		my $self = shift;
		my ($range) = @_;
		$range = $range->range if defined $range && ref $range eq "Node";
		esylio->assertRef2($range, "Range", 1);
		my $i1 = $self->indexAtStamp($range->min);
		return $i1, $self->indexAtStamp($range->max, $i1);
	}

	sub first {
		my $self = shift;
		my ($safe) = @_;
		return $self->nodeAtIndex(0, $safe);
	}

	sub last {
		my $self = shift;
		my ($safe) = @_;
		return $self->nodeAtIndex($self->count - 1, $safe);
	}

	sub iterateByIndexes {
		my $self = shift;
		my ($condition, $safe, @indexes) = @_;
		$condition = sub { return 1; } unless defined $condition;
		esylio->assertRef2($condition, "CODE", 1);
		@indexes = 0 .. $self->count - 1 unless @indexes;
		return sub {
			my ($returnIndex, $newSafe) = @_;
			$newSafe = $safe unless defined $newSafe;
			my ($ret, $i);
			if ($self->count) {
				while (!defined $ret && defined ($i = shift @indexes)) {
					my $n = $self->nodeAtIndex($i, $newSafe);
					$ret = $n if $condition->($n, $i);
				}
			}
			return $returnIndex ? ($ret, $i) : $ret;
		};
	}

	sub iterate { return shift->iterateByIndexes(@_); }

	sub iterateByIndexesBackwards {
		my $self = shift;
		my ($condition, $safe, @indexes) = @_;
		@indexes = 0 .. $self->count - 1 unless @indexes;
		return $self->iterateByIndexes($condition, $safe, reverse @indexes);
	}

	sub iterateBackwards { return shift->iterateByIndexesBackwards(@_); }

	sub iterateWithinRange {
		my $self = shift;
		my ($range, $condition, $goBackwards, $safe) = @_;
		$range = $self->boundaries unless defined $range;
		esylio->assertRef2($range, "Range", 0);
		$condition = sub { return 1; } unless defined $condition;
		esylio->assertRef2($condition, "CODE", 1);
		my @indexes;
		if (defined $range) {
			my ($i1, $i2) = $self->indexesWithinRange($range);
			@indexes = $i1 <= $i2 ? $i1 .. $i2 : (undef);
			@indexes = reverse @indexes if $goBackwards;
		}
		return $self->iterateByIndexes(sub {
			my ($node, $index) = @_;
			return ($node->range->contains($range) || $range->contains($node->range)) && $condition->($node, $index);
		}, $safe, @indexes ? @indexes : undef);
	}

	sub fillAndIterateWithinRange {
		my $self = shift;
		my ($filling, $range, $condition, $goBackwards, $safe) = @_;
		$range = $self->boundaries unless defined $range;
		esylio->assertRef2($range, "Range", 0);
		my $it = $self->iterateWithinRange($range, $condition, $goBackwards, $safe);
		my $createRange = sub { return Range->new(shift, shift, $self->trimDecimalFunction); };
		my $lastStamp = $goBackwards ? $range->max : $range->min if defined $range;
		my ($currentNode, $currentIdex) = $it->(1);
		($currentNode, $currentIdex) = (Node->new($filling, $createRange->($range->raw)), -1) unless defined $currentNode;
		return sub {
			my ($returnIndex, $newSafe) = @_;
			$newSafe = $safe unless defined $newSafe;
			my ($ret, $i);
			if (defined $currentNode) {
				if ($goBackwards) {
					if ($lastStamp <= $currentNode->range->max) {
						($ret, $i) = ($newSafe ? $currentNode->clone : $currentNode, $currentIdex);
						($currentNode, $currentIdex) = $it->(1);
						($currentNode, $currentIdex) = (Node->new($filling, $createRange->($range->min, $ret->range->min)), -1) if !defined $currentNode && $range->min < $ret->range->min;
					}
					else {
						($ret, $i) = (Node->new($filling, $createRange->($currentNode->range->max, $lastStamp)), -1);
					}
					$lastStamp = $ret->range->min;
				}
				else {
					if ($lastStamp >= $currentNode->range->min) {
						($ret, $i) = ($newSafe ? $currentNode->clone : $currentNode, $currentIdex);
						($currentNode, $currentIdex) = $it->(1);
						($currentNode, $currentIdex) = (Node->new($filling, $createRange->($ret->range->max, $range->max)), -1) if !defined $currentNode && $range->max > $ret->range->max;
					}
					else {
						($ret, $i) = (Node->new($filling, $createRange->($lastStamp, $currentNode->range->min)), -1);
					}
					$lastStamp = $ret->range->max;
				}
			}
			return $returnIndex ? ($ret, $i) : $ret;
		};
	}

	sub iterateAsMask {
		my $self = shift;
		my ($maskFunction, $condition) = @_;
		esylio->assertRef2($maskFunction, 'CODE', 1);
		my $iterator = $self->iterateByIndexes($condition, 1);
		return sub {
			my ($returnIndex) = @_;
			my $retNode = undef;
			my ($n, $i) = $iterator->(1);
			if (defined $n) {
				my ($newValue) = $maskFunction->($n, $i);
				$retNode = Node->new($newValue, $n->range->clone);
			}
			return $returnIndex ? ($retNode, $i) : $retNode;
		};
	}

	sub _baseYield {
		my $self = shift;
		my ($function, $iterator) = @_;
		esylio->assertRef2($function, "CODE", 1);
		esylio->assertRef2($iterator, "CODE", 1);
		my $stop = 0;
		while (!$stop) {
			my ($n, $i) = $iterator->(1);
			$stop = !defined $n || $function->($n, $i);
		}
		return $self;
	}

	sub yieldByIndexes {
		my $self = shift;
		my ($function, $condition, $safe, @indexes) = @_;
		return $self->_baseYield($function, $self->iterateByIndexes($condition, $safe, @indexes));
	}

	sub yield { return shift->yieldByIndexes(@_); }

	sub yieldByIndexesBackwards {
		my $self = shift;
		my ($function, $condition, $safe, @indexes) = @_;
		@indexes = 0 .. $self->count - 1 unless @indexes;
		return $self->yieldByIndexes($function, $condition, $safe, reverse @indexes);
	}

	sub yieldBackwards { return shift->yieldByIndexesBackwards(@_); }

	sub yieldWithinRange {
		my $self = shift;
		my ($function, $range, $condition, $goBackwards, $safe) = @_;
		return $self->_baseYield($function, $self->iterateWithinRange($range, $condition, $goBackwards, $safe));
	}

	sub fillAndYieldWithinRange {
		my $self = shift;
		my ($function, $filling, $range, $condition, $goBackwards, $safe) = @_;
		return $self->_baseYield($function, $self->fillAndIterateWithinRange($filling, $range, $condition, $goBackwards, $safe));
	}

	sub yieldAsMask {
		my $self = shift;
		my ($function, $maskFunction, $condition) = @_;
		return $self->_baseYield($function, $self->iterateAsMask($maskFunction, $condition));
	}

	sub maskAs {
		my $self = shift;
		my ($maskFunction, $condition) = @_;
		my @nodes;
		$self->yieldAsMask(sub {
			push @nodes, shift;
			return 0;
		}, $maskFunction, $condition);
		my $ret = $self->clone(0);
		$ret->insertAF(@nodes);
		return $ret;
	}

	sub maskAsNumber {
		my $self = shift;
		my ($start) = @_;
		$start = 0 if !defined $start || $start =~ /^\s*$/;
		my $i = $start;
		return $self->maskAs(sub { return $i++; });
	}

	sub maskAsAlphabet {
		my $self = shift;
		my @alphabet = @_;
		my $base = @alphabet;
		esylio->customDie("Error base $base.") if $base < 2;
		my $cont = 0;
		return $self->maskAs(sub {
			my $l = $cont++;
			my $ret = '';
			while ($l >= $base) {
				$l = ($l - (my $r = $l % $base)) / $base;
				$ret = $alphabet[$r] . $ret;
			}
			$ret = $alphabet[$l] . $ret;
			return $ret;
		});
	}

	sub indexArrayWithinRange {
		my $self = shift;
		my ($range) = @_;
		my @ret;
		$self->yieldWithinRange(sub {
			my ($n, $i) = @_;
			push @ret, $i;
			return 0;
		}, $range, undef, 0, 0) if defined $range;
		return @ret;
	}

	sub select {
		my $self = shift;
		my ($condition, $safe) = @_;
		my @ret;
		$self->yieldByIndexes(sub {
			my ($n, $i) = @_;
			push @ret, $n;
			return 0;
		}, $condition, $safe);
		return @ret;
	}

	sub temp {
		my $self = shift;
		my ($function, $withNodes) = @_;
		esylio->assertRef2($function, "CODE", 1);
		my $chain = $self->clone(0);
		$chain->add($self) if $withNodes;
		eval { $function->($chain); };
		my $error = $@;
		$chain->removeAll if defined $chain && ref $chain eq "Chain";
		die $error if $error;
		return $self;
	}

	sub _insertNodeAtIndex {
		my $self = shift;
		my ($index, $node, $replace) = @_;
		my $tempRange = $node->range->clone;
		$tempRange->trimDecimalFunction($self->trimDecimalFunction);
		my $nodeAdded = $self->allowNullLength || $tempRange->difference != 0;
		if ($nodeAdded) {
			$replace = 0 unless defined $replace;
			splice @{$self->{nodes}}, $index, $replace, $node;
			$node->range->trimDecimalFunction($self->trimDecimalFunction);
		}
		return $nodeAdded;
	}

	sub _splitAtStamp {
		my $self = shift;
		my ($value, @cloneParameters) = @_;
		my $nodeGetter = sub {
			my ($index) = @_;
			return $index >= 0 && $index < $self->count ? $self->nodeAtIndex($index, 0) : undef;
		};
		my $lIndex = $self->indexAtStamp($value);
		my $lNode = $nodeGetter->($lIndex);
		if (defined $lNode && $value > $lNode->range->min && $value < $lNode->range->max) {
			my $newPart = $lNode->clone(@cloneParameters);
			$lNode->range->max($value);
			$self->_insertNodeAtIndex($lIndex + 1, Node->new($newPart->value, Range->new($value, $newPart->range->max)), 0);
		}
		return $lIndex;
	}

	sub splitAtStamp {
		my $self = shift;
		my ($value, @cloneParameters) = @_;
		$self->_splitAtStamp($value, @cloneParameters);
		return $self;
	}

	sub removeByIndexes {
		my $self = shift;
		my @indexes = @_;
		splice @{$self->{nodes}}, $_, 1 for sort { $b <=> $a } @indexes;
		return $self;
	}

	sub removeAll {
		my $self = shift;
		return $self->removeByIndexes(0 .. $self->count - 1);
	}

	sub clear { return shift->removeAll; }

	sub removeAs {
		my $self = shift;
		my ($condition, $range, $split) = @_;
		$range = $self->boundaries unless defined $range;
		esylio->assertRef2($range, "Range", 0);
		return defined $range ? $self->yieldWithinRange(sub {
			my ($node, $index) = @_;
			my $remIndex = $index;
			if ($split) {
				$self->splitAtStamp($range->max) if $node->range->max > $range->max;
				if ($node->range->min < $range->min) {
					$self->splitAtStamp($range->min);
					$remIndex += 1;
				}
			}
			$self->removeByIndexes($remIndex);
			return 0;
		}, $range, $condition, 1, 1) : $self;
	}

	sub _removeByRange {
		my $self = shift;
		my ($range) = @_;
		esylio->assertRef2($range, "Range", 1);
		my $nodeGetter = sub {
			my ($index) = @_;
			return $index >= 0 && $index < $self->count ? $self->nodeAtIndex($index, 0) : undef;
		};
		my $i1 = $self->_splitAtStamp($range->min);
		my $i2 = $self->_splitAtStamp($range->max);
		my $midNode1 = $nodeGetter->($i1);
		my $midNode2 = $nodeGetter->($i2);
		$i1 += 1 if defined $midNode1 && $midNode1->range->min < $range->min;
		$i2 -= 1 if defined $midNode2 && $midNode2->range->min >= $range->max;
		$self->removeByIndexes($i1 .. $i2);
		return $i1;
	}

	sub insertAF {
		my $self = shift;
		my @nodes = @_;
		for my $n (@nodes) {
			if (ref $n eq "Chain") { $self->insertAF($n->nodes); }
			elsif (ref $n eq "Node") { $self->_insertNodeAtIndex($self->count, $n, 0); }
			else { esylio->customDie("Either 'Node' or 'Chain' objects allowed."); }
		}
		return $self;
	}

	sub clone {
		my $self = shift;
		my ($cloneNodes) = @_;
		my $ret = Chain->new($self->id, $self->allowNullLength, $self->defaultSafe, $self->trimDecimalFunction);
		$self->yieldByIndexes(sub {
			my ($node, $index) = @_;
			$ret->_insertNodeAtIndex($index, $node, 0);
			return 0;
		}, undef, 1) if $cloneNodes;
		return $ret;
	}

	sub insert {
		my $self = shift;
		my @nodes = @_;
		for my $n (@nodes) {
			if (defined $n) {
				if (ref $n eq 'Chain') {
					$self->insert($n->nodes);
				}
				elsif (ref $n eq 'Node') {
					$self->_insertNodeAtIndex($self->_removeByRange($n->range), $n, 0);
				}
				elsif (ref $n eq 'CODE') {
					my $cont = 1;
					while ($cont) {
						my ($realNode) = $n->();
						$self->insert($realNode) if $cont = defined $realNode;
					}
				}
				else {
					esylio->customDie("Either 'Chain' or 'Node' values are allowed.");
				}
			}
		}
		return $self;
	}

	sub fill {
		my $self = shift;
		my ($filling, @ranges) = @_;
		push @ranges, $self->boundaries unless @ranges;
		for my $range (@ranges) {
			my $lastIndex;
			$self->fillAndYieldWithinRange(sub {
				my ($n, $i) = @_;
				$lastIndex = $i unless $i == -1;
				if ($i == -1) {
					if (defined $lastIndex) {
						$self->_insertNodeAtIndex($lastIndex, $n, 0);
						$lastIndex = undef;
					}
					else {
						$self->insert($n);
					}
				}
				return 0;
			}, $filling, $range, undef, 1);
		}
		return $self;
	}

	sub merge {
		my $self = shift;
		my ($mergingType, @ranges) = @_;
		# $mergingType:
		# 0 : only inner content
		# 1 : only boundaries
		# 2 : boundaries and inner content
		$mergingType = 0 if !defined $mergingType || $mergingType < 0;
		$mergingType = 2 if $mergingType > 2;
		esylio->customDie("Unknown merging option $mergingType.") unless $mergingType =~ /^[0-2]$/;
		push @ranges, $self->boundaries unless @ranges;
		my $doMerge = sub {
			return unless (my @indexes = reverse @_);
			my $currentIndex = shift @indexes;
			my $currentNode = $self->nodeAtIndex($currentIndex, 0);
			while (@indexes) {
				my $nextIndex = shift @indexes;
				my $nextNode = $self->nodeAtIndex($nextIndex, 0);
				if ($nextNode->range->max == $currentNode->range->min && $nextNode->value eq $currentNode->value) {
					$self->removeByIndexes($currentIndex);
					$nextNode->range->max($currentNode->range->max);
				}
				($currentIndex, $currentNode) = ($nextIndex, $nextNode);
			}
		};
		for my $currRange (@ranges) {
			if (defined $currRange) {
				my $range = $currRange->clone;
				$range->trimDecimalFunction($self->trimDecimalFunction);
				next unless $range->difference;
				if ($mergingType == 2) {
					$self->merge($_, $range) for Merging->INNER, Merging->BOUNDARIES;
				}
				else {
					next unless (my @indexes = $self->indexArrayWithinRange($range));
					if ($mergingType == 0) {
						$doMerge->(@indexes);
					}
					elsif ($mergingType == 1) {
						my ($l, $r) = ($indexes[0] - 1, $indexes[$#indexes] + 1);
						$doMerge->($indexes[$#indexes], $r) if $r < $self->count;
						$doMerge->($l, $indexes[0]) if $l >= 0;
					}
					else { esylio->customDie("Oops!"); }
				}
			}
		}
		return $self;
	}

	sub subChain {
		my $self = shift;
		my ($condition, $range, $split) = @_;
		my @nodes;
		$self->yieldWithinRange(sub {
			my $node = shift;
			if ($split) {
				$node->range->min($range->min) if $range->min > $node->range->min;
				$node->range->max($range->max) if $range->max < $node->range->max;
			}
			push @nodes, $node;
			return 0;
		}, $range, $condition, 0, 1);
		return $self->clone(0)->insertAF(@nodes);
	}

	sub moveBy {
		my $self = shift;
		my ($lapse) = @_;
		esylio->customDie("Numeric value expected for lapse.\n") unless esylio->isNumber($lapse);
		if ($self->count && $lapse != 0) {
			my $yieldingSub = $lapse > 0 ? 'yieldBackwards' : 'yield';
			$self->$yieldingSub(sub {
				shift->range->moveBy($lapse);
				return 0;
			}, undef, 0);
		}
		return $self;
	}

	sub moveTo {
		my $self = shift;
		my ($stamp) = @_;
		esylio->customDie("Numeric value expected for stamp.\n") unless esylio->isNumber($stamp);
		return $self->count ? $self->moveBy($stamp - $self->first->range->min) : $self;
	}

	sub scale {
		my $self = shift;
		my ($factor) = @_;
		esylio->customDie("Numeric value expected for factor.\n") unless esylio->isNumber($factor);
		if ($self->count && $factor != 1) {
			my $yieldingSub = $factor > 0 ? 'yieldBackwards' : 'yield';
			$self->$yieldingSub(sub {
				shift->range->scale($factor);
				return 0;
			}, undef, 0);
		}
		return $self;
	}

	sub toString {
		my $self = shift;
		my ($toStringValueFunction) = @_;
		my $ret = $self->id. " (" . $self->count . " nodes):\n";
		$self->yield(sub {
			my ($node, $index) = @_;
			$ret .= $index . "\\ " . $node->toString($toStringValueFunction) . "\n";
			return 0;
		}, undef, 0);
		$ret =~ s/\n+$//;
		return $ret;
	}

	sub compare {
		my $self = shift;
		my ($target, @rules) = @_;
		esylio->assertRef2($target, 'Chain', 1);
		esylio->customDie("No comparison rules provided.") unless @rules;
		my $ret = Chain->new($self->name . "->cmp(" . $target->name . ")", 0, 1);
		if ($self->count || $target->count) {
			$self->fillAndYieldWithinRange(sub {
				my ($nodeRef, $indexRef) = @_;
				$target->subChain(undef, $nodeRef->range, 1)->fillAndYieldWithinRange(sub {
					my ($nodeTrg, $indexTrg) = @_;
					for my $rule (@rules) {
						esylio->assertRef2($rule, 'Rule', 1);
						if ($rule->run($nodeRef, $nodeTrg)) {
							$ret->insert(Node->new($rule->runValue($nodeRef->value, $nodeTrg->value), $nodeTrg->range->clone));
							last;
						}
					}
					return 0;
				}, Node->VOID, $nodeRef->range);
				return 0;
			}, Node->VOID, Range->getWhole($self->bounds, $target->bounds, $self->trimDecimalFunction));
		}
		return $ret->merge;
	}

package Merging;

	use constant {
		INNER => 0,
		BOUNDARIES => 1,
		BOUNDARIES_INNER => 2
	};

package Rule;

	sub new {
		my $class = shift;
		my ($value, $rule) = @_;
		$rule = sub { shift->value ne shift->value; } if defined $rule && $rule eq Rule->NE;
		$rule = sub { shift->value eq shift->value; } if defined $rule && $rule eq Rule->EQ;
		esylio->assertRef2($rule, 'CODE', 1);
		return bless {
			value => $value,
			rule => $rule
		}, $class;
	}

	sub run {
		my $self = shift;
		my (@args) = @_;
		return $self->{rule}->(@args);
	}

	sub runValue {
		my $self = shift;
		my (@args) = @_;
		return ref $self->{value} eq "CODE" ? $self->{value}->(@args) : $self->{value};
	}

	sub mirrorClass { return shift; }

	sub getN { return shift->{n}; }

	use constant {
		NE => (bless { n => 'NE' }, Rule->mirrorClass),
		EQ => (bless { n => 'EQ' }, Rule->mirrorClass)
	};

1;

##################
### i made dis ###
### esyl       ###
##################