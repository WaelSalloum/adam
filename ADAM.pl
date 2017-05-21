#! /usr/bin/perl

use English;
$OUTPUT_AUTOFLUSH = 1;
use FindBin;                 # locate this script
use lib "$FindBin::Bin/";  # use the parent directory
use MADA::ALMOR3; 

##############################################################################
# some of the code is from AraMorph.pl ???
##############################################################################

# argument handling
$argc  = @ARGV;
die "Usage: $0 <ADAM-DB> <backoff>?\n <backoff> ::= {none, noan-all, noan-prop, add-all, add-prop}\n none : No backoffs are generated (Default mode)\n noan-all : For cases with no lexicon-based analyses, all possible backoff analyses are generated\n noan-prop : For cases with no lexicon-based analyses, only backoffs that are proper nouns are generated\n add-all : All possible backoff analyses are generated and added to existing lexicon analyses\n add-prop : Proper noun backoff analysese are generated and added to existing lexicon analyses\n"
    if ($argc <1);

my $dbase=$ARGV[0];
my $backoff=$ARGV[1];
if( ! defined $backoff ) { $backoff = "none"; }  ## Default backoff mode

my $ALMOR3DB=&ALMOR3::initialize($dbase);

print STDERR "#Running [ADAM]. Copyright (c) 2012 Columbia University.\n";

while (my $line=<STDIN>) {
    chomp $line;
    my @out=();
    #@out=&ALMOR3::AlmorProcess($line);
    @out=@{ &ALMOR3::analyzeSolutions($line,$ALMOR3DB,$backoff)};
    foreach my $o (@out){
	print "$o\n";
    }
    #print "(@out)\n";
}
 
