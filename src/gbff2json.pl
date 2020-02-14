#!/usr/bin/env perl 
###############################################################################
#
# A GenBank GBFF file to JSON file converter
#
# Author:  Qianqian Fang <q.fang at neu.edu>
# License: BSD 3-clause
# Version: 0.5
# URL:     http://openjdata.org
# Github:  https://github.com/fangq/covid19/
#
###############################################################################

use strict;
use warnings;
use JSON 'to_json';
use Tie::IxHash;

if($#ARGV<0){
	print("gbff2json.pl - converting GenBank database file to a JSON/JData file
	Format: gbff2json.pl <options> input.gbff > output.json
The supported options include (multiple parameters can be used, separated by spaces)
	-m	convert key names to MATLAB friendly forms, otherwise, keeps the original key names
	-C	use all-caps for top-level key names, otherwise, capitalize only the first letter
	-c	print JSON in compact form, otherwise, print in the indented form\n");
	exit 0;
}

my ($key1, $key2, $key3, $originkey)=("","","","Origin");
my ($lastobj,$value, $options);
my %jsonopt=(utf8 => 1, pretty => 1);

tie my %obj1, "Tie::IxHash";
tie my %obj2, "Tie::IxHash";
tie my %obj3, "Tie::IxHash";

# parse commandline options, the last input is assumed to be the .gbff file or stdin
$options='';
while(my $opt = $ARGV[0]) {
    if($opt =~ /^-[mcC]$/){
	$options.='m'         if($opt eq '-m');
	$jsonopt{'pretty'}=0  if($opt eq '-c');
	if($opt eq '-C'){
	    $options.='C';
	    $originkey="ORIGIN";
	}
	shift;
    }else{
	last;
    }
}

while(<>){ # loop over each line of the input file
	next if(/^\s*$/);  # skip empty lines
	if(/^((\s*)(\S+)(\s+))(.*)/){  # line format: |$1=[(ws1=$2)key=$3(ws2=$4)]remaining=$5|
		my $ln=$_;
		$value=$4.$5;
		if(length($2)==0){ # a first level key start at the begining of the line
			if((keys %obj3)>0){ # attaching lower-level objects
				push(@{$obj2{$key2}},rmap(\%obj3,$options));
				%obj3=();
				$key3="";
			}
			if((keys %obj2)>0){
				push(@{$obj1{$key1}},rmap(\%obj2,$options));
				%obj2=();
				$key2="";
			}
			last if(/^\/\/$/);
			$key1= (!($options=~/C/)) ? ucfirst(lc($3)) : $3;
			push(@{$obj1{$key1}}, $5) if $5 ne '';
			$lastobj=$obj1{$3};
		}elsif(length($2)<12){ # a second level key starts within 12 spaces from the beginning
			if((keys %obj3)>0){  # attaching lower-level objects
				push(@{$obj2{$key2}},rmap(\%obj3,$options));
				%obj3=();
				$key3="";
			}
			push(@{$obj2{$3}}, $5) if $5 ne '';
			$key2=$3;
			$lastobj=$obj2{$3};
		}elsif($3 =~/^\/([a-z_]+)="{0,1}(.*)$/){ # a 3rd level key starts with "/keyname=..."
			$key3=$1;
			$value=$2.$value;
			$value=~s/"*\s*$//g;
			push(@{$obj3{$key3}},$value);
			$lastobj=$obj3{$key3};
		}else{                       # appending line to the last object
			$ln=~s/^\s+|"*\s+$//g;
			if(join('',map { ref() eq 'HASH' ? 1 : 0} $lastobj) ==0){
				${$lastobj}[0].= $ln;
			}else{
				push(@{$lastobj}, $ln);
			}
		}
	}
}

%obj1=%{rmap(\%obj1,$options)};

# concatenate ORIGIN hash values into a single string for easy lookup
if($obj1{$originkey}){
	$obj1{$originkey}=join('',map { $obj1{$originkey}{$_}} keys %{$obj1{$originkey}});
	$obj1{$originkey}=~s/\s//g;
}

# output the final JSON

print to_json(\%obj1,\%jsonopt);

###############################################################################

sub rmap{
	my ($obj,$opt)=@_;
	tie my %res, "Tie::IxHash";
	%res= map { $_ => (ref($obj->{$_}) eq 'ARRAY' &&  @{$obj->{$_}}>0) 
	              ? ( @{$obj->{$_}}==1 ? ${ $obj->{$_} }[0] : 
		           (@{$obj->{$_}} %2 ==0 ? fixkey($obj->{$_},$opt) : $obj->{$_} ) )
		      : $obj->{$_}
	         } keys %{$obj};
	return \%res;
}

sub fixkey{
	my ($obj,$opt)=@_;
	tie my %res, "Tie::IxHash";
	for (my $i = 0; $i < @{$obj}; $i += 2) {
	    my($k, $v) = @$obj[$i,$i+1];
	    $res{validname($k,$opt)}=$v;
        }
	return \%res;
}

# create matlab/octave friendly key names
sub validname{
	my ($str,$opt)=@_;
	return $str if (! ($opt=~ /m/));
	$str=~s/[\s\/,()]/_/g;  # replace white spaces, commas and "/" by "_" without losing info
	$str=~s/(\d+)\.\.(\d+)/From_$1_to_$2/g;  # replace start..end pairs by From_start_to_end
	return $str;
}