#! /usr/bin/perl

use English;
$OUTPUT_AUTOFLUSH = 1;
#use ALMOR3;

##############################################################################
# Standard Arabic to Dialectal Arabic conversion
##############################################################################

# argument handling
$argc  = @ARGV;
die "Usage: $0 <SA-DA-map> <ALMOR-DB-SA> <ALMOR-DB-DA> <STDERR-Print-Less=0/1> (> <rulesAdded.w4> )?\n"
    if ($argc != 3 && $argc != 4);

my ($map,$almorsa,$almordi,$printLess)=@ARGV;

if (! defined $printLess) {
    $printLess = 0;
}

open (MAP,$map) || die "Can't open map file [$map]\n";
open (ALMRS,"$almorsa") || die "Can't open file [$almorsa]\n";
open (ALMRD,">$almordi") || die "Can't open file [$almordi]\n";

##############################################################################
# Read MAP
my @MAPSA = ();
my @MAPDA = ();
my $map=0;

print STDERR "Reading map file ... \n";

while (my $line=<MAP>){
    chomp $line;

    if (($line!~/^\s*$/)&&($line!~/^\#/)){
	#H Ha Ha/FUT_PART prc1:Ha_fut << s sa sa/FUT_PART prc1:sa_fut 



	if ($line=~/^\s*(.*) << (.*)\s*$/){
	    my ($da,$sa)=($1,$2);
	    $sa=~s/\+/\\\+/g;
	    my @sa=split(/\s+/,$sa);
	    my @da=split(/\s+/,$da);
	    
	    @{$MAPSA[$map]}=@sa;
	    @{$MAPDA[$map]}=@da;
	    $map++;
   	}
    }
}
close (MAP);
print STDERR "... done\n";
##############################################################################

##############################################################################
# Read Almor-SA and print Almor-DA

#-----------------------------------------
print STDERR "Reading ALMOR-SA ... \n";
print ALMRD "# Automatically generated file from $almorsa\n";
my @lines=<ALMRS>;
close (ALMRS);
my $warnings = "";
my $gradualSize = @lines;
for (my $map=0; $map<@MAPSA; $map++){ # For each rule in the map:

    print "RULE $map:\t@{$MAPDA[$map]} << @{$MAPSA[$map]}\n"; # to the directed output
    if ($printLess) {
	print STDERR "RULE $map: "; #to the screen
    } else {
	print STDERR "RULE $map:\t@{$MAPDA[$map]} << @{$MAPSA[$map]}\n"; #to the screen
    }
    #H Ha Ha/FUT_PART prc1:Ha_fut << s sa sa/FUT_PART prc1:sa_fut 
    my ($surfs,$diacs,$bws,@feats)=@{$MAPSA[$map]};
    my ($surfd,$diacd,$bwd,@featd)=@{$MAPDA[$map]};

    my ($surfpre,$surfsuf,$diacpre,$diacsuf,$bwpre)=("\\S\*","\\S\*","\\S\*","\\S\*","\\S\*");
    if ($surfs=~s/^!//){$surfpre=""}
    if ($surfs=~s/!$//){$surfsuf=""}
    if ($diacs=~s/^!//){$diacpre=""}
    if ($diacs=~s/!$//){$diacsuf=""}
	
    my $addedRulesCount=0;
    $gradualSize = @lines;
    my $indexDi = 0; my @linesDi=();
    for (my $i=0; $i<$gradualSize; $i++) { #For each line in the DB
	chomp($lines[$i]);
    
	my $line=$lines[$i];
	$linesDi[$indexDi++] = $line;
	#my @line=split('\t',$line);

	if ($line=~s/^($surfpre)$surfs($surfsuf\t\S+\tdiac:$diacpre)$diacs($diacsuf bw:$bwpre)$bws/$1$surfd$2$diacd$3$bwd/){
	    my $match=1;
	    foreach my $f (@feats) {
		if ($line=~/$f/) {$match=$match;} else {$match=0;}
	    }
	    if (1 == $match) {
		#print STDERR "$line\nlines:$i\n";
		print STDERR ".";
		$addedRulesCount++;
    
		for (my $j=0; $j<@featd; $j++){
		    $featd[$j] =~ /^(.*):(.*)/;
		    my $featName = $1;
		    my $fs_value="";
		    #print STDERR "@feats\n";
		    my $fs = join (" ", @feats);
		    if ($fs =~ /$featName:(\S+)/){
			$fs_value = $1;
			#print STDERR "\n** $fs ==> $fs_value **\n";
		    } else {
			$fs_value = "(\\S+)";
			#print STDERR "\n** $fs ==> $fs_value **\n";
		    }
		    if ($line =~ /$featName:$fs_value/) {
			$line =~ s/$featName:$fs_value/$featd[$j]/;
		    }
		    else {
			$line .= " $featd[$j]";
		    }
		}
		#$lines[$index] = $line;
		$linesDi[$indexDi++] = $line;
		print "$line\n"; # to the directed output
	    }
	}
    }
    @lines = @linesDi;
    if ($addedRulesCount > 0) {
	print STDERR ": [$addedRulesCount]\n";
    } else {
	print STDERR "###############################\n";
	print STDERR "THIS RULE DID NOT ADD ANY LINE!\n";
	print STDERR "###############################\n";
	$warnings .= ", $map";
    }
    #$gradualSize = @lines;
}
if ($warnings) {
    print STDERR "Rules that did not add any lines (if any) are: $warnings.\n";
}
for (my $i=0; $i < @lines; $i++) {

    print ALMRD "$lines[$i]\n";
#    print "$line\n";
}
    
print STDERR "... done\n";
#-----------------------------------------
close (ALMRD);

##############################################################################
