#!/bin/bash

if [ ! "$1" ]
then
	echo "Please specify filename."
	exit 1
fi

if [ ! -f "$1" ]
then
	echo "Error: file does not exist"
	exit 1
fi


# extract the filename without extension
filename=`basename "$1" | sed 's/\.\([^\/\.]*$\)//'`


# check lower limit param
if [ $2 ]
then
	lower_limit="$2"
else
	lower_limit=-3
fi

# check upper limit param
if [ $3 ]
then
	upper_limit="$3"
else
	upper_limit=3
fi

# make sure lower limit < upper limit
if [ $upper_limit -le $lower_limit ]
then
	echo "Error: upper limit is smaller than lower limit."
	exit 1
fi


echo "Processing from $lower_limit to $upper_limit."


file_list=""

# should we use -3 exposure from RAW
if [ $lower_limit -lt -2 ]
then
	if [ ! -f "${filename}_N3.tiff" ]
	then
		ufraw-batch  --wb=camera --exposure=-3 --out-type=tiff16  --output=${filename}_N3.tiff "$1"
	fi
	file_list="${filename}_N3.tiff"
fi

# should we use -2 exposure from RAW
if [ $lower_limit -le -2 -a $upper_limit -ge -2 ]
then
	if [ ! -f ${filename}_N2.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=-2 --out-type=tiff16  --output=${filename}_N2.tiff "$1"
	fi
	file_list="${file_list} ${filename}_N2.tiff"
fi


# should we use -1 exposure from RAW
if [ $lower_limit -le -1 -a $upper_limit -ge -1 ]
then
	if [ ! -f ${filename}_N1.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=-1 --out-type=tiff16  --output=${filename}_N1.tiff "$1"
	fi
	file_list="${file_list} ${filename}_N1.tiff"
fi

# should we use 0 exposure from RAW
if [ $lower_limit -le 0 -a $upper_limit -ge 0 ]
then
	if [ ! -f ${filename}_0.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=0 --out-type=tiff16  --output=${filename}_0.tiff "$1"
	fi
	file_list="${file_list} ${filename}_0.tiff"
fi

# should we use +1 exposure from RAW
if [ $lower_limit -le 1 -a $upper_limit -ge 1 ]
then
	if [ ! -f ${filename}_P1.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=1 --out-type=tiff16  --output=${filename}_P1.tiff "$1"
	fi
	file_list="${file_list} ${filename}_P1.tiff"
fi

# should we use +2 exposure from RAW
if [ $lower_limit -le 2 -a $upper_limit -ge 2 ]
then
	if [ ! -f ${filename}_P2.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=2 --out-type=tiff16  --output=${filename}_P2.tiff "$1"
	fi
	file_list="${file_list} ${filename}_P2.tiff"
fi

# should we use +3 exposure from RAW
if [ $upper_limit -gt 2 ]
then
	if [ ! -f ${filename}_P3.tiff ]
	then
		ufraw-batch  --wb=camera --exposure=3 --out-type=tiff16  --output=${filename}_P3.tiff "$1"
	fi
	file_list="${file_list} ${filename}_P3.tiff"
fi

# run enfuse with default parameter, edit this line for more advance enfuse options
enfuse ${file_list} -o ${filename}_enfused.tiff -l 29 $4 $5 $6 $7 $8 $9

# uncomment the next line to auto clean up, else just leave the temp files to experiment more
rm ${file_list}

echo "Done: final output file is ${filename}_enfused.tiff"
exit 0
