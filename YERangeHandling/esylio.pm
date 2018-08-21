package esylio;

	use strict;
	use warnings;
	use Encode;
	use utf8;
	use File::Basename;
	use Scalar::Util qw(looks_like_number);
	binmode STDOUT, ":utf8";
	binmode STDERR, ":utf8";

	sub prompt {
		my ($self, $title) = @_;
		print $title;
		my $answer = <STDIN>;
		chomp $answer if defined $answer;
		return $answer;
	}

	sub writeFile {
		my($self, $fileName, $content, $encoding, $append) = @_;
		$append = 0 if (!defined $append);
		$encoding = "utf8" if (!defined $encoding);
		my $err = 0;
		open (FILE1, ($append ? ">" : "") . ">:encoding($encoding)", $fileName) or $err = 1;
		if ($err == 1) {
			die "Can't write file \"$fileName\" [$!]\n"
		}
		print FILE1 $content;
		close FILE1;
		return 1;
	}

	sub openFile {
		my ($self, $file_name, $codification) = @_;
		$codification = "utf-8" if (!defined $codification || $codification =~ /^\s*$/);
		my $err = 0;
		local $/;
		open (FILE2, "<", $file_name) or $err = 1;
		if ($err == 1) {
			die "Can't read file \"$file_name\" [$!]\n";
		}
		my $fileContent = <FILE2>;
		close FILE2;
		if ($codification eq "utf-8") {
			eval { $fileContent = Encode::decode("utf-8", $fileContent, Encode::FB_CROAK); };
			$fileContent = Encode::decode("utf-16", $fileContent, Encode::FB_CROAK) if ($@);
		}
		elsif ($codification =~ /^\s*$/) { }
		else { $fileContent = Encode::decode($codification, $fileContent, Encode::FB_CROAK); }
		return $fileContent;
	}

	sub yieldLines {
		my ($self, $file_name, $function, $codification) = @_;
		$codification = "utf-8" if (!defined $codification || $codification =~ /^\s*$/);
		my $err = 0;
		open (FILE3, $file_name) or $err = 1;
		if ($err == 1) {
			die "Can't read file \"$file_name\" [$!]\n";
		}
		eval {
			while(my $line = <FILE3>) {
				if ($codification eq "utf-8") {
					eval { $line = Encode::decode("utf-8", $line, Encode::FB_CROAK); };
					$line = Encode::decode("utf-16", $line, Encode::FB_CROAK) if ($@);
				}
				elsif ($codification =~ /^\s*$/) { }
				else { $line = Encode::decode($codification, $line, Encode::FB_CROAK); }
				chomp $line;
				$line =~ s/﻿//g; # Remove BOM
				my $stop = $function->($line, $.);
				last if (esylio->isNumber($stop) && $stop == 1);
			}
		};
		close FILE3;
		die $@ if $@;
	}

	sub countFileLines {
		my $self = shift;
		my ($file_name, $codification) = @_;
		my $overallCount = 0;
		esylio->yieldLines($file_name, sub { $overallCount += 1; return 0; }, $codification);
		return $overallCount
	}

	sub isPathString {
		my ($self, $str) = @_;
		return 0 if ($^O =~ /win/i && length $str > 260 || $^O =~ /linux/i && length $str > 4096);
		$str .= " ";
		return $str =~ m/^(?:[\\\/]?(?:.+[\\\/])+[^\\\/]+|[^\n]+)$/;
	}

	sub parseFilePath {
		my ($self, $filePath) = @_;
		my($filename, $dir, $suffix) = File::Basename::fileparse($filePath);
		$filename =~ /(.*?)(\.[^\.]*)?$/;
		my $nameWithoutExtension = $1;
		my $extension = $2;
		return ($filename, $dir, $nameWithoutExtension, $extension);
	}

	sub parseFilePathAsHash {
		my $self = shift;
		my ($path) = @_;
		my ($filename, $dir, $nameWithoutExtension, $extension) = $self->parseFilePath($path);
		return (
			fullName => $filename,
			directory => $dir,
			name => $nameWithoutExtension,
			extension => $extension,
			fullPath => $path
		);
	}

	sub getFileNameExtension {
		my $class = shift;
		my ($filePath) = @_;
		my ($filename, $dir, $nameWithoutExtension, $extension) = $class->parseFilePath($filePath);
		return ($dir . $nameWithoutExtension, $extension);
	}

	sub addToName {
		my ($self, $filePath, $textToAdd) = @_;
		my ($filename, $dir, $nameWithoutExtension, $extension) = parseFilePath($self, $filePath);
		return "$dir$nameWithoutExtension$textToAdd$extension";
	}

	sub changeExtension {
		my ($self, $filePath, $newExtension) = @_;
		my ($filename, $dir, $nameWithoutExtension, $extension) = parseFilePath($self, $filePath);
		return "$dir$nameWithoutExtension$newExtension";
	}

	sub hashKeysToArray {
		my ($self, %hash) = @_;
		return sort { lc($a) cmp lc($b) } keys %hash;
	}

	sub arrayToString {
		my ($self, $slicer, @array) = @_;
		my $ret = "";
		for (my $i = 0; $i < scalar(@array); $i++) {
			$ret .= $array[$i]."$slicer";
		}
		return $ret;
	}

	sub getCommonLetters {
		my ($self, @words) = @_;
		my $ret = $words[0];
		for (my $i = 1; $i < scalar(@words); $i++) {
			my $temp = "";
			while ($ret =~ /(.)/g) { $temp .= $1 if ($words[$i] =~ /($1)/); }
			$ret = $temp;
		}
		return $ret;
	}

	sub crossArrays {
		my ($self, $base, @arrays) = @_;
		if (@arrays > 2) {
			my @tempArr = $arrays[0];
			for (my $i = 1; $i < @arrays; $i++) { @tempArr = [$self->crossArrays("", @tempArr, $arrays[$i])]; }
			@tempArr = @{$tempArr[0]};
			for (my $i = 0; $i < @tempArr; $i++) { $tempArr[$i] = $base . $tempArr[$i]; }
			return @tempArr;
		}
		elsif (@arrays == 2) {
			my @ret;
			foreach my $ar1 (@{$arrays[0]}) {
				foreach my $ar2 (@{$arrays[1]}) { push @ret, "$base$ar1 $ar2"; }
			}
			return @ret;
		}
		else { die "At least 2 arrays were expected."; }
	}

	sub blockRunner (&@) {
		my $self = shift;
		my $code = \&{shift @_};
		my ($printingSub, $action, @args) = @_;
		$printingSub->($action);
		$printingSub = sub { print shift; } unless defined $printingSub;
		die "Only CODE values allowed." unless (ref $printingSub eq "CODE");
		my @ret = $code->(@args);
		$printingSub->("[done]\n");
		return @ret;
	}

	sub executeConsoleCommand {
		my ($self, $command) = (shift, join ' ', @_);
		my $output = "";
		my $status ;
		my $time = $self->timeSub(sub {
			$output = qx{$command 2>&1};
			$status = $? >> 8;
		});
		return $status, $output, $time;
	}

	sub getDiskElements {
		my ($self, $rootPath, $addPath, $reject_regex) = @_;
		$addPath = 1 if (!defined $addPath);
		opendir(DIR, $rootPath) or die $!;
		my @directories_files_arr;
		while (my $directory_or_file_name = readdir(DIR)) {
			next if (defined $reject_regex && $directory_or_file_name !~ /$reject_regex/);
			if ($directory_or_file_name !~ /^\.+$/) {
				my $finalPath = $directory_or_file_name;
				$finalPath = $rootPath . ($^O =~ /linux/ ? '/' : '\\') . $directory_or_file_name if ($addPath);
				push @directories_files_arr, $finalPath;
			}
		}
		closedir(DIR);
		return @directories_files_arr;
	}

	sub getDiskElementsAsHash {
		my ($self, $rootPath, $addPath, $reject_regex) = @_;
		my @elements = $self->getDiskElements($rootPath, $addPath, $reject_regex);
		my @ret;
		for my $e (@elements) {
			push @ret, { $self->parseFilePathAsHash($e) };
		}
		return @ret;
	}

	sub isNumber {
		my ($self, $val) = @_;
		return 0 unless defined $val;
		return Scalar::Util::looks_like_number($val);
	}

	sub getScriptInfo {
		my ($filename, $dir, $nameWithoutExtension, $extension) = shift->parseFilePath($0);
		return $dir, $filename;
	}

	sub arrayAsHashKeys {
		my ($self, $value, $keyFilter, @array) = @_;
		$keyFilter = sub { return shift } if (!defined $keyFilter);
		die "Only CODE values allowed." if (ref $keyFilter ne "CODE");
		my %ret;
		$ret{$keyFilter->($_)} = $value foreach (@array);
		return %ret;
	}

	sub seekElementInArray {
		my ($self, $element, $keyFilter, @array) = @_;
		die "Only CODE values allowed." if (!defined $keyFilter || ref $keyFilter ne "CODE");
		my $count = 0;
		foreach my $val (@array) {
			return $count if ($element eq $keyFilter->($val));
			$count += 1;
		}
		return -1;
	}

	sub customDie {
		my ($self, $message) = @_;
		#$message =~ s/^/    /gm;
		my $sub_name = (caller(1))[3];
		$sub_name = "__ANON__" if !defined $sub_name || $sub_name =~ /__ANON__/;
		$message = "Error at \"$sub_name\":\n$message";
		$message .= "\n" unless $message =~ /\n\s*$/;
		die $message;
	}

	sub assertRef2 {
		my $self = shift;
		my ($obj, $type, $dieOnUndef) = @_;
		die "Type missmatch at " . (caller(1))[3] . ":\nExpected '$type', provided '" . (ref $obj) . "'.\n" if defined $obj && ref $obj ne $type || $dieOnUndef && !defined $obj;
		return $obj;
	}

	sub assertRef {
		my ($self, %params) = @_;
		my $obj = $params{obj} if (exists $params{obj});
		my $rgx = $params{errRgx} if (exists $params{errRgx});
		my $type = $params{type} if (exists $params{type});
		my $paramName = $params{name} if (exists $params{name});
		my $dieOnUndef = $params{dieOnUndef} if (exists $params{dieOnUndef});
		my $title = (caller(1))[3] . (defined $paramName ? " (by $paramName)" : "") . ":";
		my $msg = "";
		if (defined $obj) {
			$msg .= "\\ Expected type: $type\n  Provided type: " . ref $obj if (defined $type && ref $obj ne $type);
			$msg .= "\\ Unexpected value." if (defined $rgx && ref $obj eq "" && $obj =~ /$rgx/);
			if ($msg !~ /^\s*$/) {
				$msg = "Assertion error.\n" . $msg;
				$msg =~ s/^/    /gm;
				die "$title\n$msg\n";
			}
		}
		else {
			die "$title\n    No value provided.\n" if (defined $dieOnUndef && $dieOnUndef);
		}
	}

	sub iterateOverArray {
		my ($self, $function, @array) = @_;
		my @ret;
		push @ret, $function->($_) foreach (@array);
		return @ret;
	}

	sub randomNumByThread {
		my $class = shift;
		my ($max) = @_;
		$max = 1000 unless $max;
		return $$ . int(rand($max));
	}

	sub getNumDec {
		my $class = shift;
		my ($number) = @_;
		die "No number provided.\n" unless esylio->isNumber($number);
		my @a = split /[\.,]/, $number;
		return length $a[1];
	}

1;

##################
### i made dis ###
### esyl       ###
##################