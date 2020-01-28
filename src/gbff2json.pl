#!/usr/bin/env perl 
###############################################################################
#
# A GenBank GBFF file to JSON file converter
#
# Author:  Qianqian Fang <q.fang at neu.edu>
# License: BSD 3-clause
# Version: 0.4
# URL:     http://openjdata.org
# Github:  https://github.com/fangq/gene2019ncov/
#
###############################################################################

use strict;
use warnings;
use JSON 'to_json';
use Tie::IxHash;

if($#ARGV<0){
	print("gbff2json.pl - converting GenBank database file to a JSON/JData file
	Format: gbff2json.pl input.gbff > output.json\n");
	exit 0;
}

my ($key1, $key2, $key3)=("","","");
my ($lastobj,$value);

tie my %obj1, "Tie::IxHash";
tie my %obj2, "Tie::IxHash";
tie my %obj3, "Tie::IxHash";

while(<>){
	next if(/^\s*$/);
	last if(/^\/\/$/);
	if(/^((\s*)(\S+)(\s+))(.*)/){
		my $ln=$_;
		$value=$4.$5;
		if(length($2)==0){
			if((keys %obj3)>0){
				push(@{$obj2{$key2}},rmap(\%obj3));
				%obj3=();
				$key3="";
			}
			if((keys %obj2)>0){
				push(@{$obj1{$key1}},rmap(\%obj2));
				%obj2=();
				$key2="";
			}
			push(@{$obj1{$3}}, $5);
			$key1=$3;
			$lastobj=$obj1{$3};
		}elsif(length($2)<12){
			if((keys %obj3)>0){
				push(@{$obj2{$key2}},rmap(\%obj3));
				%obj3=();
				$key3="";
			}
			push(@{$obj2{$3}}, $5);
			$key2=$3;
			$lastobj=$obj2{$3};
		}elsif($3 =~/^\/([a-z_]+)="{0,1}(.*)$/){
			$key3=$1;
			$value=$2.$value;
			$value=~s/"*\s*$//g;
			push(@{$obj3{$key3}},$value);
			$lastobj=$obj3{$key3};
		}else{
			$ln=~s/^\s+|"*\s+$//g;
			if(join('',map { ref() eq 'HASH' ? 1 : 0} $lastobj) ==0){
				${$lastobj}[0].= $ln;
			}else{
				push(@{$lastobj}, $ln);
			}
		}
	}
}
%obj1=%{rmap(\%obj1)};
print to_json(\%obj1,{utf8 => 1, pretty => 1});

sub rmap{
	my ($obj)=@_;
	tie my %res, "Tie::IxHash";
	%res= map { $_ => (ref($obj->{$_}) eq 'ARRAY' &&  @{$obj->{$_}}==1) ? ${ $obj->{$_} }[0] : $obj->{$_} } keys %{$obj};
	return \%res;
}