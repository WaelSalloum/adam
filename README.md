# ADAM: Analyzer for Dialectal Arabic Morphology

Copyright 2012 (c) Columbia University. All Rights Reserved.

ADAM VERSION: 0.4
Authors: Wael Salloum and Nizar Habash. 

## CITATION

If you use ADAM, please cite this paper:

    (2011) Wael Salloum & Nizar Habash: Dialectal to standard Arabic
    paraphrasing to improve Arbaic-English statistical machine
    translation. [EMNLP 2011] DIALECTS2011: Proceedings of the First
    Workshop on Algorithms and Resources for Modelling of Dialects and
    Language Varieties, Edinburgh, Scotland, UK, July 31, 2011;
    pp.10-21.

[http://aclweb.org/anthology/W/W11/W11-2602.pdf]

--------------------------------------------------------------------------------

## INSTALLATION

### 1. Get a standard Arabic morphological database.
 
To use ADAM, you need to acquire one the morphological analyzers from
the Buckwalter Arabic Morphological Analyzer (BAMA) family --
henceforth (XAMA). There are three choices:

    a. SAMA 3.1 (Standard Arabic Morphological Analyzer).
        Go to LDC: http://www.ldc.upenn.edu/Catalog/CatalogEntry.jsp?catalogId=LDC2010L01
    b. BAMA 2.0 (Buckwalter Arabic Morphological Analyzer).
        Go to LDC: http://www.ldc.upenn.edu/Catalog/CatalogEntry.jsp?catalogId=LDC2004L02
    c. Aramorph 1.2 (FREE VERSION!!!)
        Go to Sourceforge: http://sourceforge.net/projects/aramorph/

### 2. Convert XAMA database to ADAM database:

Use the script convert/XAMA-to-ADAM.sh to create ADAM database from
your SAMA/BAMA/Aramorph database. 


Usage: 
--------

   $ bash convert/XAMA-to-ADAM.sh [XAMA-DB-Directory] [XAMA-Version] [ADAM-Version]
    
        [XAMA-DB-Directory]: is the directory that contains XAMA database that you have. 
                             For Example, for SAMA 3.1, it should be:
                                    SAMA-3.1/SAMA-3.1/lib/SAMA_DB/v3_1/
        
        <XAMA-Version>: takes one of these values:
                            SAMA3.1
                            BAMA2
                            ARAMORPH1.2.1
                            
        <ADAM-Version>: the version of ADAM you want to create.


Output: ADAM database in the current (package) directory.

Example:
--------

If you installed SAMA 3.1 under /home/tools/, run the following
command to create ADAM v0.4 database from SAMA 3.1.

$ bash convert/XAMA-to-ADAM.sh /home/tools/SAMA-3.1/SAMA-3.1/lib/SAMA_DB/v3_1/ SAMA3.1 0.4

Output: adam-v0.4.db in the current (package) directory

--------------------------------------------------------------------------------

## ANALYSIS WITH ADAM


Usage:
--------

perl ADAM.pl <ADAM-DB> <backoff>?
 <backoff> ::= {none, noan-all, noan-prop, add-all, add-prop}
 none : No backoffs are generated (Default mode)
 noan-all : For cases with no lexicon-based analyses, all possible backoff analyses are generated
 noan-prop : For cases with no lexicon-based analyses, only backoffs that are proper nouns are generated
 add-all : All possible backoff analyses are generated and added to existing lexicon analyses
 add-prop : Proper noun backoff analysese are generated and added to existing lexicon analyses

    
Example:
--------

$ perl ADAM.pl adam-v0.4.db 
loading database [../work/adam-v0.4/adam-v0.4.db] in [analysis] mode ...
#Running [ADAM]. Copyright (c) 2012 Columbia University.

mAHyktbwlw
diac:mAHayakotubuwluwu lex:katab-u_1 bw:mA/NEG_PART+Ha/FUT_PART+ya/IV3MP+kotub/IV+uw/IVSUFF_SUBJ:MP_MOOD:SJ+la/PREP+w/VSUFF_DO:3MS gloss:write pos:verb prc3:0 prc2:0 prc1:mAHa_negfut prc0:0 per:3 asp:i vox:a mod:i gen:m num:p stt:na cas:na enc0:l3ms_prepdobj rat:na source:lev_north stem:kotub stemcat:IV
diac:mAHayukotibuwluwu lex:>akotab_1 bw:mA/NEG_PART+Ha/FUT_PART+yu/IV3MP+kotib/IV+uw/IVSUFF_SUBJ:MP_MOOD:SJ+la/PREP+w/VSUFF_DO:3MS gloss:dictate;make_write pos:verb prc3:0 prc2:0 prc1:mAHa_negfut prc0:0 per:3 asp:i vox:a mod:i gen:m num:p stt:na cas:na enc0:l3ms_prepdobj rat:na source:lev_north stem:kotib stemcat:IV_yu

EhAlAsAs
diac:EahAl<isAs lex:>us~_1 bw:Ea/PREP+hAl/DET+<isAs/NOUN+ gloss:exponents pos:noun prc3:0 prc2:0 prc1:Ea_prep prc0:hAl_det per:na asp:na vox:na mod:na gen:m num:s stt:d cas:u enc0:0 rat:y source:spvar stem:<isAs stemcat:N
diac:EahAl<isAsi lex:>us~_1 bw:Ea/PREP+hAl/DET+<isAs/NOUN+i/CASE_DEF_GEN gloss:exponents pos:noun prc3:0 prc2:0 prc1:Ea_prep prc0:hAl_det per:na asp:na vox:na mod:na gen:m num:s stt:d cas:g enc0:0 rat:y source:spvar stem:<isAs stemcat:N
diac:EahAl>asAs lex:>asAs_1 bw:Ea/PREP+hAl/DET+>asAs/NOUN+ gloss:foundation;basis pos:noun prc3:0 prc2:0 prc1:Ea_prep prc0:hAl_det per:na asp:na vox:na mod:na gen:m num:s stt:d cas:u enc0:0 rat:y source:spvar stem:>asAs stemcat:NduAt
diac:EahAl>asAsi lex:>asAs_1 bw:Ea/PREP+hAl/DET+>asAs/NOUN+i/CASE_DEF_GEN gloss:foundation;basis pos:noun prc3:0 prc2:0 prc1:Ea_prep prc0:hAl_det per:na asp:na vox:na mod:na gen:m num:s stt:d cas:g enc0:0 rat:y source:spvar stem:>asAs stemcat:NduAt


--------------------------------------------------------------------------------

## KNOWN BUGS

The current release of ADAM was mainly tested on SAMA 3.1
databases. This is the version used in the paper mentioned above.  The
conversion for Aramorph is known to have some limitations. We plan on
addressing this in the future.



--------------------------------------------------------------------------------
Copyright 2012 (c) Columbia University. All Rights Reserved.
