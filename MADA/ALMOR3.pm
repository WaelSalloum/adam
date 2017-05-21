package ALMOR3;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( initialize analyzeSolutions generateSolutions isPunct);

$| = 1;  ## OUTPUT_AUTOFLUSH

#######################################################################
# ALMOR3.pm
# Copyright (c) 2004-2012 Columbia University in 
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


=head1 NAME

    ALMOR3 -- Arablic Lexeme-baed Morphology Analyzer

=head1 DESCRIPTION

    This library contains the functionality of the ALMOR software. For
    general use, only the initialize(), analyzeSolutions() and
    generateSolutions() functions are typically needed; the other
    functions in this library are for internal use.

=cut



##################################################################################

=head2 Public Methods


=head3 initialize

    Example of use:

    ## $ALMOR_DB the path and file name of the almor.db file

    my $ALMOR_DBref = &ALMOR3::initialize($ALMOR_DB);   ## Defaults to "analysis" mode

    my $ALMOR_DBref_gen = $ALMOR3:initialize($ALMOR_DB,"generation");  # Database in "generation" mode

    my $ALMOR_DBref2 = $ALMOR3:initialize($ALMOR_DB,"analysis",1);  # Database in "analysis mode, with
                                                                    # quiet mode turned on


    Reads the ALMOR database file and creates an internal ALMOR
    data structure in memory, and returns a reference to this structure.
    initialize() must be run prior to calling other ALMOR functions.


    Databases can be initialized for "analysis" or "generation" tasks, but not both.
    "analysis" is the default.  Scripts requiring both "analysis" and
    "generation" will need to run initialize() twice, creating two
    separate data structures.


=cut


sub initialize {
  my ($dbase,$mode,$quiet) = @_ ;
  my $sublex="";
  my %hash = ();

  if ($mode eq ""){ $mode="analysis";}
  elsif ($mode!~/^(analysis|generation)$/){
      die "Error: unrecognized mode [$mode]\n";
  }
  if( ! defined $quiet ) { $quiet = 0; }

  if( ! $quiet ) {
      print STDERR "loading database [$dbase] in [$mode] mode ...\n";
  }

  open (DB,"$dbase") || die "cannot open $dbase\n";
  
  while (my $entry = <DB>){
      chomp $entry;
      if ($entry eq "###PREFIXES###"){
	  $sublex = "pre#";
      }elsif ($entry eq "###SUFFIXES###"){
	  $sublex = "suf#";
      }elsif ($entry eq "###STEMS###"){
	  $sublex = "stem#";
      }elsif ($entry eq "###TABLE AB###"){
	  $sublex = "tAB#";
      }elsif ($entry eq "###TABLE BC###"){
	  $sublex = "tBC#";
      }elsif ($entry eq "###TABLE AC###"){
	  $sublex = "tAC#";
      }elsif ($sublex=~/^t(AB|BC|AC)#$/){
	  $hash{"$sublex$entry"}=1;
	  if ($sublex=~/^t(AB|BC)\#/){
	      my ($xcat,$ycat)=split(' ',$entry);
	      if ($sublex eq "tAB#"){
		  push @{$hash{"PRECAT $ycat"}}, $xcat;
	      }else{ #tBC
		  push @{$hash{"SUFCAT $xcat"}}, $ycat;
	      }
	  }
      }elsif ($entry=~s/^DEFINE //){
	  my ($feature,@fv)=split('\s+',$entry);
	  foreach my $fv (@fv){
	      $hash{"$fv"}=$feature;
	  }
      }elsif ($entry=~s/^DEFAULT //){
	  my ($pos)=split('\s+',$entry);
	  $hash{"DEFAULT $pos"} = &featureStr2Hash($entry);

      }elsif ($entry=~s/^ORDER //){
	  $hash{"ORDER"}=$entry;
	  
	  #move this step to Form2Func
	  #get list of features with countable values for generation purposes
	  foreach my $f (split (' ',$entry)) {
	      if ($f!~/^(lex|bw|XAMACAT|XAMASURF|gloss|diac|Xsize|Xfeat)/){
		  $hash{"Xfeat $f"}=1;
		  push @{$hash{"Xfeat"}},$f;
	      }
	  }
      }elsif ($entry=~s/^STEMBACKOFF (\S+) //){
	  my $backoffclass=$1;
	  foreach my $backoffcat (split(/\s+/,$entry)) {
	      $hash{"STEMBACKOFF $backoffclass $backoffcat"}=1;
	  }
      }elsif ($entry!~/^###/) {
	  $entry=~s/^(\S*)\t(\S+)\t//;
	  my $undiac=$1;
	  my $cat=$2;

	  if ($mode=~/analysis/i){
	      my %FS= %{ &featureStr2Hash("$entry XAMACAT:$cat") };
	      push @{$hash{"$sublex$undiac"}},\%FS;
	  }else{  #if ($mode=~/generation/i)
	      my %FS= %{ &featureStr2Hash("$entry XAMACAT:$cat XAMASURF:$undiac") };
	      
	      if ($sublex eq "stem#"){
		  my $lex=$FS{"lex"};
		  push @{$hash{"LEX#$lex"}},\%FS;
=pod
		  my $Xsize=0; #number of content-valid features
		  my @Xfeat=();
		  foreach my $f (keys %FS){
		      my $v=$FS{$f};
		      if ($f eq ""){ #no feature cases are Pre-0 and Suf-0
			  $v="";
			  push @{$hash{"$sublex#FEAT#$f:$v"}},\%FS;
		      }elsif ($hash{"Xfeat $f"}){#only count features that are real
			  my $v=$FS{$f};
			  $Xsize++;
			  push @Xfeat,$f;
			  push @{$hash{"$sublex#FEAT#$f:$v"}},\%FS;
		      }
		  }
		  $FS{"Xsize"}=$Xsize;
		  @{$FS{"Xfeat"}}=@Xfeat; #countable features for matching
=cut

	      }else{
		  push @{$hash{"FEAT#$cat"}},\%FS;
		  my $Xsize=0; #number of content-valid features
		  my @Xfeat=();
		  foreach my $f (keys %FS){
		      my $v=$FS{$f};
		      if ($f eq ""){ #no feature cases are Pre-0 and Suf-0
			  $v="";
			  push @{$hash{"$sublex#FEAT#$f:$v"}},\%FS;
		      }elsif ($hash{"Xfeat $f"}){#only count features that are real
			  my $v=$FS{$f};
			  $Xsize++;
			  push @Xfeat,$f;
			  push @{$hash{"$sublex#FEAT#$f:$v"}},\%FS;
		      }
		  }
		  $FS{"Xsize"}=$Xsize;
		  @{$FS{"Xfeat"}}=@Xfeat; #countable features for matching
	      }
	  }
      }
  }
  close(DB);
  return(\%hash);
}


