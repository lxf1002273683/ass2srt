#!/bin/bash
mkdir new
find . -type f -name '*.*' -print0 | while IFS= read -r -d '' file; 
do
    fname=$(basename "$file")
    echo -e "\n\t -- $fname --"
    echo 0 > .tmp

    mkvmerge -i "$file" | grep 'subtitles (SubStationAlpha)' | egrep -o "[0-9]{1,2}" | while read subid
    do
	subname="$fname-$subid"
	subass="$subname.ass"
	tmpfname="$fname.tmpmkv"
        subsrt="$subname.srt"

	# extract one subtitile track and convert it to srt
	echo -en "\t\textracting ass ..."
        mkvextract tracks "$file" "$subid":"$subass" >/dev/null
	echo "done."
	echo -en "\t\tconverting ass to srt ..."
	ffmpeg -i "$subass" "$subsrt" -nostdin -loglevel quiet
	rm "$subass"
	echo -e "done."
        
	echo -en "\t\tadding srt to file..."
	clearsub=$(cat .tmp)
	if [ $clearsub -eq 0 ]; then
	    # create mkv copy with no sub at all
	    mkvmerge -o "$tmpfname" --no-subtitles "$fname" >/dev/null
	    mkvmerge -o "new/$fname" "$tmpfname" --track-name "$subid":"suboro" "$subsrt" >/dev/null
	    rm "$tmpfname"
	    echo 1 > .tmp
	else
            # create a last mkv from the previous one and add srt to it	
	    mkvmerge -o "new/$fname.x" "new/$fname" --track-name "$subid":"suboro" "$subsrt" >/dev/null
	    mv "new/$fname.x" "new/$fname"
	fi
	echo -e "done."
	rm "$subsrt"
    done
    
    clearsub=$(cat .tmp)
    rm .tmp
    if [ $clearsub -eq 0 ]; then
       echo -e "\n\t\tnothing to do."
    else
        mkdir -p bkp
        mv "$fname" bkp/
        mv "new/$fname" .
    fi
done
rm -rf new
