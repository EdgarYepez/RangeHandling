package Range;

	use utf8;
	use strict;
	use warnings;
	use YERangeHandling::esylio;

	sub new {
		my $class = shift;
		my ($min, $max, $trimDecimalFunction) = @_;
		my $self = bless {
			max => undef,
			min => undef,
			trimDecimalFunction => undef,
			settingTrimFunction => 0
		}, $class;
		$self->trimDecimalFunction($trimDecimalFunction);
		$self->max($max);
		$self->min($min);
		return $self;
	}

	sub clone {
		my $self = shift;
		return Range->new($self->min, $self->max, $self->trimDecimalFunction);
	}

	sub max {
		my $self = shift;
		if (@_) {
			my ($value) = @_;
			esylio->assertRef2($value, "", 1);
			$value = $self->_runTrimFunction($value);
			$self->assertBounds($self->min, $value);
			$self->{max} = $value;
		}
		return $self->{max};
	}

	sub min {
		my $self = shift;
		if (@_) {
			my ($value) = @_;
			esylio->assertRef2($value, "", 1);
			$value = $self->_runTrimFunction($value);
			$self->assertBounds($value, $self->max);
			$self->{min} = $value;
		}
		return $self->{min};
	}

	sub raw {
		my $self = shift;
		return $self->min, $self->max;
	}

	sub boundaries { return shift->raw; }

	sub trimDecimalFunction {
		my $self = shift;
		if (@_) {
			my ($code) = @_;
			$code = sub { return 0 + shift; } unless defined $code;
			esylio->assertRef2($code, "CODE", 1);
			$self->{settingTrimFunction} = 1;
			eval {
				$self->{trimDecimalFunction} = $code;
				$self->min($self->_runTrimFunction($self->min)) if defined $self->min;
				$self->max($self->_runTrimFunction($self->max)) if defined $self->max;
			};
			$self->{settingTrimFunction} = 0;
			die $@ if $@;
			$self->assertBounds($self->min, $self->max);
		}
		return $self->{trimDecimalFunction};
	}

	sub _runTrimFunction {
		my $self = shift;
		my ($val) = @_;
		my $ret = $self->trimDecimalFunction->($val);
		esylio->customDie("Value after trim function seems not to be a number.") unless esylio->isNumber($ret);
		return 0 + $ret;
	}

	sub moveTo {
		my $self = shift;
		my ($stamp) = @_;
		esylio->customDie("Not a numeric value provided for stamp.") unless esylio->isNumber($stamp);
		return $self->moveBy($stamp - $self->min);
	}

	sub moveBy {
		my $self = shift;
		my ($lapse) = @_;
		esylio->customDie("Not a numeric value provided for lapse.") unless esylio->isNumber($lapse);
		if ($lapse != 0) {
			if ($lapse > 0) {
				$self->max($self->max + $lapse);
				$self->min($self->min + $lapse);
			}
			elsif ($lapse < 0) {
				$self->min($self->min + $lapse);
				$self->max($self->max + $lapse);
			}
		}
		return $self;
	}

	sub scale {
		my $self = shift;
		my ($factor) = @_;
		esylio->customDie("Not a numeric value provided for factor.") unless esylio->isNumber($factor);
		esylio->customDie("Factor must be greater than zero.") if $factor <= 0;
		if ($factor != 1) {
			if ($factor < 1) {
				$self->min($self->_runTrimFunction($self->min * $factor));
				$self->max($self->_runTrimFunction($self->max * $factor));
			}
			elsif ($factor > 1) {
				$self->max($self->_runTrimFunction($self->max * $factor));
				$self->min($self->_runTrimFunction($self->min * $factor));
			}
		}
		return $self;
	}

	sub absoluteInterval { return shift->difference; }

	sub difference {
		my $self = shift;
		esylio->customDie("Both max and min must have a numeric value assigned.") unless defined $self->max && defined $self->min;
		return $self->_runTrimFunction($self->max - $self->min);
	}

	sub contains {
		my $self = shift;
		my ($range, $fully) = @_;
		esylio->assertRef2($range, "Range", 1);
		$fully = 0 unless defined $fully;
		return $range->min >= $self->min && $range->max <= $self->max if $fully;
		return $range->min >= $self->min && $range->min < $self->max || $range->max > $self->min && $range->max <= $self->max;
	}

	sub assertBounds {
		my $self = shift;
		my ($min, $max) = @_;
		esylio->customDie("Maximum value must be greater than or equal to minimum value.\n\tmax: $max\n\tmin: $min\n") if !$self->{settingTrimFunction} && defined $max && defined $min && $max < $min;
	}

	sub equals {
		my $self = shift;
		my ($range) = @_;
		return 0 if !defined $range || ref $range ne 'Range';
		return $self->max == $range->max && $self->min == $range->min;
	}

	sub toString {
		my $self = shift;
		my ($sepStr) = @_;
		return $self->min . (defined $sepStr ? $sepStr : " -> ") . $self->max;
	}

	sub getWhole {
		my $class = shift;
		my ($ABounds, $BBounds, $trimDecimalFunction) = @_;
		esylio->assertRef2($ABounds, "Range", 0);
		esylio->assertRef2($BBounds, "Range", 0);
		return undef unless defined $ABounds || defined $BBounds;
		return $BBounds unless defined $ABounds;
		return $ABounds unless defined $BBounds;
		my ($tierAMin, $tierAMax) = $ABounds->raw;
		my ($tierBMin, $tierBMax) = $BBounds->raw;
		return Range->new($tierAMin < $tierBMin ? $tierAMin : $tierBMin, $tierAMax > $tierBMax ? $tierAMax : $tierBMax, $trimDecimalFunction);
	}

1;

##################
### i made dis ###
### esyl       ###
##################