##################################################################################

=head3 analyzeSolutions

    ALMOR3::analyzeSolutions($word,$DBhashref,$backoffmode)
 
    Example of use:

    my $DBhashref = &ALMOR3::initialize("almor.db"); ## defaults to "analysis" mode
    my $word = "Ely";
    my $backoffmode = "add-all";
    my @analyses = @{ &ALMOR3::analyzeSolutions($word,$DBhashref,$backoffmode) }

    ## @analyses now includes the lexical generated analyses (including spelling variations),
    ##  and every addition analysis that can be generated from affixes (the most exhaustive backoff mode)



    This function uses the ALMOR database to generate feature:value sets (analyses)
    for different interpretations of a given Arabic word.

    The ALMOR database is passed as a reference, and generated by ALMOR3::initialize().

    The backoff mode can be one of the following:

       none      :  No backoffs are generated (Default mode)
       noan-all  :  For cases with no lexicon-based analyses, all possible backoff analyses are generated
       noan-prop :  For cases with no lexicon-based analyses, only backoffs that are proper nouns are generated
       add-all   :  All possible backoff analyses are generated and added to existing lexicon analyses
       add-prop  :  Proper noun backoff analysese are generated and added to existing lexicon analyses

    If the backoff mode is "none" (or is undefined), it is possible that this function will return
    an empty array reference.

    Returns a reference to an array of analyses.

=cut

