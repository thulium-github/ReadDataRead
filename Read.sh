#!/bin/bash
# 2026.05.13 @ 19:34 PDT - done!

builtin declare -ia Data;
#Data=();
builtin declare -i Address=0x0;
builtin declare -i DataSize=0x0;

builtin declare -i i=0;
builtin declare -i j=0;

# 2007.10.29 S2:E4
function ReadDataRead()
{
	builtin shopt -u "extglob";
	
	builtin local SourceDirectory=${1};
	builtin local -i SourceTargetStart=${2};
	builtin local -i SourceTargetSize=${3};
	
	# far / ceil align to 8 bytes
	builtin local -i SourceTargetEnd=$(( ((SourceTargetStart + SourceTargetSize + 7) & -8) ));
	# floor align to 8 bytes
	SourceTargetStart=$(( SourceTargetStart & -8 ));
	
	builtin local FileSource;
	builtin local FileSpotterA;
	builtin local FileSpotterB;
	
	builtin exec {FileSource}< $SourceDirectory;
	builtin exec {FileSpotterA}< $SourceDirectory;
	builtin exec {FileSpotterB}< $SourceDirectory;
	
	#local -i SourceSize=0x0000000000000000;
	builtin local -i AddressSource=0x0000000000000000;
	builtin local -i AddressSource_Prev=0x0000000000000000;
	
	builtin local -i AddressSpotterA=0x0000000000000000;
	builtin local -i AddressSpotterB=0x0000000000000000;
	
	builtin local -i Value=0x0000000000000000;
	builtin local -i Count=0;
	builtin local -i Shift=0;
	
	builtin local -i ReadCount=0x40000000;
	
	builtin read -r < /proc/self/fdinfo/$FileSpotterB;
	AddressSpotterB=${REPLY#pos:};
	builtin read -r < /proc/self/fdinfo/$FileSpotterA;
	AddressSpotterA=${REPLY#pos:};
	builtin read -r < /proc/self/fdinfo/$FileSource;
	AddressSource=${REPLY#pos:};
	
	builtin local Status=0;
	
	# this part is for getting the size, but it can be slow and sometimes unnecessary
	#while [[ $Status -eq 0 ]]
	#do
		#IFS= LC_ALL=C read -r -N $ReadCount -d "" <& $FileSpotter;
		#Status=$?;
		#read -r < /proc/self/fdinfo/$FileSpotter;
		#echo ${REPLY#pos:};
	#done;
	
	#read -r < /proc/self/fdinfo/$FileSpotter;
	#SourceSize=${REPLY#pos:};
	
	#printf "Total Size: 0x%08X\n" $SourceSize;
	
	#if [[ $SourceTargetStart -ge $SourceSize ]]
	#then
		#echo out of bounds!;
		#return;
	#fi;
	
	#exec {FileSpotter}< $SourceDirectory;
	#read -r < /proc/self/fdinfo/$FileSpotter;
	#AddressSpotter=${REPLY#pos:};
	
	# effectively gets the most significant bit
	# this can be done with either bit-wise "or"s and shifts, or with ternary operations and bit-wise "and"s
	ReadCount=$(( (SourceTargetStart >> 1) ));
	(( ReadCount |= (ReadCount >> 1) ));
	(( ReadCount |= (ReadCount >> 2) ));
	(( ReadCount |= (ReadCount >> 4) ));
	(( ReadCount |= (ReadCount >> 8) ));
	(( ReadCount |= (ReadCount >> 16) ));
	(( ReadCount |= (ReadCount >> 32) ));
	# ..., et all (if youre in the far future and working with 128 bits or higher, continue up to the next powers of two)
	(( ReadCount = (ReadCount + 1) ));
	
	builtin local -i ReadCountOverall=0;
	builtin local -i ReadCountAdvanceA=0;
	builtin local -i ReadCountAdvanceB=0;
	
	# fast address jumper
	#for (( ReadCount = ReadCount; (ReadCount > 0) && (Status == 0); ))
	while [[ ($ReadCount -gt 0) && ($Status -eq 0) ]]
	do
		IFS= LC_ALL=C builtin read -r -N $(( ReadCountAdvanceA | ReadCount )) -d $'\x00' <& $FileSpotterA;
		builtin read -r < /proc/self/fdinfo/$FileSpotterA;
		AddressSpotterA=${REPLY#pos:};
		
		if [[ $AddressSpotterA -gt $SourceTargetStart ]]
		then
			Status=0;
			ReadCountAdvanceA=$ReadCountOverall;
			builtin exec {FileSpotterA}< $SourceDirectory;
		else
			IFS= LC_ALL=C builtin read -r -N $ReadCount -d $'\x00' <& $FileSource;
			Status=$?;
			IFS= LC_ALL=C builtin read -r -N $ReadCount -d $'\x00' <& $FileSpotterB;
			(( ReadCountOverall |= ReadCount ));
			ReadCountAdvanceA=0;
		fi;
		
		(( ReadCount >>= 1 ));
		
		if [[ $ReadCount -le 0 ]]
		then
			builtin break;
		fi;
		
		# one more time!!!!!!!
		
		IFS= LC_ALL=C builtin read -r -N $(( ReadCountAdvanceB | ReadCount )) -d $'\x00' <& $FileSpotterB;
		builtin read -r < /proc/self/fdinfo/$FileSpotterB;
		AddressSpotterB=${REPLY#pos:};
		
		if [[ $AddressSpotterB -gt $SourceTargetStart ]]
		then
			Status=0;
			ReadCountAdvanceB=$ReadCountOverall;
			builtin exec {FileSpotterB}< $SourceDirectory;
		else
			IFS= LC_ALL=C builtin read -r -N $ReadCount -d $'\x00' <& $FileSource;
			Status=$?;
			IFS= LC_ALL=C builtin read -r -N $ReadCount -d $'\x00' <& $FileSpotterA;
			(( ReadCountOverall |= ReadCount ));
			ReadCountAdvanceB=0;
		fi;
		
		(( ReadCount >>= 1 ));
	done;
	
	#echo New: $ReadCountOverall;
	
	builtin exec {FileSpotterB}<& -;
	builtin exec {FileSpotterA}<& -;
	
	if [[ $Status -ne 0 ]]
	then
		builtin exec {FileSource}<& -;
		builtin echo "out of bounds! (...or something!)";
		builtin return 1;
	fi;
	
	builtin exec {FileSpotterA}< $SourceDirectory;
	IFS= LC_ALL=C builtin read -r -N $ReadCountOverall -d $'\x00' <& $FileSpotterA;
	
	builtin read -r < /proc/self/fdinfo/$FileSource;
	AddressSource=${REPLY#pos:};
	Address=$((AddressSource & -8));
	
	# nobody cares
	#printf "AddressSpotterA: 0x%08X\n" $AddressSpotterA;
	#printf "AddressSpotterB: 0x%08X\n" $AddressSpotterB;
	#printf "AddressSource: 0x%08X\n" $AddressSource;
	
	builtin local -i Difference=0;
	builtin local WorkingString="";
	builtin local CharacterCurrent="";
	builtin local -ia DataTemp;
	builtin unset DataTemp[*];
	
	while [[ $Address -lt $SourceTargetEnd ]]
	do
		#Value=0x0000000000000000;
		Count=0;
		#Shift=0;
		AddressSource_Prev=$AddressSource;
		
		IFS= LC_ALL=C builtin read -r -N 1 -d $'\x00' <& $FileSource;
		Status=$?;
		builtin set -f -- "${REPLY}";
		WorkingString=${1};
		
		builtin read -r < /proc/self/fdinfo/$FileSource;
		AddressSource=${REPLY#pos:};
		
		Difference=$(( (AddressSource - AddressSource_Prev) ));
		
		# there is definitely a faster way to do this but i genuinely cant be arsed to do it rn
		
		# this is here 'cos we can't always guarantee that 1 byte was read...- damn u, 'nicode!
		while [[ -n $WorkingString ]]
		do
			# luckily, `printf` can extract a single byte from the front of a string *
			IFS= LC_ALL=C builtin printf -v CharacterCurrent "%.1s" $WorkingString;
			IFS= LC_ALL=C builtin printf -v Value "%i" "'$CharacterCurrent'";
			
			# don't use this one, it's slower
			#DataTemp+=($(IFS= LC_ALL=C printf "%i" "'$CharacterCurrent'"));
			
			DataTemp+=($Value);
			(( Count ++ ));
			
			# we can then remove the singular byte we read from the front of our working string *
			IFS= LC_ALL=C WorkingString=${WorkingString##$CharacterCurrent};
			
			# * note: this needs to be checked across different distributions / implementations!!!
		done;
		
		# cool trick for detecting if an extra zero was encountered, should the unicode decoder fail without resetting *
		# * this happens on termux, as of 2026.05.11 @ 12:45 PDT - unclear whether or not it's a bug, but it should still be accounted for
		IFS= LC_ALL=C builtin read -r -n $(( Difference - Count )) -d $'\x00' <& $FileSpotterA;
		builtin set -f -- "${#REPLY}";
		
		if [[ ${1} -gt 0 ]]
		then
			(( Count ++ ));
			#printf "got extra null @ 0x%08X - be sure to check!\n" $(( AddressSpotterA - 1 ));
		fi;
		
		builtin read -r < /proc/self/fdinfo/$FileSpotterA;
		AddressSpotterA=${REPLY#pos:};
		
		if [[ $AddressSpotterA -lt $AddressSource ]]
		then
			# it might be safe to jump ahead, assuming this only happens when a null character is encountered
			IFS= LC_ALL=C builtin read -r -N 1 -d $'\x00' <& $FileSpotterA;
			
			# we don't actually need to update it here- `AddressSpotterA` isn't used after this point in the loop
			#read -r < /proc/self/fdinfo/$FileSpotterA;
			#AddressSpotterA=${REPLY#pos:};
		fi;
		
		# aligns `Address`
		while [[ ($Address -lt $AddressSource) && ($Address -lt $SourceTargetEnd) ]]
		do
			Address=$(( ((Address + 8) & -8) ));
			#i=$(( Address >> 3 ));
			i=$(( ((Address - SourceTargetStart) >> 3) ));
			
			if [[ ($Address -ge $SourceTargetStart) && ($i -ge ${#Data[*]}) ]]
			then
				Data[i]=0x0000000000000000;
			fi;
		done;
		
		(( Address ++ ));
		
		if [[ $Address -gt $AddressSource ]]
		then
			Address=$AddressSource;
		fi;
		
		#printf "@ 0x%08X\n" $Address;
		
		# we either reached the end of the file, timed out, or whatever
		if [[ $Status -ne 0 ]]
		then
			builtin break;
		fi;
		
		# if we aren't reading within the address range, then move on
		if [[ $Address -le $SourceTargetStart ]]
		then
			builtin unset DataTemp[*];
			builtin continue;
		fi;
		
		(( Address -= Count ));
		
		#printf "0x%08X %i %i\n" $Address $Difference $Count;
		
		for (( j = 0; j < ${#DataTemp[*]}; j ++ ))
		do
			i=$(( ((Address - SourceTargetStart) >> 3) ));
			# you can change this to store as though it were reading in big-endian by xor'ing `Shift` with `0x38` / `56`
			Shift=$(( ((Address & 0x07) << 3) ));
			(( Data[i] |= (${DataTemp[j]} << Shift) ));
			
			(( Address ++ ));
		done;
		
		builtin unset DataTemp[*];
	done;
	
	builtin exec {FileSpotterA}<& -;
	builtin exec {FileSource}<& -;
	
	builtin return 0;
};

# example usage

ReadDataRead ${1} ${2} ${3};

for (( i = 0; i < ${#Data[*]}; i ++ ))
do
	printf "@0x%08X: 0x%016X\n" $(( (i << 3) + (${2} & -0x8) )) "${Data[$i]}";
done;

#printf "DataSize: %i\n" "$DataSize";