#David Wilson
#1/27/05
#Builder.pl

#This perl script is designed to find all .source and files in the 
#current directory, call the make sure to build, and then encrypt them
#You will need to make sure the FWEncryptor.exe file is in the current
#directory as well, and that the path to GCC is in your environment path.

#You can specify diffent makefiles in the same folder by naming each makefile uniquely.


#The line below points to your perl installation. 
#Tf your perl executable is in a different place, you will need to edit
#this.
#!c:/perl/bin/perl.exe

#first, let's check to make sure the apps we need are here
if(!-e "FWEncryptor.exe")
{
	print "ERROR: Firmware Encryptor (FWEncryptor.exe) not found.\nMake sure this executable is in the same folder.\b\n";
	print "\n";
	print "Build process halted due to errors.\n";
	return;
}

#now make them.
print "Starting make....\n";
	
qx(make.exe all);

#now time to encrypt them
#glob all the .hex files
@HexList=<*.hex>;
$Counter=0;

#now go through them one by one.
while($HexList[$Counter] ne "")
{
	print "Starting Encryption of ";
	print $HexList[$Counter];
	print "\n";
	
	$OriginalFileName=$HexList[$Counter];
	#split the file name base from the extension
	@the_file_name = split(/.hex/, $OriginalFileName);

	#use the file name base as the file name used with the .efw
	$EncyptedFileName=sprintf("%s.efw", $the_file_name[0]);
	
	#now call the encryptor with correct $BoardType
	#0 is Chaos
	#1 is Entropy
	#2 is Pandora
	#3 is Loki
	#4 is Spyder
	#5 is NME
	#6 is Xonik
	#7 is AKA2
	#8 is Alias
	#9 is Freestyle
	
	#get the first three characters from the file name
	my $FileTitle = substr($OriginalFileName, 0, 3);

	if($FileTitle eq "cha")
	{
		$BoardType=0;
		print "Setting Firmware for Chaos...\n";
	}
	if($FileTitle eq "ent")
	{
		$BoardType=1;
		print "Setting Firmware for Entropy...\n";
	}
	if($FileTitle eq "pan")
	{
		$BoardType=2;
		print "Setting Firmware for Pandora...\n";
	}
	if($FileTitle eq "lok")
	{
		$BoardType=3;
		print "Setting Firmware for Loki...\n";
	}
	if($FileTitle eq "spy")
	{
		$BoardType=4;
		print "Setting Firmware for Spyder...\n";
	}
	if($FileTitle eq "nme")
	{
		$BoardType=5;
		print "Setting Firmware for NME...\n";
	}
	if($FileTitle eq "xon")
	{
		$BoardType=6;
		print "Setting Firmware for Xonik...\n";	
	}
	if($FileTitle eq "ak2")
	{
		$BoardType=7;
		print "Setting Firmware for AKA2...\n";
	}
	if($FileTitle eq "ali")
	{
		$BoardType=8;
		print "Setting Firmware for Alias...\n";
	}
	if($FileTitle eq "free")
	{
		$BoardType=9;
		print "Setting Firmware for Freestyle...\n";
	}
	
	if($FileTitle eq "matrix")
	{
		$BoardType=11;
		print "Setting Firmware for Matrix...\n";
	}
	
	qx(FWEncryptor.exe $OriginalFileName $EncyptedFileName $BoardType);
	
	$Counter=$Counter+1;
}

print "Cleaning up unneeded files...\n";
qx(del *.hex);
qx(del *.lst);
qx(del *.eep);
qx(del *.elf);
qx(del *.lss);
qx(del *.map);
qx(del *.sym);
qx(del *.o);

print "All Done!";