sub analyzeSolutions { # returns a list of 1 or more solutions
    my ($word,$hash, $backoff)=@_;
    #my %hash = %$hash;

    if( ! defined $backoff ) { $backoff = "none"; }  ## Default backoff mode

    my (@output) = ();
    my @solutions = (); 
    my $cnt = 0;


    ## Handle deterministic (trivial) cases 
    if ($word =~/^\s*$/){
	#Word is just whitespace
	return [$word];

    }elsif (( $word=~/[BCceGIJLMOPQRUVWX]/ ) || ($word=~/^(\s|[aiuo\~\`FKN\_])*$/)){
	##  Word is likely a non-Arabic word
	my %default=%{$$hash{"DEFAULT pos:noun"}};
	$default{"diac"}=$word; $default{"lex"}=$word."_0"; $default{"bw"}=$word."/FOREIGN"; $default{"gloss"}=$word; $default{"source"}="foreign";
	my $analysis=&featureHash2Str($$hash{"ORDER"},\%default);
	return [$analysis];
	
    }elsif ( $word=~/\d+/ ){
	##  Word contains digits
	my %default=%{$$hash{"DEFAULT pos:noun_num"}};
	$default{"diac"}=$word; $default{"lex"}=$word."_0"; $default{"bw"}=$word."/NOUN_NUM"; $default{"gloss"}=$word; $default{"source"}="digit";
	my $analysis=&featureHash2Str($$hash{"ORDER"},\%default);
	return [$analysis];
	    
    }elsif ( &isPunct($word) ){
	## Word is a string of punctuation characters (excepting those used by Buckwalter)
	my %default=%{$$hash{"DEFAULT pos:punc"}};
	$default{"diac"}=$word; $default{"lex"}=$word."_0"; $default{"bw"}=$word."/PUNC"; $default{"gloss"}=$word; $default{"source"}="punc";
	my $analysis=&featureHash2Str($$hash{"ORDER"},\%default);
	return [$analysis];
    }else{


    my $matchword=$word;
    
    $matchword=~s/(\s|[aiuo\~\`FKN\_])//g; 
    my $unvocword=$matchword; #just no voc.

    $matchword=~s/[>|<\{]/A/g;
    $matchword=~s/Y/y/g;
    $matchword=~s/p/h/g;

    if ($matchword eq ""){
	$matchword=$word;
    }


    my @segmented= @{ &segmentword($matchword,$hash) };
    foreach my $segmentation (@segmented) {
	 #print "( $segmentation )\n";
	my ($prefix,$stem,$suffix) = split ("\t",$segmentation); 
	
	if (exists($$hash{"stem#$stem"})){
	  #  if (exists($hash{"pre#$prefix"})) {
		#if (exists($hash{"suf#$suffix"})) {

		   #  print "($prefix,$stem,$suffix)\n";
		    foreach my $stem_value (@{$$hash{"stem#$stem"}}){
			my  $cat_b = $$stem_value{"XAMACAT"};
			
			foreach my $prefix_value (@{$$hash{"pre#$prefix"}}) {
			    my $cat_a = $$prefix_value{"XAMACAT"};
			    
			    if ( exists($$hash{"tAB#$cat_a $cat_b"}) ) {
				
				foreach my $suffix_value (@{$$hash{"suf#$suffix"}}) {
				    my $cat_c = $$suffix_value{"XAMACAT"};	
				    
				    if ( exists($$hash{"tBC#$cat_b $cat_c"}) ) {
					if ( exists($$hash{"tAC#$cat_a $cat_c"}) ) {
					    
					    my $bb=$$stem_value{"bw"};
					    
					    #my $aa=$$prefix_value{"bw"};
					    #my $cc=$$suffix_value{"bw"};
					    
						#my $gloss = "$gloss_a+$gloss_b+$gloss_c";
						my $gloss = $$stem_value{"gloss"};
												
						my $BW = $$prefix_value{"bw"}."+".$$stem_value{"bw"}."+".$$suffix_value{"bw"};
						#$BW=~s/\+/\#/g;
						
						#update Sept 11 2008: to match up behavior of sun/moon letters in BAMA2
						# code segemnt from BAMA-2
						my $voc_str = $$prefix_value{"diac"}."+".$$stem_value{"diac"}."+".$$suffix_value{"diac"};
						$voc_str =~ s/^((wa|fa)?(bi|ka)?Al)\+([tvd\*rzs\$SDTZln])/$1$4~/; # not moon letters
						$voc_str =~ s/^((wa|fa)?lil)\+([tvd\*rzs\$SDTZln])/$1$3~/; # not moon letters
						$voc_str =~ s/A\+a([pt])/A$1/; # e.g.: Al+HayA+ap
						$voc_str =~ s/\{/A/g; 
						$voc_str =~ s/\+//g; 
						###
						my $unvoc_str=$voc_str;
						$unvoc_str=~s/(\s|[aiuo\~\`FKN\_])//g; 
						
						#prefer values in this order: STEM+default < prefix < suffix 
						#my $analysis=&CombineFS($aa,$bb,$cc);
						#my $analysis="$voc_str\t$BW\t$gloss\n";
						my %analysis = %{ &featureMergePSS($prefix_value,$stem_value,$suffix_value) };
						
						$analysis{"gloss"} = $$stem_value{"gloss"};
						$analysis{"bw"} = $$prefix_value{"bw"}."+".$$stem_value{"bw"}."+".$$suffix_value{"bw"};
						$analysis{"diac"} = $voc_str;

						if ($unvoc_str ne $unvocword){ $analysis{"source"}="spvar";}
						
						my $analysis = &featureHash2Str($$hash{"ORDER"},\%analysis);
						#push (@output, $analysis);
						my $voc_stem=$$stem_value{"diac"};
						push (@output, "$analysis stem:$voc_stem stemcat:$cat_b");
						
						
					    }
					}
				}
			    }
			}
		    }
#%=cut
		
	    
	}
    }
	
    #@output=@{ &trimMalformed(&markMalformed($hash,\@output)) };
    #@output=@{ &markMalformed($hash,\@output) };
    
    #Hard-coded solutions:
    #CLASS LATIN	pos:latin
    #CLASS DIGIT	pos:digit
    #CLASS PUNC	pos:punc
    #CLASS else	pos:noun_prop

    #if( @output == 0 ) { print STDERR "NO LEXICAL ANALYSES\n"; }

    if (@output==0 && $backoff =~ /^noan-(all|prop)$/i ){

	@output = @{ &ALMOR3::backoffAnalyze($word, $hash, $backoff) };

	
	## No analysis produced, so default to noun_prop
#	my %default=%{$hash{"DEFAULT pos:noun_prop"}};
#	$default{"diac"}=$word; $default{"lex"}=$word."_0"; $default{"bw"}=$word."/NOUN_PROP"; $default{"gloss"}=$word;
#	my $analysis=&featureHash2Str($hash{"ORDER"},\%default);
#	push (@output, $analysis);
 
    }


    if( $backoff =~ /^add-(all|prop)$/i ) {

	my @backoff = @{ &ALMOR3::backoffAnalyze($word, $hash, $backoff) };
			 
	@output = (@output, @backoff);

    }

	
    ## Probably a more efficient way of doing the following step ?
    @output=@{ &unique(\@output) };
    
    return \@output;
    }
}

##################################################################################

=head3 generateSolutions

    ALMOR3::generateSolutions($morphfeats,$DBhashref,$gmode)
 
    Example of use:

    my $DBhashref = &ALMOR3::initialize("almor.db", "generate"); ## Make sure to use "generate" mode
    
    # $morphfeats contains the morphological feat list for a given word (as
    #   would be created by MADA

    my @solutions = &ALMOR3::generateSolutions($morphfeats,$DBhashref,"diac")

    ## @solutions now includes an array containing word elements corresponding to
    ##   $morphfeats


    In general, $gmode should be set to "diac", which will cause the output
    elements to contain surface diac forms.
    
    If $gmode is not set to "diac", the output elements will contain addditional
    Buckwalter tag information.

    RETURNS A REFERENCE TO AN ARRAY.

=cut


sub generateSolutions { # returns a list of 1 or more solutions

    my ($lexfeats,$hash,$gmode)=@_;
        
    my %LF= %{ &featureStr2Hash($lexfeats) };
    
    my %output = ();
    my @solutions = (); 
    my $cnt = 0;
  

    my $lex=$LF{"lex"};

    my @base=();
    my $noan=0;
    my $STEM="";


    if (exists $$hash{"LEX#$lex"}){
	@base=@{$$hash{"LEX#$lex"}};
    }else{

	#NO LEX!
	if ($lex=~/(\S+)\_0/){
	    $STEM=$1;
	    my @output=();

	    #Handle basic trivial cases #source could be used?
	    if (($STEM=~/[BCceGIJLMOPQRUVWX]/)&&($LF{"pos"} eq "noun")){
		if ($gmode eq "diac"){ 
		    @output=($STEM);
		}else{
		    @output=("$STEM\t$STEM\t$STEM/FOREIGN");
		}
		return \@output;
	    }elsif (($STEM=~/\d+/)&&($LF{"pos"} eq "noun_num")){
		if ($gmode eq "diac"){ 
		    @output=($STEM);
		}else{
		    @output=("$STEM\t$STEM\t$STEM/NOUN_NUM");
		}
		return \@output;
	    }elsif ((&isPunct($STEM))&&($LF{"pos"} eq "punc")){
		if ($gmode eq "diac"){ 
		    @output=($STEM);
		}else{
		    @output=("$STEM\t$STEM\t$STEM/PUNC");
		}
		return \@output;
	    }
	}
	@base=@{$$hash{"LEX#NOAN_0"}};
	$noan=1;

    }


    my $maxmatch=0;

    foreach my $x (@base){ #for every stem that matches the lexeme in input
	
#	$$x{"Xsize"}=0;
	
#	foreach my $ff (keys %LF){
#	    if ($LF{$ff} eq  $$x{$ff}){
#		$$x{"Xsize"}++;
#	    }
#	}


#	my $Z=&featureHash2Str("anyorder",$x);
#	print "LEX>> ". $$x{"diac"} ."\t$Z\n";
#	my $Z=&featureHash2Str("anyorder",\%LF);
#	print "LF>>\t$Z\n";

	
	# Multi-step process to avoid searching the whole space of Prefix/Suffix combinations
	# 1. get initial stem set from lexeme
	#    1.a eliminate LEX that diagree with pos
	# for each stem
	# 2. get prefix and suffix sets that are compatible with stem (precompiled) by category
	#    2.a eliminate cases with disagreement with input (feature:value not present yet feature is present)
	# 3. final check of CAT (A-C) xand rank by coversize


	#ignore POS mismatch cases...
	if (($$x{"pos"} eq $LF{"pos"})
	    && (((exists $LF{"stem"})&&($$x{"diac"} eq $LF{"stem"}))
		||(not exists $LF{"stem"}))){
	    # step 1
	    my $cat_b=$$x{"XAMACAT"};
	    
	    # step 2
	    my @prefixes=();
	    my @suffixes=();
	   
	    foreach my $ff (@{$$hash{"pre##FEAT#:"}}){
		push @prefixes, $ff;
	    }
	    				    
	    foreach my $ff (@{$$hash{"suf##FEAT#:"}}){
		push @suffixes, $ff;
	    }

	    #GET ALL PREFIXES COMPATIBLE WITH cat_b
	    #Only keep prefixes with matching present features

	    #since Prefixes currently override all features... They must be a complete match!
	    
	    foreach my $precat (@{$$hash{"PRECAT $cat_b"}}){
		foreach my $prefix (@{$$hash{"FEAT#$precat"}}){
		    my $match=1;
		    foreach my $f (@{$$prefix{"Xfeat"}}){
			if ($$prefix{$f} ne $LF{$f}){
			    $match=0;
			    last;
			}
		    }
		    if ($match){
			push @prefixes, $prefix;
		    }
		}	      
	    }

	    #GET ALL SUFFIXES COMPATIBLE WITH cat_b
	    #consider matching Prefixes??
	    # suffixes can have partial match...
	    foreach my $sufcat (@{$$hash{"SUFCAT $cat_b"}}){
		foreach my $suffix (@{$$hash{"FEAT#$sufcat"}}){
		    $$suffix{"Xsize"}=0;
		    foreach my $f (@{$$suffix{"Xfeat"}}){
			if ($$suffix{$f} eq $LF{$f}){
			    $$suffix{"Xsize"}++;
			} 
		    }
		    if ($$suffix{"Xsize"}>0){
			push @suffixes, $suffix;
		    }
		}	      
	    }

	    
	   # my $xxx=@prefixes; print "CNT PREF $xxx\n";
	   # my $xxx=@suffixes; print "CNT SUF $xxx\n";


	    foreach my $pre (@prefixes){
		foreach my $suf (@suffixes){
		    
		    #print $$pre{"bw"}."  +  ".$$x{"bw"}."  +  ".$$suf{"bw"} ."\n";
		    
		    my $cat_a=$$pre{"XAMACAT"};
		    my $cat_c=$$suf{"XAMACAT"};
		    if ( exists($$hash{"tAC#$cat_a $cat_c"}) ){
			#my $match=$$pre{"Xsize"}+$$x{"Xsize"}+$$suf{"Xsize"};
			my $match=&featureMergePSSandMatch($pre,$x,$suf,\%LF);
			#print "$match $maxmatch\n";

			if ($match >= $maxmatch){
			    
			    my $out = $$pre{"diac"}."+".$$x{"diac"}."+".$$suf{"diac"};
			    my $surfdiac=&BWMorphotactics($out);
			    
			    #DIFFERENT GMODES
			    if ($gmode eq "diac"){
				$out= "$surfdiac";
			    }else{
				my $BWout = $$pre{"bw"}."+".$$x{"bw"}."+".$$suf{"bw"};
				$out= "$surfdiac\t$out\t$BWout";
			    }
			    
			    #print "\t$match\t$out\n";

			    if ($match > $maxmatch){
				%output=();
				$output{$out}=1;
				$maxmatch=$match;
			    }elsif ($match==$maxmatch){
				$output{$out}=1;
			    }
			}
		    }
		}
	    }




	}
    }
   # @output=@{ &unique(\@output) };


    my @output=(keys %output);

    if ($noan){
	for (my $i=0; $i<@output; $i++){

	    $output[$i]=~s/NOAN/$STEM/g;

	}
    }


    return \@output;
 

}

  
##################################################################################

=head3 isPunct

    ALMOR3::isPunct( $str )
 
    Example of use:

    if(  ALMOR3::isPunct( $str ) ) {
       # Process punctuation string
    }

    Returns true if the input string is a sequence of ASCII punctuation
    characters, not counting the Buckwalter reserved characters:

      {}<>|&$'`~*

    Returns false if other characters are present.

    Whitespace at the beginning and end of the word is ignored.


=cut

sub isPunct {
    my ($str) = @_;
    my $result = 0;

    if( $str =~ /^\s*[\-\=\"\_\:\#\@\!\?\^\/\(\)\[\]\%\;\\\+\.\,]+\s*$/ ) {
	$result = 1;
    }
    return $result;
}


##################################################################################

=head2 Private Methods


=head3 backoffAnalyze

    ALMOR3::backoffAnalyze($word, $backoffmode)
 
    Example of use:

    my $word = "Ely";
    my $backoffmode = "add-all";
    my @backoff = @{ &ALMOR3::backoffAnalyze($word, $backoffmode) }

    ## @backoff now includes the backoff generated analyses

    The backoff mode can be one of the following:

       none      :  No backoffs are generated -- function will return a reference to an empty list
       noan-all  :  For cases with no lexicon-based analyses, all possible backoff analyses are generated
       noan-prop :  For cases with no lexicon-based analyses, only backoffs that are proper nouns are generated
       add-all   :  All possible backoff analyses are generated and added to existing lexicon analyses
       add-prop  :  Proper noun backoff analysese are generated and added to existing lexicon analyses


    Returns a reference to an array of analyses.

=cut



sub backoffAnalyze { 
    my ($word,$hash, $backoff)=@_;
    my @output = ();
    my @solutions = (); 
    my $cnt = 0;
   
    

    if ( $backoff =~ /^none$/i ) { return \@output; }  # to guard against improper calls to this function
    else {

	#print "call backoff \n";
	
	my $matchword=$word;
	#This could be passed along to save time....
	$matchword=~s/(\s|[aiuo\~\`FKN\_])//g; 
	$matchword=~s/[>|<\{]/A/g;
	$matchword=~s/Y/y/g;
	$matchword=~s/p/h/g;
	
	if ($matchword eq ""){
	    $matchword=$word;
	}
	
	
	my @segmented= @{ &segmentword($matchword,$hash) };
	foreach my $segmentation (@segmented) {
	    
	    my ($prefix,$stem,$suffix) = split ("\t",$segmentation); 
	    
	    foreach my $prefix_value (@{$$hash{"pre#$prefix"}}) {
		my $cat_a = $$prefix_value{"XAMACAT"};
		
		foreach my $suffix_value (@{$$hash{"suf#$suffix"}}) {
		    my $cat_c = $$suffix_value{"XAMACAT"};	
		    
		    if ( exists($$hash{"tAC#$cat_a $cat_c"}) ) {
			
			foreach my $stem_value (@{$$hash{"stem#NOAN"}}) {
			    
			    my  $cat_b = $$stem_value{"XAMACAT"};
			    my $bb=$$stem_value{"bw"};
			    
			    ## Only produce allowed analyses
			    
			    if (( $backoff =~ /prop$/i )&&
				(($bb!~/NOUN\_PROP/)||
				 (not exists $$hash{"STEMBACKOFF PROP $cat_b"}))){
				$cat_b="NO_POSSIBLE_MATCH";
			    }elsif (( $backoff =~ /all$/i )&&
				    (not exists $$hash{"STEMBACKOFF ALL $cat_b"})){
				$cat_b="NO_POSSIBLE_MATCH";
			    }
			    
			    if ( exists($$hash{"tAB#$cat_a $cat_b"}) ) {
				if ( exists($$hash{"tBC#$cat_b $cat_c"}) ) {
				    
				    my $gloss = $$stem_value{"gloss"};
				    
				    my $BW = $$prefix_value{"bw"}."+".$$stem_value{"bw"}."+".$$suffix_value{"bw"};
				    
				    #update Sept 11 2008: to match up behavior of sun/moon letters in BAMA2
				    # code segemnt from BAMA-2
				    my $voc_str = $$prefix_value{"diac"}."+".$$stem_value{"diac"}."+".$$suffix_value{"diac"};
				    
				    $voc_str=&BWMorphotactics($voc_str);
				    
				    #prefer values in this order: STEM+default < prefix < suffix 
				    my %analysis = %{ &featureMergePSS($prefix_value,$stem_value,$suffix_value) };
				    
				    $analysis{"gloss"} = $$stem_value{"gloss"};
				    $analysis{"bw"} = $$prefix_value{"bw"}."+".$$stem_value{"bw"}."+".$$suffix_value{"bw"};
				    $analysis{"diac"} = $voc_str;
				    
				    $analysis{"lex"}=~s/NOAN/$stem/;
				    $analysis{"bw"}=~s/NOAN/$stem/;
				    $analysis{"diac"}=~s/NOAN/$stem/;
				    
				    my $analysis = &featureHash2Str($$hash{"ORDER"},\%analysis);
				    push (@output, "$analysis stem:$stem stemcat:$cat_b");
				    
				}
			    }
			}
		    }
		}
	    }
	}
    }
    return \@output;
}


##################################################################################

=head3 BWMorphotactics

    ALMOR3::BWMorphotactics($str)
 
    Example of use:

    $str = &ALMOR3::BWMorphotactics($str)



    Applies certain rules to input string:

      $str =~ s/^((wa|fa)?(bi|ka)?Al)\+([tvd\*rzs\$SDTZln])/$1$4~/; # not moon letters
      $str =~ s/^((wa|fa)?lil)\+([tvd\*rzs\$SDTZln])/$1$3~/; # not moon letters
      $str =~ s/A\+a([pt])/A$1/; # e.g.: Al+HayA+ap
      $str =~ s/\{/A/g; 
      $str =~ s/\+//g; 

    Returns the resulting string.


=cut

sub BWMorphotactics {
    my ($str)=@_;

    $str =~ s/^((wa|fa)?(bi|ka)?Al)\+([tvd\*rzs\$SDTZln])/$1$4~/; # not moon letters
    $str =~ s/^((wa|fa)?lil)\+([tvd\*rzs\$SDTZln])/$1$3~/; # not moon letters
    $str =~ s/A\+a([pt])/A$1/; # e.g.: Al+HayA+ap
    $str =~ s/\{/A/g; 
    $str =~ s/\+//g; 

    return($str);

}

##################################################################################

=head3 segmentword

    ALMOR3::segmentword($word,$ALMORDBref)
 
    Example of use:

    # $ALMORDBref is the reference returned by ALMOR3::initialize()

    my @segmented= @{ &segmentword($word,$ALMORDBref) };

   
    Returns a reference to an array of valid segmentations for a given
    word.

    Based on a function from BAMA.

=cut


sub segmentword { 
# returns a list of valid segmentations 
# based on a function from BAMA

    my ($str,$hash)=@_;
    my @segmented = ();
    my $prefix_len = 0;
    my $suffix_len = 0;
    my $stem_len = 0;
    my $prefix="";
    my $suffix="";
    my $stem="";
    my $str_len = length($str);

    while ( $prefix_len <= 6 ) {
	$prefix = substr($str, 0, $prefix_len);
	if (exists($$hash{"pre#$prefix"})) {
	    $stem_len = ($str_len - $prefix_len); 
	    $suffix_len = 0;
	    while (($stem_len >= 1) and ($suffix_len <= 6)) {
		$stem   = substr($str, $prefix_len, $stem_len);
		$suffix = substr($str, ($prefix_len + $stem_len), $suffix_len);
		if (exists($$hash{"suf#$suffix"})) {
		    push (@segmented, "$prefix\t$stem\t$suffix");
		}
		$stem_len--;
		$suffix_len++;
	    }
	}
	$prefix_len++;
    }
    return \@segmented;   
}



	  
	

##################################################################################

###=head3 mergeFeatures
###
###    ALMOR3::mergeFeatures($word,@feats)
### 
###    Older, broken function.  Use featureMerge(), etc., instead.
###
###=cut

#sub  mergeFeatures{
    #overaly features in order passed
#    my ($word,@feat)=@_;
#    my %func=();

    #naturally overwrite in the order read!
#    foreach my $x (split('\s+',join(' ',@feat))) {
#	$x=~/^([^:]+):(.*)$/;
#	my ($f,$v)=($1,$2);
#	
#	$func{$f}=$v;
#    }

#    my $fout="";#&featureHash2Str($hash{"ORDER"},\%func);

    # print "$fout\n";
#    return($fout);
#}



#sub  mergeFeatures{
#    my ($hash,$word,$pre,$stem,$suf)=@_;
#
#   # print "MERGE: ($hash,$word,$pre,$stem,$suf)\n";
#
#    my %hash = %$hash;
#    my $pos="pos:*";
#    my %pre=();
#    my %stem=();
#    my %suf=();
#    my %func=();
#
#    if ($stem=~/(pos:\S+)/){
#	$pos=$1;
#    }else{
#	print STDERR "No POS > $word ($pre,$stem,$suf)\n";
#    }
#    
#    my $default=$hash{"DEFAULT $pos"};
#
#    my %pre= %{ &featureStr2Hash($pre) };
#    my %stem= %{ &featureStr2Hash($stem) };
#    my %suf= %{ &featureStr2Hash($suf) };
#    my %func= %{ &featureStr2Hash($default) };
#
#    foreach my $key (keys %func){
#	#prefer values in this order: STEM > prefix > suffix > default (is this good??) 
#
#	if (exists $stem{$key}){ $func{$key}=$stem{$key}; }
#	elsif (exists $pre{$key}){ $func{$key}=$pre{$key}; }
#	elsif (exists $suf{$key}){ $func{$key}=$suf{$key}; }
#    }
#    my $fout=&featureHash2Str($hash{"ORDER"},\%func);
#
#   # print "$fout\n";
#    return($fout);
#}


#sub formAnalysis {
#    my ($a)=@_;
#    my %a=();
#    foreach $a (split('\s+',$a)){
#	$a=~s/^/5:::/;
#	$a=~s/5:::diac:/1:::diac:/;
#	$a=~s/5:::lex:/2:::lex:/;	
#	$a=~s/5:::pos:/3:::pos:/;
#	$a=~s/5:::BW:/6:::BW:/;
#	$a=~s/5:::gloss:/7:::gloss:/;
#	$a{$a}=1;
#    }
#    my @a=(keys %a);
#    @a=sort (@a);
#    $a=join(' ',@a);
#    $a=~s/\d::://g;
#    return ($a);
#}





##################################################################################

=head3 wellformed

    ALMOR3::wellformed($featureHashRef,$featureListString)
 
    This function checks that the same feature is not repeated with different value,
    and that all feature:value pairs are defined.

    Returns 1 if all valid feature:value pairs are present without duplicates,
    and 0 otherwise.

=cut
    
sub wellformed {
    #This function checks that the same feature is not repeated with different value.
    #And that all feature:value pairs are defined.

    my ($FEATref,$funcstr)=@_;
    
    my %FEAT=%{$FEATref};

    my $valid=0;
    
   # print "$func\n";

    my @func=split('\s+',$funcstr);
    foreach my $fv (@func){
	if ($FEAT{$fv}) {$valid++}
	else {
	    $fv=~s/:\S+/:*open*/;
	    if ($FEAT{$fv}) {$valid++}
	}
#	print "$fv\t$valid\n";
    }

    $funcstr=~s/(\S+):\S+/$1/g;

    my @func=split('\s+',$funcstr);

    my @funcunique=@{ &unique(\@func) };
    if ((@funcunique < @func)||($valid<@func)){
	return (0);
    }else{
	return (1);
    }
}


##################################################################################

=head3 sortFeatOrder

    ALMOR3::sortFeatOrder($feature_order_string,$feature_string)
 
    Given a feature:value string and an preferred order string,
    ( as defined under featureHash2Str() ) create a new string 
    that reorders the features accordingly.

    Returns a feature:value string.

=cut

sub sortFeatOrder {
    my ($order,$f)=@_;
    my $fout=&featureHash2Str($order, &featureStr2Hash($f));
    return($fout);
}


##################################################################################

=head3 overwrite

    ALMOR3::overwrite($feature_value_sting,$base_feature_value_string)
 
    Takes two feature:value strings.  Creates a new feature:value string
    (in no particular order) that has the values of the $base_feature_value_string,
    overwritten by the values (if present) from the first feature:value
    string.

    Returns a feature:value string.

=cut

sub overwrite {
    my ($x,$base)=@_;
    #apply $x overwirtes to base

    my %x= %{ &featureStr2Hash($x) };
    my %base= %{ &featureStr2Hash($base) };

    foreach my $key (keys %base){
	if (exists $x{$key}){
	    $base{$key}=$x{$key};
	}
    }
    my $fout=&featureHash2Str("anyorder",\%base);
    return($fout);
}


##################################################################################

=head3 trimMalformed

    ALMOR3::trimMalformed(\@func)
 
    Takes a reference to a list of strings (@func), and creates a new copy that 
    removes any elements that contained "MALFORMED".

    Returns a reference to a list.

=cut

sub trimMalformed {
    my ($funcref)=@_;
    my @newfunc=();
    
    foreach my $f ( @{$funcref} ){
	if ($f!~/MALFORMED/){
	    push @newfunc,$f;
	}
    }
    return(\@newfunc);
}

##################################################################################

=head3 markMalformed

    ALMOR3::markMalformed($featureHashRef, \@func)
 
    Given a feature hash reference and a refernce to a list of feature:value strings,
    checks each string and marks (directly into the original data structure) any 
    that are not wellformed() with a "MALFORMED" tag.
    
    Returns the reference to the original list

=cut

sub markMalformed {
    my ($FEAT,$funcref)=@_;

    for (my $f=0; $f<=$#{$funcref}; $f++){
	if (not &wellformed($FEAT,$funcref->[$f])){
	    $funcref->[$f]="MALFORMED $funcref->[$f]";
	}
    }
    return($funcref);
}

##################################################################################

=head3 multiplySets

    ALMOR3::multiplySets($list1Ref,$list2Ref)
 
    Given references to two lists, creates a new list
    where each element is a space-separated concatenation 
    of an element from each input list.

    Extraneous whitespace is removed from the new list
    in the process.

    Returns a reference to a list.

=cut

sub multiplySets {
    my ($a,$b)=@_;
    my @a=@{$a};
    my @b=@{$b};
    my @c=();
   # print "(@a) X (@b) =";

    foreach my $ai (@a){
	foreach my $bi (@b){
	    my $ci="$ai $bi";
	    $ci=~s/^\s*//; $ci=~s/\s*$//;
	    #print STDERR "multiplySets:  |$ci|\n";
	    my @tmp = split(/\s+/, $ci);
	    $ci=join(' ',@{ &unique(\@tmp) } );
	    push @c, "$ci";
	}
    }
    #print "(@c)\n";
    return(\@c);
}




######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
#Feature Structure Handling
#All FS will be a hash keyed on feature name;


##################################################################################

=head3 featureStr2Hash

    ALMOR3::featureStr2Hash($feat_value_string)
 
    Takes a string of feature:value pairs and returns a
    hash using the features as keys and the values as hash values.

    The structure is built such that later values in string override 
    earlier ones.

    Returns a reference to a hash.

=cut

sub featureStr2Hash {
    my ($x)=@_;
    my %x=(); 
    foreach my $xi (split('\s+',$x)){
	$xi=~/^([^:]+):(.*)$/;
	$x{$1}=$2;
    }
    return(\%x);
}

##################################################################################

=head3 featureHash2Str

    ALMOR3::featureHash2Str($feature_order_string, \%featureHash)
 
    Takes a feature hash reference and creates a feature:value string
    from it, according to the $feature_order_string.

    If $feature_order_string starts with "ignore-empty",
    then features mentioned in the $feature_order_string that
    have no values in the hash will not appear in the output.
    Otherwise, these features will appear in the output as
    "feature:-" tags.

    If $feature_order_string equals "anyorder", all the
    keys in the hash will be written to the output string
    in no particular order.

    Otherwise, each word in the $feature_order_string is
    assumed to be feature (key) names written in the same
    order as desired in the output.

    Returns a string.

=cut



sub featureHash2Str {
    my ($order,$xref)=@_;
    my %x = %{ $xref };
    my $marked=1;

    if ($order=~s/^ignore-empty //){
	$marked=0;
    }

    my @out=();
    
    if ($order eq "anyorder"){
	foreach my $o (keys %x){
	    push @out,"$o:$x{$o}";
	}
    }else{
	foreach my $o (split('\s+',$order)){
	    if ($x{$o} ne ""){
		push @out,"$o:$x{$o}";
	    }else{
		if ($marked){
		    push @out,"$o:-";
		}
	    }
	}
    }
    return(join(' ',@out));
}

##################################################################################

=head3 featureMerge

    ALMOR3::featureMerge($featHashRef1, $featHashRef2)
 
    Combines two feature hashes into a new one.

    The features in the 2nd Hash override the first unless the
    2nd hash feature does not exist, is empty, or has a value of "-"


    Returns a reference to a new hash.

=cut

sub featureMerge {
    my ($FSa,$FSb)=@_;

    my %FSn=();

    my %FSa=%$FSa;
    my %FSb=%$FSb;
    
    foreach my $f (keys %$FSa) {
	
	if ((exists $FSb{$f})&&($FSb{$f} ne "-")&&($FSb{$f} ne "")){
	    $FSn{$f}=$FSb{$f};
	}else{
	    $FSn{$f}=$FSa{$f};
	}
    }
    return(\%FSn);
}

##################################################################################

=head3 featureMergePSS

    ALMOR3::featureMergePSS($prefixHashRef, $stemHashRef, $suffixHashRef)
 
    Takes 3 hash references (corresponding to the prefixes, stems and suffixes),
    and builds a new hash.

    The new hash has the same keys as the stemHash, but takes the
    values of the prefixHash. If the prefixHash for that key is empty
    or "-", the suffixHash value used. If that is empty or "-",
    the stemHash value is used.


    Returns a reference to a new hash.

=cut

sub featureMergePSS { #prefix-stem-suffix; PREFIX > SUFFIX > STEM
    my ($FSa,$FSb,$FSc)=@_;

    my %FSn=();

    my %FSa=%$FSa;
    my %FSb=%$FSb;
    my %FSc=%$FSc;

    foreach my $f (keys %$FSb) {

	$FSn{$f}=$FSb{$f};
	
	if  ((exists $FSc{$f})&&($FSc{$f} ne "-")&&($FSc{$f} ne "")){
	    $FSn{$f}=$FSc{$f};
	}

	if ((exists $FSa{$f})&&($FSa{$f} ne "-")&&($FSa{$f} ne "")){
	    $FSn{$f}=$FSa{$f};
	}

    }
    return(\%FSn);
}


##################################################################################

=head3 featureMergePSSandMatch

    ALMOR3::featureMergePSSandMatch($prefixHashRef, $stemHashRef, $suffixHashRef, $referenceHashRef)
 
    Takes 4 hash references (corresponding to the prefixes, stems and suffixes
    and a reference).

    This function compares the values in the first the hashes to the
    reference values, and keeps a count of how many matches there are.

    Using the keys of the reference:
       - If: the prefixHash has a value that is not "-" or empty, 
            it and the reference value are compared.
       - Else:  If the suffixHash value is not empty or "-", 
            it and reference value are compared
       - Else:  the stemHash value and the reference value are compared.


    Returns the number of matches.

=cut

sub featureMergePSSandMatch { #prefix-stem-suffix; PREFIX > SUFFIX > STEM
    my ($FSa,$FSb,$FSc,$REF)=@_;

    my %FSn=();

    my %FSa=%$FSa;
    my %FSb=%$FSb;
    my %FSc=%$FSc;
    my %REF=%$REF;

    my $match=0;

    foreach my $f (keys %$REF) {

	if ((exists $FSa{$f})&&($FSa{$f} ne "-")&&($FSa{$f} ne "")){
	    if ($FSa{$f} eq $REF{$f}){ $match++ }
	}elsif  ((exists $FSc{$f})&&($FSc{$f} ne "-")&&($FSc{$f} ne "")){
	    if ($FSc{$f} eq $REF{$f}){ $match++ }
	}elsif ($FSb{$f}  eq $REF{$f}) {$match++}
    }
    return($match);
}



##################################################################################

=head3 unique

    ALMOR3::unique(@l)
 
    my @array = (1,2,4,5,2,3,4,2,1);
    @array = ALMOR3::unique(@array);
    # @array now is (1,2,3,4,5)

    Returns a reference to a new array of unique values contained in 
    the array referenced; the order of the elements sorted.

=cut


sub unique {
    my ($lref)=@_;
    my %lhash=();
    foreach my $l ( @{$lref} ){
	$lhash{$l}=1;
    }
    my @uniq = sort keys %lhash;
    return (\@uniq);
}



######################################################################
######################################################################
######################################################################
######################################################################
######################################################################


##################################################################################


## Related, older version of generateSolutions()

sub generateExamples { # returns a list of 1 or more solutions

    my ($instem,$incat,$hash)=@_;
  
    my %output = ();
 
    my @prefixes=();
    my @suffixes=();
   
 

    my $cat_b = $incat;
    
    #GET ALL PREFIXES COMPATIBLE WITH cat_b
   
    foreach my $precat (@{$$hash{"PRECAT $cat_b"}}){
	foreach my $prefix (@{$$hash{"FEAT#$precat"}}){
	    if ((exists $$prefix{"prc0"})||
		(exists $$prefix{"prc1"})||
		(exists $$prefix{"prc2"})||
		(exists $$prefix{"prc3"})){
		#ignore
	    }else{
		
		push @prefixes, $prefix;
	    }
	}
    }
    
    #GET ALL SUFFIXES COMPATIBLE WITH cat_b
    foreach my $sufcat (@{$$hash{"SUFCAT $cat_b"}}){
	foreach my $suffix (@{$$hash{"FEAT#$sufcat"}}){
	    unless (exists $$suffix{"enc0"}){
		if (($$suffix{"cas"} eq "n")&&
		    ((not exists $$suffix{"stt"}) || ($$suffix{"stt"} eq "d"))&&
		    (($$suffix{"num"} ne "d"))){
		    push @suffixes, $suffix;
		}
	    }
	}
    }
    	      

    if (@suffixes==0){
	foreach my $ff (@{$$hash{"suf##FEAT#:"}}){
	    push @suffixes, $ff;
	}
    }

    if (@prefixes==0){
	foreach my $ff (@{$$hash{"pre##FEAT#:"}}){
	    push @prefixes, $ff;
	}
    }


	    
    foreach my $pre (@prefixes){
	foreach my $suf (@suffixes){
	    
	    my $cat_a=$$pre{"XAMACAT"};
	    my $cat_c=$$suf{"XAMACAT"};
	    if ((exists($$hash{"tAC#$cat_a $cat_c"}))
		&& (exists($$hash{"tAB#$cat_a $cat_b"}))
		&& (exists($$hash{"tBC#$cat_b $cat_c"}))){
		my $out = $$pre{"diac"}."+".$instem."+".$$suf{"diac"};
		my $surfdiac=&BWMorphotactics($out);
				
		$out= "$surfdiac";
		$output{$out}=1;
	    }
	}
    }
    
    my @output=(keys %output);

    
    return (\@output);
 

}


##################################################################################
##################################################################################

=head1 KNOWN BUGS

    Currently in Development.  No bugs known.

=cut


=head1 SEE ALSO

    MADATools, MADAWord, TOKAN

=cut

=head1 AUTHOR

    Nizar Habash, Ryan Roth, Owen Rambow
    
    Center for Computational Learning Systems
    Columbia University
    
    Copyright (c) 2004,2005,2006,2007,2008,2009,2010 Columbia University in the City of New York

=cut


1;
