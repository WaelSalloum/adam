#!/bin/bash

scriptPath=`echo -n $0 | perl -pe 's/[^\/]+$//g'`
        #echo "scriptPath = $scriptPath"

usage ()
{
    echo "
USAGE
=-=-=
    $ bash $0 <XAMA-DB-Directory> <XAMA-Version> <ADAM-Version>
    
        <XAMA-DB-Directory>: is the directory that contains XAMA database that you have. 
                             For Example, for SAMA 3.1, it should be:
                                    SAMA-3.1/SAMA-3.1/lib/SAMA_DB/v3_1/
        
        <XAMA-Version>: takes one of these values:
                            SAMA3.1
                            BAMA2
                            ARAMORPH1.2.1
                            
        <ADAM-Version>: the version of ADAM you want to create.
"
}
if [[ $# != 3 ]]; then
    usage; exit 1
fi

xamaSourceDir=$1;shift
xamaVersion=$1;shift
adamVersion=$1;shift
# /export/projects/nlp/ALMOR/backup/tools/SAMA-3.1/SAMA-3.1/lib/SAMA_DB/v3_1/

xamaMap=$scriptPath/Form2Func-$xamaVersion.map
adamSadaMap=$scriptPath/adam-v$adamVersion.SADA.map
almor_db=$scriptPath/almor.db
adam_db=$scriptPath/../adam-v$adamVersion.db

if [[ "$xamaVersion" != "SAMA3.1" && "$xamaVersion" != "ARAMORPH1.2.1" && "$xamaVersion" != "BAMA2" ]]; then
    echo -e "\n>>>> ERROR:\n\n\t Unrecognized XAMA version: $xamaVersion.\n\t XAMA-Version parameter takes one of these values:\n\t\t SAMA3.1 \n\t\t BAMA2 \n\t\t ARAMORPH1.2.1\n\n"
    usage; exit 1
fi

if [[ ! -e $xamaMap ]]; then
    echo -e "\n>>>> ERROR:\n\n\t Cannot find XAMA Map:\n\t\t $xamaMap\n\n"
    usage; exit 1
fi
if [[ ! -e $xamaSourceDir ]]; then
    echo -e "\n>>>> ERROR:\n\n\t Cannot find XAMA Source Directory:\n\t\t $xamaSourceDir\n\n"
    usage; exit 1
fi


echo -e "
        =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        1. Convert XAMA DB to ALMOR DB:
        =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
"
perl -I $scriptPath/../ $scriptPath/XAMA-to-ALMOR3.pl $xamaMap $xamaSourceDir $almor_db

echo -e "
        =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        2. Convert ALMOR DB to ADAM DB:
        =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
"
perl $scriptPath/Gradual-ALMOR-SA2DA.pl $adamSadaMap $almor_db $adam_db 1 > $scriptPath/rulesAdded.w4

rm $almor_db $scriptPath/rulesAdded.w4

