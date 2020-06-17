#!/usr/bin/perl

use File::Copy;
use File::Basename; # for basename() and dirname() and fileparse()
use strict;
use warnings;

###############################################################################
###############MAIN############################################################
###############################################################################

# defaults
my $libname_default = "KTMD Base Client";
my $csvdir_default = ".";
my $checkoutdb_default = ".";
my $errStr = undef;

my $csvdir;
my $csvfile;
my $exporteddb;
my $checkoutdb;
my $dbcheckdir;

# command line arguments
while (defined(@ARGV)){
    $a = shift;
    if ( $a eq "-c" ){
        ($csvfile, $csvdir) = fileparse($ARGV[0]);
        $csvdir =~ s-/$--; # remove trailing /
        $csvdir = "." unless defined($csvdir);
        shift;
    }
    elsif ( $a eq "-d" ){
        $checkoutdb = "$ARGV[0]";
        shift;
    }
    elsif ( $a eq "-e" ){
        $exporteddb = "$ARGV[0]";
        shift;
    }
    else{
        print " ** Warning: invalid/unused option: $a\n";
        die " ** Usage: $0 [-c CSV.file] [-d db.location] [-e exported.location]\n";
    }
}

#Count of Files.
my $totalfiles = 0;
my $errors = 0;

unless (defined($csvdir)){
    print ("Enter directory that contains the CSV files [default: $csvdir_default]\n > ");
    $csvdir = <STDIN>;
    chomp ($csvdir);
    $csvdir = $csvdir_default unless $csvdir;

    # list available selections for cut and paste
    my $dirtoget="$csvdir";
    opendir(IMD, $dirtoget) || die("Cannot open directory");
    my @theCSVFiles= readdir(IMD);
    closedir(IMD);

    print ("The list of CSV files are .......\n");
    foreach my $list (@theCSVFiles) {
        print $list . "\n";
    }

    #my $cmd = "/bin/ls -CF $csvdir/*.csv";
    #print "\n + $cmd\n";
    #system($cmd);
}


unless (defined($csvfile)){
    print ("\nEnter CSV file name\n > ");
    $csvfile = <STDIN>;
    chomp($csvfile);
}
die " ** Error: csv file name is required.\n" unless $csvfile;

if ( -f "$csvdir/$csvfile" ) {
    print " + located file: $csvdir/$csvfile\n";
}
else {
    die " ** Error: CSV file was not found: $csvdir/$csvfile\n";
}

unless (defined($exporteddb)){
    print ("\nEnter the directory of exported translated db files\n > ");
    $exporteddb = <STDIN>;
    chomp ($exporteddb);
}
die " ** Error: directory name is required.\n" unless $exporteddb;

if ( -d "$exporteddb/clientData" ){
    $dbcheckdir = "clientData";
}
elsif ( -d "$exporteddb/libraries" ){
    $dbcheckdir = "libraries";
}
else{
    die " ** Error: directory not found: $exporteddb/clientData or $exporteddb/libraries\n";
}
print " + located directory: $exporteddb/$dbcheckdir\n";

my $libname;
if ( $csvfile =~ /MailTemplate/i or $csvfile =~ /Question/i ) {
    print ("\nEnter the library Modified [default: $libname_default]\n > ");
    $libname = <STDIN>;
    chomp ( $libname);
    $libname = $libname_default unless $libname;
}

unless (defined($checkoutdb)){
    print ("\nEnter the directory of svn checked-out db files [default: $checkoutdb_default]\n > ");
    $checkoutdb = <STDIN>;
    chomp($checkoutdb);
}
$checkoutdb = $checkoutdb_default unless $checkoutdb;
if ( -d "$checkoutdb/$dbcheckdir" ){
    print " + located directory: $checkoutdb/$dbcheckdir\n";
}
else{
    die " ** Error: directory not found: $checkoutdb/$dbcheckdir\n";
}


print "
        CSV file: $csvdir/$csvfile
        checked out DB:  $checkoutdb    (contains $checkoutdb/$dbcheckdir)
        exported dir:  $exporteddb    (contains $exporteddb/$dbcheckdir)
\n";

print "Press 'y' to accept these paramters and execute the copy: ";
my $answ = <STDIN>;
chomp($answ);
die " ** Exiting...\n" unless $answ =~ /[Yy]/;

