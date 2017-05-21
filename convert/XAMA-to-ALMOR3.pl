#! /usr/bin/perl

$| = 1;
use MADA::ALMOR3;
##############################################################################
# XAMA-to-ALMOR3.pl
# Copyright (c) 2009,2010 Columbia University in 
#               the City of New York
#
# Please do not distribute to anyone else without written permission
# from authors.  If you know someone who can use this software, please 
# direct them to http://www1.ccls.columbia.edu/~cadim/MADA, where they
# may freely obtain the software.  Doing this helps us to understand how
# our software is being used, and to make future improvements tailored to
# the needs of users.
#
# MADA, TOKAN and ALMOR are distributed in the hope that they will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#
#
# For more information, bug reports, fixes, contact:
#    Nizar Habash, Owen Rambow and Ryan Roth
#    Center for Computational Learning Systems
#    Columbia University
#    New York, NY 10115
#    USA
#    habash@cs.columbia.edu
#    ryanr@ccls.columbia.edu
#
#######################################################################
# This script that reads a XAMA (BAMA or SAMA) directory and a 
# corresponding map file, and creates an ALMOR database file from its
# contents. In this way, MADA can (in principle) make use of any 
# BAMA or SAMA version, condensing their data to a common format. This
# does, however, require a properly arranged *.map file.  Currently,
# we only provide a map for SAMA 3.1, which MADA has been tuned for.
# We hope to offer more maps (for older BAMA versions) in the near future.
# 
# This script only needs to be run once on MADA's installation to create
#  the ALMOR database that MADA will use thereafter.
#
#
##############################################################################


# argument handling
$argc  = @ARGV;
die "Usage: $0 <map> <XAMA-directory> <ALMOR-DB>\n"
    if ($argc != 3);

my ($map,$dir,$almordb)=@ARGV;

my $stemmode="bama"; # basic style; or "tsv", the style used 

open (MAP,$map) || die "Can't open map file [$map]\n";
open (PRE,"$dir/dictPrefixes") || die "Can't open file [$dir/dictPrefixes]\n";
open (SUF,"$dir/dictSuffixes") || die "Can't open file [$dir/dictSuffixes]\n";

if (-e "$dir/dictStems"){				      
    open (STEM,"$dir/dictStems");			      
}elsif (-e "$dir/dictStems.tsv"){			      
    open (STEM,"$dir/dictStems.tsv");			      
    $stemmode="tsv";					      
}else { die "Can't open file [$dir/dictStems(\.tsv)?]\n";}   

open (TABAB,"$dir/tableAB") || die "Can't open file [$dir/tableAB]\n";
open (TABAC,"$dir/tableAC") || die "Can't open file [$dir/tableAC]\n";
open (TABBC,"$dir/tableBC") || die "Can't open file [$dir/tableBC]\n";
open (ALMR,">$almordb") || die "Can't open file [$almordb]\n";

##############################################################################
# Read MAP
my %MAP = ();
my $mapset=""; 
my $mapmode="";
my %FEAT = ();
my %OUTPUT=();


print STDERR "Reading map file ... \n";

