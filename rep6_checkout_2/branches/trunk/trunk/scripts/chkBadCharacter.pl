#!/usr/bin/perl

use strict;
use warnings;

use File::Basename; # for basename() and dirname() and fileparse()

#Function to print usage()
sub usage() {

    print "Please specify the full path to the CSV file name\n";
    print  "perl chkBadCharacter.pl <path to the CSV file>";
    die ("Arguments not specfied\n");

}

###############################################################################
######################MAIN#####################################################
###############################################################################

my $qfile = undef;

if (scalar (@ARGV) != 0 ) {
    $qfile = shift(@ARGV);
} else {
    usage();
}
my $qdir;
my $qfileName;

my $line = 0;
my $errors = 0;

if ( -f "$qfile" ){
    $qdir = dirname($qfile);
    $qfileName = basename($qfile);
}
elsif ( "$qfile" ne "" ){
    die " ** Error: file not found: $qfile\n";
}


print "
        CSV file: $qdir/$qfileName

\n";

#Handling DisplaySet
if ( $qfileName =~ /DisplaySetValues/i  ) {

    print "The CSV file has the Display Set Values \n";
    open (DSTEXT,"<$qdir/$qfileName") or die " ** Error: can not open $qdir/$qfileName: $!\n";
    while ( <DSTEXT>) {
        $line++;
        next if /,,,,,$/; # skip header
        next if /^Library,Qualifier,DisplaySetValues/; # skip header
        my @fileList = split(",",$_);
        $fileList[4] = '' unless defined($fileList[4]); # avoid strict warning
        chomp ($fileList[4]);
        unless ( $fileList[4] =~/^[a-zA-Z0-9,\s\@\=\;<\!>\!\%\~\&\#\$\[\]\.\-\_\d\( \)\\\/\:\?\*]+$/g  ) {
            #print (" ** BAD character found in \"$fileList[4]\" at line $line\n\n");
            print " ** BAD character found on line: $line\n$fileList[4]\n\n";
            $errors++;
        }
   }

   close(DSTEXT);
}
#Handling DisplayText
elsif ( $qfileName =~ /DisplayText/i  ) {

    print "The CSV file has the Display Text values\n";
    open (DTEXT,"<$qdir/$qfileName") or die " ** Error: can not open $qdir/$qfileName: $!\n";
    while ( <DTEXT>) {
        $line++;
        next if /,,,,,$/ ; # skip header
        next if /^Library,Qualifier,DisplayText/; # skip header
        my @fileList = split(",",$_);
        $fileList[3] = '' unless defined($fileList[3]); # avoid strict warning
        chomp ($fileList[3]);
        unless ( $fileList[3] =~/^[a-zA-Z0-9,\s\@\=\'\;\<\!\>\%\~\&\#\$\\[ \]\.\-\_\ \d!\( \)\\\/\:\?\*]+$/g ) {
            #print (" ** BAD character  found in \"$fileList[3]\" at line $line\n\n");
            print "\n\n** BAD character found on line: $line\n$fileList[3]";
            while ($fileList[3] =~ m/[^a-zA-Z0-9,\s\@\=\'\;\<\!\>\%\~\&\#\$\\[ \]\.\-\_\ \d!\( \)\\\/\:\?\*]+/g) {
			  print "Found '$&' at position " . (pos($fileList[3])+1) . "\n";
			}
	    $errors++;
        }
    }
   close(DTEXT);
}
elsif ( $qfileName =~ /MailTemplate/i ) {

    print "The CSV file has the mail template\n";
    open (MAILTEMPLATE,"<$qdir/$qfileName") or die " ** Error: can not open $qdir/$qfileName: $!\n";
    while (<MAILTEMPLATE>) {
        $line++;
        next if /,,,,,$/ ; # skip header
        next if /^Client,Global Identifier,SequenceName/ ; # skip header

        my @fileList = split(",",$_);
        $fileList[3] = '' unless defined($fileList[3]); # avoid strict warning
        chomp ($fileList[3]);
        unless ( $fileList[3] =~/^[a-zA-Z0-9,\@\;\=\<\ \!\>\s\%\~\#\&\$\[\]\.\-\_\ \d\( \)\\\/\:\?\*]+$/g ) {

            #print (" ** BAD character found in \"$fileList[3]\" at line $line\n\n");
            print " ** BAD character found on line: $line\n$fileList[3]\n\n";
            $errors++;
	}
    }
     close(MAILTEMPLATE);
}
elsif ( $qfileName =~ /QuestionResponse/i ) {

    open (FH,"<$qdir/$qfileName") or die " ** Error: can not open $qdir/$qfileName: $!\n";
    #C:\test\db\clientData\KTMD Base Client\DBObject
    while ( <FH> ) {
        $line++;
        my @fileList = ();
        #print $_;
        next if /,,,,,$/ ; # skip header
        next if /^Client,Global Identifier,Category/ ; # skip header

        @fileList = split(",",$_);
        $fileList[3] = '' unless defined($fileList[3]); # avoid strict warning
        $fileList[9] = '' unless defined($fileList[9]); # avoid strict warning
        chomp ($fileList[9]);
        unless ( $fileList[9] =~/^[a-zA-Z0-9,\@\s\=\;\!\<\>\% \~\&\$\[\]\.\-\_\ \d\( \)\\\/\:\?\*]+$/g   ) {
	    #print (" ** BAD character found in \"$fileList[9]\" at line $line\n\n");
            print " ** BAD character found on line: $line\n$fileList[3]\n\n";
            $errors++;
        }
    }
    close(FH);
}
else {
    print " ** Error: CSV file was not recognised: $qfileName\n";
}

if ( $errors == 0 ) {
    print " ** No Errors reported\n";

}
else {
    print " ** Total errors: $errors.\n";
    print "Please check the errors with BAD Character\n";
}