#Handling DisplaySet
if ( $csvfile =~ /DisplaySetValues/i  ) {

    print ("The CSV file has the Display Set Values \n");
    open (DSTEXT,"<$csvdir/$csvfile") or die " ** Error: can not open $csvdir/$csvfile: $!\n";
    while ( <DSTEXT>) {
        next if /DisplaySetValues/ and ( $totalfiles == 0 ); # skip header
        next if /^Library,Qualifier,Display/; # skip header
        my @fileList = split(",",$_);
        chomp ($fileList[0]);
        chomp ($fileList[1]);
        chomp ($fileList[2]);
        $totalfiles =$totalfiles + 1;
        $fileList[2] =~s/\./-/g;
        $fileList[2] =~s/\s+/-/g;
        if ( $fileList[1] =~ /N\/A/ ) {
            $fileList[1] = 'null';
        }

        my $fileName = "$fileList[2]_$fileList[0]_$fileList[1].xml";

        if ( -f "$exporteddb/libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName") {
            print " + copy libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName\n";
            copy ("$exporteddb/libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName",
                  "$checkoutdb/libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName") or die "Copy failed: $!";
            #print ("The File $fileName is copied \n");
        }
        else {
            #printf (" ** Error: $fileName does not exist....Please check\n");
            print " ** Error: file not found: $exporteddb/libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName\n";
	    $errStr = $errStr. " ** Error: file not found: $exporteddb/libraries/$fileList[0]/DBAsset/DisplaySet Definition/$fileName\n";
            $errors++;
        }
    }
   close(DSTEXT);
}
#Handling DisplayText
elsif ( $csvfile =~ /DisplayText/i  ) {

    print ("The CSV file has the Display Text values\n");
    open (DTEXT,"<$csvdir/$csvfile") or die " ** Error: can not open $csvdir/$csvfile: $!\n";
    while ( <DTEXT>) {
    next if /DisplayText/ and  ( $totalfiles == 0 ); # skip header
    next if /^Library,Qualifier,Display/; # skip header
    my @fileList = split(",",$_);
        chomp ($fileList[0]);
        chomp ($fileList[1]);
        chomp ($fileList[2]);
        $totalfiles = $totalfiles + 1;
        $fileList[2] =~s/\./-/g;
        $fileList[2] =~s/\s+/-/g;
        if ( $fileList[1] =~ /N\/A/ ) {
            $fileList[1]= 'null';
        }
        my $fileName = "$fileList[2]_$fileList[0]_$fileList[1].xml";

        if ( -f "$exporteddb/libraries/$fileList[0]/DBAsset/DisplayText/$fileName") {
            print " + copy libraries/$fileList[0]/DBAsset/DisplayText/$fileName\n";
            copy ("$exporteddb/libraries/$fileList[0]/DBAsset/DisplayText/$fileName",
                  "$checkoutdb/libraries/$fileList[0]/DBAsset/DisplayText/$fileName") or die "Copy failed: $!";
            #print ("The File $fileName is copied \n");
        }
        else {
            #printf (" ** Error: $fileName does not exist....Please check\n");
            print " ** Error: file not found: $exporteddb/libraries/$fileList[0]/DBAsset/DisplayText/$fileName\n";
	        $errStr = $errStr. " ** Error: file not found: $exporteddb/libraries/$fileList[0]/DBAsset/DisplayText/$fileName\n";
            $errors++;
        }
    }
   close(DTEXT);
}
elsif ( $csvfile =~ /MailTemplate/i ) {

    print ("The CSV file has the mail template\n");
    open (MAILTEMPLATE,"<$csvdir/$csvfile") or die " ** Error: can not open $csvdir/$csvfile: $!\n";
    while (<MAILTEMPLATE>) {
        next if /MailTemplate/ and  ( $totalfiles == 0 ); # skip header
        next if /^Client,Global Identifier/; # skip header
        my @fileList = split(",",$_);
        chomp ($fileList[0]);
        $totalfiles =$totalfiles + 1;
        $fileList[0] =~s/\s+/-/g;

        if (  defined $fileList[1] ) {
            chomp ($fileList[1]);
            my $mailFileName = "${fileList[0]}_${fileList[1]}";

            if ( -f "$exporteddb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml") {

                print (" + cp $exporteddb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml $checkoutdb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml\n");
                print " + copy clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml\n";
                copy ("$exporteddb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml",
                      "$checkoutdb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml") or die "Copy failed: $!";
                #print ("The File ${mailFileName}.xml is copied \n");
            }
            else {
                #printf (" ** Error: $mailFileName does not exist..Please check\n");
                print " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml\n";
		        $errStr = $errStr. " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/MailTemplate/${mailFileName}.xml\n";
                $errors++;
            }
        }
    }
     close(MAILTEMPLATE);
}
elsif ( $csvfile =~ /Question/i ) {

    open (FH,"<$csvdir/$csvfile") or die " ** Error: can not open $csvdir/$csvfile: $!\n";
    #C:\test\db\clientData\KTMD Base Client\DBObject
    while ( <FH> ) {

        my @fileList = ();
        #print $_;
        next if /(.)*(Question)/ and $_ !~ /${libname}|ANSWER/i ; # skip header
        next if /^Client,Global Identifier,Category/; # skip header

        @fileList = split(",",$_);

        chomp ($fileList[0]);
        chomp ($fileList[1]);
        $totalfiles = $totalfiles + 1;

        #print ("The File Type or Library is ".$fileList[0]."\n");

        # this file has a '#' in place of a '-' in the questions file
        #db/clientData/KTMD\ Base\ Client/DBObject/Question/-TermsAndCondSalaried-eula.xml
        my $dbfile = $fileList[1];
        $dbfile =~ s/\#/-/g;
        print ("The FileName is $dbfile\n");

        if ( $fileList[0] =~ /ANSWER/i ) {

            if ( -f "$exporteddb/clientData/$libname/DBObject/Answer/$dbfile.xml"){
                #We are dealing with Answer
                #print ("Copying the Answer file $dbfile.xml\n");
                print " + copy clientData/$libname/DBObject/Answer/$dbfile.xml\n";
                copy ("$exporteddb/clientData/$libname/DBObject/Answer/$dbfile.xml" ,"$checkoutdb/clientData/$libname/DBObject/Answer/$dbfile.xml") or die "Copy failed: $!";
                #print ("Copying of Answer file is successful");
            }
            else {
                #printf ("$dbfile does not exist..Please check\n");
                print " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/Answer/$dbfile.xml\n";
		$errStr = $errStr. " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/Answer/$dbfile.xml\n";
                $errors++;
            }
        }
        elsif ( $fileList[0] =~ /$libname/i ) {
            #We are dealing with Questions.
            if ( -f "$exporteddb/clientData/$libname/DBObject/Question/$dbfile.xml" ){
                #print ("Copying the Question file $dbfile.xml\n");
                print " + copy clientData/$libname/DBObject/Question/$dbfile.xml\n";
                copy ("$exporteddb/clientData/$libname/DBObject/Question/$dbfile.xml",
                      "$checkoutdb/clientData/$libname/DBObject/Question/$dbfile.xml") or die "Copy failed: $!";
                #print ("Copying of Question file is successful");
            }
            else {
                #printf (" ** Error: $dbfile does not exist..Please check\n");
                print " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/Question/$dbfile.xml\n";
		$errStr = $errStr. " ** Error: file not found: $exporteddb/clientData/$libname/DBObject/Question/$dbfile.xml\n";
                $errors++;
            }
        }
        else{
            print " ** Error: unknown fileList: $fileList[0]\n";
        }
    }
    close(FH);
}
else{
    print ("\n ** Error: CSV file name was not recognised: $csvfile !!!\n");
}