while (my $line=<MAP>){
    chomp $line;
    if ($line =~/^;/){
	#skip comment
    }elsif ($line =~/^\s*$/){
	#skip empty
    }elsif ($line=~/^(DEFINE|MAP|EXTEND)\s+(\S+)/){ 
       #DEFINE: NOANLYSIS/DEFAULTS/FEATURE:VALUE/STEMBACKOFF
       #PREFIXES/SUFFIXES/STEMS/CAT2POS
	$mapmode=$1;
	$mapset=$2;
	$mapset=~tr/[A-Z]/[a-z]/;
	$mapmode=~tr/[A-Z]/[a-z]/;
    }elsif ($mapmode eq "define"){
	if  (($mapset eq "feature:value")&&($line=~/^(\S+)\s+(.*)\s*$/)){
	    my ($feat,$vals)=($1,$2);
	    foreach my $val (split(/\s+/,$vals)){
		$FEAT{"$feat:$val"}=$feat;
	    }
	}elsif ($mapset eq "defaults"){

	    if ($line=~/^(\@\S+)\s+(.*)\s*$/){
		my ($def,$featvals)=($1,$2);
		$featvals=~s/\s+/ /g;
		$FEAT{"DEFCLASS $def"}=$featvals;
	    }elsif ($line=~/^MEMBERS\s+(\@\S+)\s+(.*)\s*$/){
		my ($def,$poses)=($1,$2);
		foreach my $pos (split(/\s+/,$poses)){
		    $FEAT{"DEFAULT $pos"}=&ALMOR3::featureStr2Hash($FEAT{"DEFCLASS $def"}." $pos");
		}
	    }
	}elsif ($mapset eq "noanalysis"){
	    if ($line=~/^CLASS\s+(\S+)\s+(\S+)\s*$/){
		my $noanorder=" $1/$2";
		if (not exists $FEAT{"NOANALYSIS"}){
		    $FEAT{"NOANALYSIS"}=$noanorder;
		}else{
		    $FEAT{"NOANALYSIS"}.=$noanorder;
		}
	    }
	}elsif ($mapset eq "order"){
	    #$line=~s/\s*$//;
	    #$line=~s/(\S+)/$1:-/g;
	    $FEAT{"ORDER"}=$line;
	}elsif ($mapset eq "stembackoff"){
	    $line=~s/\s+/ /g;
	    $FEAT{"STEMBACKOFF $line"}=1;
	    foreach my $bcat (split (/\s+/,$line)){
		$FEAT{"STEMBACKOFF-$bcat"}=1;
	    }
	}
    }elsif ($mapmode eq "extend"){
	if  (($mapset eq "lexeme")&&($line=~/^(\S+)\s+(.*)\s*$/)){
	    my ($lex,$featval)=($1,$2);
	    $FEAT{"LEX $lex"}=$featval;
	}elsif (($mapset eq "lexeme/stem")&&($line=~/^(\S+)\s+(.*)\s*$/)){
	    my ($lexstem,$featval)=($1,$2);
	    $FEAT{"LEXSTEM $lexstem"}=$featval;
	}
    }elsif ($mapmode eq "map"){
	if ($line=~/^(\S+)\s+(.*)\s*$/){
	    my ($form,$func)=($1,$2);
	    push @{$MAP{"$mapset:$form"}}, $func;
	}
    }
}
close (MAP);
print STDERR "... done\n";
##############################################################################

##############################################################################
# Read Dicts and Print Almor.db


print STDERR "Definitions and Defaults ... \n";

print ALMR "###DEFINE FEATURE:VALUE###\n";
my %RMAP=();
foreach my $key (keys %FEAT){
    if ($key=~/^(\S+):(\S+)$/){
	$RMAP{$FEAT{$key}}.=" $key";
    }
}
foreach my $key (keys %RMAP) {
    print ALMR "DEFINE $key"."$RMAP{$key}\n";
}
#-----------------------------------------
print ALMR "###DEFAULTS###\n";
foreach my $key (keys %FEAT){
    if ($key=~/DEFAULT/){
	print ALMR "$key ";
	my $default=&ALMOR3::featureHash2Str($FEAT{"ORDER"},$FEAT{"$key"});
	print ALMR "$default\n";
    }
}
print ALMR "###ORDER###\n";
foreach my $key (keys %FEAT){
    if ($key=~/ORDER/){
	print ALMR "$key ".$FEAT{"$key"}."\n";
    }
}
print ALMR "###STEMBACKOFF###\n";
foreach my $key (keys %FEAT){
    if ($key=~/STEMBACKOFF /){
	print ALMR "$key\n";
    }
}
#-----------------------------------------
print STDERR "Reading Prefixes ... \n";
print ALMR "###PREFIXES###\n";
while (my $line=<PRE>) {
   # print "$line";
    &processLine("prefixes",$line);
}
close (PRE);
print STDERR "... done\n";
#-----------------------------------------
print STDERR "Reading Suffixes ... \n";
print ALMR "###SUFFIXES###\n";
while (my $line=<SUF>) {
   # print "$line";
    &processLine("suffixes",$line);
}
close (SUF);
print STDERR "... done\n";
#-----------------------------------------
print STDERR "Reading Stems ... \n";
print ALMR "###STEMS###\n";
while (my $line=<STEM>) {
   # print "$line";
    &processLine("stems",$line);
}
close (STEM);
print STDERR "... done\n";
#-----------------------------------------
print STDERR "Reading Tables ... \n";
print ALMR "###TABLE AB###\n";
while (my $line=<TABAB>) {
    &processLine("tables",$line);
}
close (TABAB);
#-----------------------------------------
print ALMR "###TABLE BC###\n";
while (my $line=<TABBC>) {
    &processLine("tables",$line);
}
close (TABBC);
#-----------------------------------------
print ALMR "###TABLE AC###\n";
while (my $line=<TABAC>) {
    &processLine("tables",$line);
}
close (TABAC);
#-----------------------------------------

