#!/bin/bash
#find /mnt/dumps -mtime +30 -print
# ce scrip efface les vieux dumps de la base de données.
PURGEPATH=/mnt/dumps
cd $PURGEPATH
OLD_IFS="$IFS"
 
IFS=$(echo -en "\n\b")
for file in `ls -rt`
do
        IFS="$OLD_IFS"
        # en Ko
        espace_libre=`df -P "$PURGEPATH" | grep "$PURGEPATH" | head -n 1 | awk 'BEGIN{FS=" "} {print $4}'`
        # We want to keep 5 Go free
        if [ "$espace_libre" -lt 5000000 ] 
        then
            rm -rf -- "$file" && echo "Removed $file"
        else
            echo "Enough free space retrieved"
            break
        fi
       # etc
       # il faut faire attention, la valeur de l'IFS n'étant pas celle par défaut, certaines choses
       # ne fonctionneront pas si tu fais des choses compliquées dans ta boucle, tu seras probablement
       # obligé de restaurer/effacer la valeur d'IFS à chaque itération.
        sleep 1
        IFS=$(echo -en "\n\b")
done
echo "$espace_libre Ko free on $PURGEPATH"
 
IFS="$OLD_IFS"
 
#suite du script

