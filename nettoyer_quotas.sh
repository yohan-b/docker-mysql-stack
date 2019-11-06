#!/bin/bash
#find /mnt/dumps -mtime +30 -print
# This script removes old database dumps.
PURGEPATH=/mnt/dumps
cd $PURGEPATH
OLD_IFS="$IFS"
 
# We want to keep 5 Go free (unit: kB)
minfree=5000000
# We want to keep 30 dumps max (min is 2)
maxkeep=30

count=$(ls | wc -l)
count_removed=0

IFS=$(echo -en "\n\b")
for file in `ls -rt`
do
        IFS="$OLD_IFS"
        # unit: KB
        free_space=`df -P "$PURGEPATH" | grep "$PURGEPATH" | head -n 1 | awk 'BEGIN{FS=" "} {print $4}'`
        if [ $(( $count - $count_removed )) -gt $(( $maxkeep - 2 )) ]
        then
            rm -rf -- "$file" && echo "Removed $file"
            count_removed=$(( $count_removed + 1 ))
        elif [ "$free_space" -lt $minfree ] 
        then
            rm -rf -- "$file" && echo "Removed $file"
            count_removed=$(( $count_removed + 1 ))
        else
            echo "Enough free space retrieved"
            break
        fi
        sleep 1
        IFS=$(echo -en "\n\b")
done
echo "$free_space KB free on $PURGEPATH"
 
IFS="$OLD_IFS"