print "\n========================================================\n";
print ("The Total number of files copied = $totalfiles\n");
if ( "$errors" > 0 ) {
    print "The error list is \n";
    print "$errStr";
    print " ** Errors detected = $errors\n";
}

print "
 *** Please manually inspect these special files before checkin.

svn diff libraries/HCOM/DBAsset/DisplayText/Object-PersonContact-ssn_HCOM_null.xml
svn diff libraries/admin/DBAsset/DisplayText/Object-ExpImpLog-exportDateTime_admin_null.xml
svn diff libraries/admin/DBAsset/DisplayText/Object-ExpImpLog-exportStatus_admin_null.xml
svn diff libraries/admin/DBAsset/DisplayText/Object-ExpImpLog-importStatus_admin_null.xml
svn diff libraries/HourlyCanada/DBAsset/DisplayText/Object-PersonContact-ssn_HourlyCanada_null.xml
";

###################################################
# Answers to question in this script
#
#
#  perl ./ImportQuestionsAnswer.pl
#
#  Enter directory that contains the CSV files:
#  > .
#  Enter CSV Questions file name
#  > SpanishErrorsGlobalQuestionsPart1CORRECTED.csv
#  Enter the directory of exported translated db files
#  > db.re293
#  Enter the library Modified [default: KTMD Base Client]
#  >
#  Enter the checkout area that contains 'db'
#  > .
#
# also: SpanishErrorsGlobalQuestionsPart2CORRECTED.csv
