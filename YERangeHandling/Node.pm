package Node;

	use utf8;
	use strict;
	use warnings;
	use YERangeHandling::Range;
	use YERangeHandling::esylio;

	sub new {
		my $class = shift;
		my ($value, $range) = @_;
		my $self = bless {
			value => undef,
			range => esylio->assertRef2($range, "Range", 1)
		}, $class;
		$self->value($value);
		return $self;
	}

	sub value {
		my $self = shift;
		if (@_) {
			my ($value) = @_;
			$self->{value} = $value;
		}
		return $self->{value};
	}

	sub range { return shift->{range}; }

	sub toString {
		my $self = shift;
		my ($toStringFunction, @params) = @_;
		$toStringFunction = sub {
			my ($val) = @_;
			$val = $val->toString(@params) if ref $val !~ /^(?:ARRAY|HASH|)$/ && $val->UNIVERSAL::can('toString');
			$val = ref $val if ref $val ne "";
			return $val;
		} unless defined $toStringFunction;
		esylio->assertRef2($toStringFunction, "CODE", 1);
		return '[' . $self->range->toString . ']: ' . $toStringFunction->($self->value);
	}

	sub clone {
		my $self = shift;
		my @valueCloneParams = @_;
		my $val = $self->value;
		return Node->new(ref $val !~ /^(?:ARRAY|HASH|)$/ && $val->UNIVERSAL::can('clone') ? $val->clone(@valueCloneParams) : $val, $self->range->clone);
	}

	sub equals {
		my $self = shift;
		my ($node) = @_;
		my $ret = 0;
		return $ret if !defined $node || ref $node ne 'Node';
		my $val = $self->value;
		$ret = ref $val !~ /^(?:ARRAY|HASH|)$/ && $val->UNIVERSAL::can('equals') ? $val->equals($node->value) : $val eq $node->value if $self->range->equals($node->range) && ref $val eq ref $node->value;
		return $ret;
	}

	sub enumClass { return "enum." . shift; }

	use constant { VOID => bless { n => 'VOID' }, Node->enumClass };

1;

##################
### i made dis ###
### esyl       ###
##################