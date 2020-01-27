#!/usr/bin/perl

use strict;
use warnings;
use JSON 'to_json';
use Tie::IxHash;

if($#ARGV<0){
	print("gbff2json.pl - converting GeneBank database file to a JSON/JData file
	Format: gbff2json.pl input.gbff > output.json\n");
	exit 0;
}

my (%obj1, %obj2, %obj3);
my ($key1, $key2, $key3)=("","","");
my ($lastobj,$name,$value);

tie %obj1, "Tie::IxHash";
tie %obj2, "Tie::IxHash";
tie %obj3, "Tie::IxHash";

while(<>){
	next if(/^\s*$/);
	last if(/^\/\/$/);
	if(/^((\s*)(\S+)\s+)(.*)$/){
		$name=$3;
		$value=$4;
		if(length($2)==0){
			push(@{$obj1{$3}}, $4);
			if($key2 ne ""){
				push(@{$obj1{$key1}},rmap(%obj2));
				%obj2=();
				$key2="";
			}
			$key1=$3;
			$lastobj=$obj1{$3};
		}elsif(length($2)<12){
			push(@{$obj2{$3}}, $4);
			if($key3 ne ""){
				push(@{$obj1{$key2}},rmap(%obj3));
				%obj3=();
				$key3="";
			}
			$key2=$3;
			$lastobj=$obj2{$3};
		}elsif($3 =~/^\/([a-z_]+)=(.*)/){
			push(@{$obj3{$1}},"$2 $value");
			$key3=$1;
			$lastobj=$obj3{$1};
		}else{
			my $ln=$_;
			$ln=~s/^\s+|\s+$//g;
			push(@{$lastobj}, $ln);
		}
	}
}
%obj1=rmap(%obj1);
print to_json(\%obj1,{utf8 => 1, pretty => 1});

sub rmap{
	my (%obj)=@_;
	return map { ref() eq 'ARRAY' ? join("\n",@$_) : (ref() eq 'HASH' ? { map {rmap($_)} %$_ } : $_) } %obj;
}