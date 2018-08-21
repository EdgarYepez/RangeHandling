package TextGrid;

	use utf8;
	use strict;
	use warnings;
	use YERangeHandling::Chain;
	use YERangeHandling::esylio;

	sub new {
		my $class = shift;
		my ($txtg, $trimDecimalFunction, $tiersToReadFunction) = @_;
		$trimDecimalFunction = sub { return 0 + shift; } unless defined $trimDecimalFunction;
		$tiersToReadFunction = sub { return 1; } unless defined $tiersToReadFunction;
		my $self = bless {
			fileType => "ooTextFile",
			objectClass => "TextGrid",
			tiers => {},
			tierIndex => [],
			filePath => undef,
			trimDecimalFunction => esylio->assertRef2($trimDecimalFunction, 'CODE', 1),
			tiersToRead => esylio->assertRef2($tiersToReadFunction, 'CODE', 1)
		}, $class;
		$self->read($txtg) if defined $txtg;
		return $self;
	}

	sub baseFile { return shift->{filePath}; }

	sub count {
		my $r = keys %{shift->{tiers}};
		return $r;
	}

	sub tierNames { return @{shift->{tierIndex}}; }

	sub contains {
		my $self = shift;
		my ($name) = @_;
		esylio->customDie("No name provided.") unless defined $name;
		return exists $self->{tiers}->{$name};
	}

	sub relocate {
		my $self = shift;
		my (@order) = @_;
		my $count = 0;
		for my $tierName (@order) {
			if (defined $tierName) {
				$self->tier($tierName);
				my $found = 0;
				for my $i (0 .. $self->count - 1) {
					$found = @{$self->{tierIndex}}[$i] eq $tierName;
					if ($found) {
						splice @{$self->{tierIndex}}, $i, 1;
						last;
					}
				}
				esylio->customDie("Error, shoot! Shouldnt have happened.") unless $found;
				splice @{$self->{tierIndex}}, $count, 0, $tierName;
			}
			$count += 1;
		}
		return $self;
	}

	sub tierAt {
		my $self = shift;
		my ($index) = @_;
		esylio->customDie("No index provided.") unless esylio->isNumber($index);
		esylio->customDie("No tier at index $index.") unless ($index >= 0 && $index < $self->count);
		return @{$self->{tierIndex}}[$index];
	}

	sub tier {
		my $self = shift;
		my ($name) = @_;
		esylio->customDie("There is no tier named '$name'.") unless $self->contains($name);
		return $self->{tiers}->{$name};
	}

	sub extract {
		my $self = shift;
		my ($name) = @_;
		my $tier = $self->tier($name);
		$self->remove($name);
		return $tier;
	}

	sub yield {
		my $self = shift;
		my ($function, @names) = @_;
		esylio->assertRef2($function, "CODE", 1);
		my $count = 0;
		for my $name (@names ? @names : $self->tierNames) {
			my $stop = $function->($self->tier($name), $count++);
			last if esylio->isNumber($stop) && $stop == 1;
		}
		return $self;
	}

	sub tiers {
		my $self = shift;
		my @ret;
		$self->yield(sub {
			push @ret, shift;
			return 0;
		});
		return @ret;
	}

	sub remove {
		my $self = shift;
		my (@names) = @_;
		for my $tierName (@names) {
			my $delTier = $self->tier($tierName);
			my $found = 0;
			foreach my $i (0 .. $self->count - 1) {
				$found = @{$self->{tierIndex}}[$i] eq $tierName;
				if ($found) {
					splice @{$self->{tierIndex}}, $i, 1;
					last;
				}
			}
			esylio->customDie("Error, shoot! Shouldn't have happened.") unless $found;
			$delTier->eventManager->removeAllOf($self);
			delete $self->{tiers}->{$tierName};
		}
		return $self;
	}

	sub removeAll {
		my $self = shift;
		return $self->remove($self->tierNames);
	}

	sub read {
		my $self = shift;
		my (@textGridStrings) = @_;
		my $tgHeadRgx = q/^\s*(?:file\s*type[\s:=]*)?"(.*?)"\s*(?:object\s*class[\s:=]*)?"(.*?)"\s*(?:x?\s*min[\s:=]*)?(\d+(?:\.\d+)?)(?:(?:\s*x?\s*max[\s:=]*)|\s+)((?3))\s*(?:tiers[\s:=?]*\s*)?<(.*?)>\s*(?:size[\s:=]*)?(\d+)\s*(?:item\s*\[\s*\]\s*[\s:=]*)?\s*/;
		my $tierHeadRgx = q/^\s*(?:item\s*\[\s*(\d+)\s*\][\s:=]*)?(?:class[\s:=]*)?"((?:""|[^"])*)"\s*(?:name[\s:=]*|\s+)"((?2))"\s*(?:x?\s*min[\s:=]*)?(\d+(?:\.\d+)?)(?:(?:\s*x?\s*max[\s:=]*)|\s+)((?4))(?:\s*(?:intervals[\s:=]*)?(?:size[\s:=]*)?|\s+)(\d+)\s*/;
		my $intervalRgx = q/^\s*(?:intervals\s*\[\s*(\d+)\s*\][\s:=]*)?(?:x?\s*min[\s:=]*)?(\d+(?:\.\d+)?)(?:(?:\s*x?\s*max[\s:=]*)|\s+)((?2))\s*(?:text[\s:=]*)?"((?:""|[^"])*)"\s*/;
		my $quotationRemover = sub {
			my $val = shift;
			$val = "" unless defined $val;
			$val =~ s/""/"/g;
			return $val;
		};
		for my $textGridString (@textGridStrings) {
			esylio->assertRef(obj => $textGridString, type => "", name => '.TextGrid file/content', dieOnUndef => 1, errRgx => qr/^\s*$/);
			if (esylio->isPathString($textGridString)) {
				$self->{filePath} = $textGridString;
				$textGridString = esylio->openFile($textGridString);
			}
			$textGridString =~ s/[\r﻿]//g; #[\rBOM]
			my ($tierCount, $actualTierCount, $tgRange) = (-1, 0, undef);
			if ($textGridString =~ s/$tgHeadRgx//i) {
				my ($fileType, $objectClass, $min, $max, $existence) = ($1, $2, $3, $4, $5);
				$tierCount = $6;
				esylio->customDie("Unknown TextGrid file type: $fileType") unless $fileType =~ /^\s*oo\s*Text\s*File\s*$/i;
				esylio->customDie("Unknown object: $objectClass") unless $objectClass =~ /^\s*Text\s*Grid\s*$/i;
				$tgRange = Range->new($min, $max, $self->{trimDecimalFunction});
				esylio->customDie("TextGrid boundaries are equal at " . $tgRange->max . ".") unless $tgRange->absoluteInterval;
				esylio->customDie("Unexpected word for tier existence: $existence") unless $existence =~ /^\s*exists?\s*$/i;
			}
			else { esylio->customDie("Not a valid .TextGrid string."); }
			while ($textGridString =~ s/$tierHeadRgx//i) {
				my ($tierIndex, $tierClass, $name, $min, $max, $intervalCount) = ($1, $2, $3, $4, $5, $6);
				esylio->customDie("Unexpected tier index $tierIndex.\nExpected index: " . ($actualTierCount)) if defined $tierIndex && $tierIndex == $actualTierCount + 1;
				esylio->customDie("Unknown tier class: $tierClass") unless $tierClass =~ /^\s*Interval\s*Tier\s*$/i;
				$name = $quotationRemover->($name);
				esylio->customDie("Empty tier name.") unless $name && $name !~ /^\s*$/;
				if ($self->{tiersToRead}->($name, $tierClass, $self)) {
					esylio->customDie("The TextGrid object already contains a tier named '$name'.") if $self->contains($name);
					my $tierRange = Range->new($min, $max, $self->{trimDecimalFunction});
					esylio->customDie("Tier '$name'. Its boundaries are equal with value " . $tierRange->max . ".") unless $tierRange->absoluteInterval;
					esylio->customDie("Tier '$name'. Its boundaries (" . $tierRange->toString . ") are outside the TextGrid's ones (" . $tgRange->toString . ").") unless $tgRange->contains($tierRange, 1);
					esylio->customDie("Tier '$name'. Its boundaries (" . $tierRange->toString . ") are different from the TextGrid's ones (" . $tgRange->toString . ").") unless $tgRange->equals($tierRange);
					my @nodes;
					my $minExpected = $tierRange->min;
					while ($textGridString =~ s/$intervalRgx//) {
						my ($intervalIndex, $min, $max, $value) = ($1, $2, $3, $4);
						esylio->customDie("Tier '$name'. Unexpected interval index $intervalIndex.\nExpected index: " . (scalar @nodes)) if defined $intervalIndex && $intervalIndex == @nodes + 1;
						$value = $quotationRemover->($value);
						my $intervalRange = Range->new($min, $max, $self->{trimDecimalFunction});
						esylio->customDie("Tier '$name'. The interval boundaries (" . $intervalRange->toString . ") are outside the tier's ones (" . $tierRange->toString . ").") unless $tierRange->contains($intervalRange, 1);
						esylio->customDie("Tier '$name'. The interval boundaries are equal with value " . $intervalRange->max . ".") unless $intervalRange->absoluteInterval;
						esylio->customDie("Tier '$name'. Unexpected beginning of interval " . $intervalRange->min . ". Expected $minExpected.") unless $intervalRange->min == $minExpected;
						$minExpected = $intervalRange->max;
						push @nodes, Node->new($value, $intervalRange);
					}
					esylio->customDie("The number of actual intervals (" . (0 + @nodes) . ") is different from the interval count ($intervalCount).") unless @nodes == $intervalCount;
					$self->add(Chain->new($name, 0, 1, $self->{trimDecimalFunction})->insertAF(@nodes));
				}
				else { while ($textGridString =~ s/$intervalRgx//) { }; }
				$actualTierCount += 1;
			}
			esylio->customDie("Error while parsing tiers.") unless $textGridString =~ /^\s*$/;
			esylio->customDie("Number of actual tiers ($actualTierCount) is different from the tier count ($tierCount).") unless $actualTierCount == $tierCount;
		}
		return $self;
	}

	sub add {
		my $self = shift;
		my (@tiers) = @_;
		$self->addAt($_) foreach @tiers;
		return $self;
	}

	sub addAt {
		my $self = shift;
		my ($tier, $index) = @_;
		$index = $self->count if (!defined $index || $index > $self->count);
		if (defined $tier && ref $tier eq "TextGrid") {
			$tier->yield(sub { $self->addAt(shift, $index++); });
		}
		else {
			esylio->assertRef(obj => $tier, type => "Chain", name => 'Chain', dieOnUndef => 1);
			esylio->customDie("The TextGrid object already contains a tier named '" . $tier->name . "'.") if $self->contains($tier->name);
			$self->{tiers}->{$tier->name} = $tier;
			splice @{$self->{tierIndex}}, $index, 0, $tier->name;
		}
		return $self;
	}

	sub boundaries { return shift->bounds; }

	sub bounds {
		my ($self) = @_;
		my $ret = undef;
		if ($self->count) {
			my $min = undef;
			my $max = undef;
			$self->yield(sub {
				my $tier = shift;
				if ($tier->count) {
					my ($tierMin, $tierMax) = $tier->bounds->raw;
					$min = $tierMin if (!defined $min || $tierMin < $min);
					$max = $tierMax if (!defined $max || $tierMax > $max);
				}
				return 0;
			});
			$ret = Range->new($min, $max) if (defined $min && defined $max);
		}
		return $ret;
	}

	sub scale {
		my $self = shift;
		my ($factor) = @_;
		return $self->yield(sub { shift->scale($factor); });
	}

	sub moveTo {
		my $self = shift;
		my ($stamp) = @_;
		return $self->yield(sub { shift->moveTo($stamp); });
	}

	sub moveBy {
		my $self = shift;
		my ($lapse) = @_;
		return $self->yield(sub { shift->moveBy($lapse); });
	}

	sub merge { return shift->yield(sub { shift->merge; }); }

	sub flash {
		my $self = shift;
		my ($fileName, $longText, $value2TextFunction, $codif, @tierNames) = @_;
		esylio->customDie("The TextGrid object contains no tiers.") unless $self->count;
		$fileName = $self->{filePath} unless defined $fileName;
		esylio->customDie("File path not set.") if (!defined $fileName || $fileName =~ /^\s*$/ || !esylio->isPathString($fileName));
		esylio->writeFile($fileName, $self->toString($longText, $value2TextFunction, @tierNames), $codif);
		return $self;
	}

	sub toString {
		my $self = shift;
		my ($longText, $value2TextFunction, @tierNames) = @_;
		$value2TextFunction = sub {
			my $value = shift;
			return "" unless defined $value;
			return ref $value ne "" && $value->UNIVERSAL::can('toString') ? $value->toString : $value;
		} unless defined $value2TextFunction;
		esylio->assertRef(obj => $value2TextFunction, type => "CODE", name => 'value to string convertion function', dieOnUndef => 1);
		my $ret = "";
		my $bounds = $self->bounds;
		if (defined $bounds) {
			my $indent = sub {
				my $text = shift;
				$text =~ s/^/    /gm if $longText;
				$text =~ s/\s+$//;
				return $text;
			};
			my $range2TextGrid = sub {
				my $range = shift;
				my $text = ($longText ? "xmin = " : "") . $range->min . "\n";
				$text .= ($longText ? "xmax = ": "") . $range->max;
				return $text;
			};
			my $valCount = 0;
			my %vals;
			@tierNames = $self->tierNames unless @tierNames;
			$ret = "File type = \"" . $self->{fileType} . "\"\nObject class = \"" . $self->{objectClass} . "\"\n\n" . $range2TextGrid->($bounds) . "\n";
			$ret .= ($longText ? "tiers? ": "") . "<exists>\n";
			$ret .= ($longText ? "size = ": "") . @tierNames . "\n";
			$ret .= "item []:\n" if $longText;
			my $bodyStr = "";
			$self->yield(sub {
				my ($orgChain, $i) = @_;
				my $name = $orgChain->name;
				$name =~ s/"/""/g;
				my $tierStr = ($longText ? "class = " : "") . "\"IntervalTier\"\n";
				$tierStr .= ($longText ? "name = " : "") . "\"$name\"\n";
				$tierStr .= $range2TextGrid->($bounds) . "\n";
				my $intervalStr = '';
				my $count = 0;
				$orgChain->fillAndYieldWithinRange(sub {
					my ($node, $index) = @_;
					my $nodeStr = $range2TextGrid->($node->range) . "\n";
					$nodeStr .= ($longText ? "text = " : "") . "<{$valCount}>\n";
					$vals{$valCount++} = $value2TextFunction->($node->value);
					$intervalStr .= ($longText ? "intervals [" . $count . "]:\n" : '') . $indent->($nodeStr) . "\n";
					$count += 1;
					return 0;
				}, '', $bounds);
				$tierStr .= ($longText ? "intervals: size = " : "") . $count . "\n$intervalStr";
				$bodyStr .= ($longText ? "item [" . $i . "]:\n" : '') . $indent->($tierStr) . "\n";
				return 0;
			}, @tierNames);
			$ret .= $indent->($bodyStr);
			$ret =~ s/\s+$//;
			for my $i (0 .. $valCount - 1) {
				my $currValue = defined $vals{$i} ? $vals{$i} : "";
				$currValue =~ s/"/""/g;
				$currValue = "\"$currValue\"";
				$ret =~ s/<\{$i\}>/$currValue/;
			}
		}
		return $ret;
	}

	sub clone {
		my $self = shift;
		my $ret = TextGrid->new(undef, $self->{trimDecimalFunction}, $self->{tiersToRead});
		$ret->{filePath} = $self->{filePath};
		$self->yield(sub { $ret->add(shift->clone(1)); });
		return $ret;
	}

1;

##################
### i made dis ###
### esyl       ###
##################