print STDERR "... done\n";





close (ALMR);
##############################################################################
sub processLine {
    my ($mapset,$line)=@_;
    $line=~s/\s*$//;    #chomp($line) is insufficient;

    #print STDERR "PROCESS ($mapset) $line\n";


    if (($mapset eq "stems")&&($stemmode eq "tsv")){
 	#convert to old style:
 	my ($undiac,$diac,$cat,$gloss,$pos,$lex)=split('\t',$line);
 	$MAP{"lex"}=$lex;
	#A not so elegant solution to an ugly problem: missing voice
	if (($pos=~/VERB/)&&($pos!~/\+/)){ 
	    $line="$undiac\t$diac\t$cat\t$gloss";
	}else{
	    $line="$undiac\t$diac\t$cat\t$gloss  <pos>$pos<\/pos>";
	}
    }
    
    if ($line =~/^;/){
	#skip comment
	if ($line =~/^;\-\-\- (\S+)/){
	    $MAP{"root"}=$1;
	}elsif ($line =~/^;; (\S+)/){
	    $MAP{"lex"}=$1;
	}

    }elsif ($line =~/^\s*$/){
	#skip empty
    }elsif ($mapset eq "tables"){
	print ALMR "$line\n";
    }else{
	my ($undiac,$diac,$cat,$gloss)=split('\t',$line);
	$pos=$gloss;
	$gloss=~s/<pos>.*//;
	$gloss=~s/\s+$//;
	$gloss=~s/\s+/\_/g;
	$pos=~s/^.*(<pos>)/$1/; if ($pos !~/<pos>/) {$pos="";}
	$pos=~s/<pos>\s*(.*)\s*<\/pos>/$1/;

	$cat=~s/\s//g; #because some cats actually had spaces by mistake!!!

	$undiac=~s/(\s|[aiuo\~\`FKN\_])//g; #just in case!
	$undiac=~s/[>|<\{]/A/g;
	$undiac=~s/Y/y/g;
	$undiac=~s/p/h/g;


	#print "($undiac,$diac,$cat,$gloss)\n";
	
	if ($pos eq ""){
	    #use cat2pos map; assume one mapping only!
	    my $glosscap="";
	    if ($gloss=~/^[A-Z]/){$glosscap="GLOSSCAP++";}
	    if (@{$MAP{"cat2pos:$glosscap$cat"}}>1){
		print STDERR "Warning - ambiguous cat2pos mapping unhandled: cat2pos:$glosscap$cat \n";
	    }
	    ($pos)=@{$MAP{"cat2pos:$glosscap$cat"}};
	    if ($pos eq ""){ #just in case
		($pos)=@{$MAP{"cat2pos:$cat"}};
	    }

	    if ($diac ne ""){ $pos="$diac/$pos" }
	}

	
	my @func=("");

	if ($mapset eq "stems"){

	    @func=("lex:$MAP{lex}");
	}
	
	#print STDERR "func (@func)\n";
	my @funci=&getMAP("$mapset","$pos");

	#print STDERR "funci (@funci)\n";
	
	foreach my $flex (@funci){
	    if ($flex=~/(lex:\S+)/){
		my $flextemp=$1;
		if ($mapset eq "stems"){
		    @func=($flextemp);
		}
	    }
	}

	@func=@{ &ALMOR3::multiplySets(\@func,\@funci) };
	
	
	# Remove all malformed functional sets:
	my @goodfunc= @{ &ALMOR3::trimMalformed(\@func) };
	
	#print "$func\n\t$goodfunc\n";
	

	if (@goodfunc==0){
	    my $funcprint=sprintf("(@func)");
	    if ($funcprint=~/pos:IGNORE/){
		#ignore silently
	    }else{
		print "Warning - Entry ignored. Functional morphology malformed: $line\t(@func)\n\n";
	    }
	}
	@func=@goodfunc;
	

	
	foreach my $f (@func){
	    
	    my %FS=%{ &ALMOR3::featureStr2Hash("$f diac:$diac bw:$pos gloss:$gloss") };
	    
	    if (($mapset eq "stems")&&(exists $FS{"pos"})){
		$FSpos=$FS{"pos"};

		my %default=%{$FEAT{"DEFAULT pos:$FSpos"}};
		%FS=%{ &ALMOR3::featureMerge(\%default,\%FS) };

		my %ExtendLexFS=();
		if (exists $FEAT{"LEX $FS{'lex'}"}){
		    %ExtendLexFS=%{ &ALMOR3::featureStr2Hash($FEAT{"LEX $FS{'lex'}"}) };
		    %FS=%{ &ALMOR3::featureMerge(\%FS,\%ExtendLexFS) };
		}
		 
		$f=&ALMOR3::featureHash2Str($FEAT{"ORDER"},\%FS);
		
	    }else{
		$f=&ALMOR3::featureHash2Str("ignore-empty ".$FEAT{"ORDER"},\%FS);
	    }

	    if ($f=~/gloss:NOT_IN_LEXICON/){
		#ignore line for Buckwalter X+ backoff
	    }else{
		if (exists $OUTPUT{"$undiac\t$cat\t$f"}){
		    #do not print out again
		}else{
		    $OUTPUT{"$undiac\t$cat\t$f"}=1;
		    print  ALMR "$undiac\t$cat\t$f\n";
		}
		
		#ALMOR BACKOFF
		if (($mapset eq "stems")&&($FEAT{"STEMBACKOFF-$cat"})){ 
		    $f=~s/diac:\S+/diac:NOAN/;
		    $f=~s/gloss:\S+/gloss:NO_ANALYSIS/;
		    $f=~s/lex:\S+/lex:NOAN_0/;
		    $f=~s/bw:\S+\/([^\/]+)/bw:NOAN\/$1/;
		    $f=~s/source:lex/source:backoff/;
		    
		    if (exists $OUTPUT{"NOAN\t$cat\t$f"}){
			#do not print out again
		    }else{
			$OUTPUT{"NOAN\t$cat\t$f"}=1;
			print  ALMR "NOAN\t$cat\t$f\n";
		    }
		}
	    }
	}
    }
}

#-----------------------------------------
sub getMAP {

    my ($mapset,$form,$nomore)=@_;

# MATCH ORDER
# (word/pos)+... => (pos)+ => Union of word/pos's => Union of pos (+) ..
# put in tab separated alternatives
    #print STDERR "getMap:  $mapset  $form   $nomore .\n";

    my @func=("");
    if ($form eq ""){ #Pref-0 and Suff-0
	@func=("");
    }elsif (exists $MAP{"$mapset:$form"}){
	@func=@{$MAP{"$mapset:$form"}};
    }else {
	my $BWPOS=$form;
	$BWPOS=~s/[^\/\+]+\///g;
	if (exists $MAP{"$mapset:$BWPOS"}){
	    @func=@{$MAP{"$mapset:$BWPOS"}};
	}else{
	    if ($nomore!=1){
		my @form=split('\+',$form);
		foreach my $formi (@form) {
		    my @funci= &getMAP($mapset,$formi,1);
		    @func=@{ &ALMOR3::multiplySets(\@func,\@funci) };
		}
	    }
	    if (@func==0){
		@func=("UNK");
	    }
	}
    }
    @func=@{ &ALMOR3::markMalformed(\%FEAT,\@func) };
    
    return (@func);
}
