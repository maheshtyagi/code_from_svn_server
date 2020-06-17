#!/usr/bin/perl 

#Author :-Amit Kalia
#Date:-03/07/2012

#Loading modules for the utility.
use strict;
use HTML::TagParser;
use Getopt::Std;
use File::Copy;


#Global Variables.
my  ( $testListProperties,$seleniumFailListFile,$help );
our ($opt_t,$opt_s,$opt_h);

getopts('t:s:h');

$testListProperties=$opt_t;
$seleniumFailListFile=$opt_s;
$help=$opt_h;


#Getting the list of Failed test from from 
#the report folder under functional test 
#of the build area.

sub getFailTest($) {
    
    my $file=shift;
	
    my $html = HTML::TagParser->new($file);
    my @list = $html->getElementsByTagName( "a" );
    my $textJava = "";

    foreach my $elem ( @list ) {
        my $tagname = $elem->tagName;
        my $attr = $elem->attributes;
        my $text = $elem->innerText;
        if ($attr->{href}=~/\.html$/i ) {   
            #print "<$tagname";
            #    foreach my $key ( sort keys %$attr ) {
            #    print " $key=\"$attr->{$key}\"";
            #}
            if ( $text eq "" ) {
                print " />\n";
            } else {
                print "$text\n";
                $textJava=$textJava.",$text";
            }
       }
   }
   
   #Replace the starting comma with null.
   $textJava=~s/^,//;
   return $textJava;

}#End of functions.


#The subroutine to update the 
#testlist.properties files for
#re-run of the test cases only for 
#failures. 

sub updateTestList($$) {
   
   my $test=shift;
   my $file=shift;
   my $tempFile = ${file}."tmp";
   
   my $updatedTestList='regressionTests='."$test";
   print "The updated lists $updatedTestList\n"; 
   open (TFH,">$tempFile") or die"Cannot open the file $tempFile  for writing $! \n";
   open (FH,"<$file") or die "Cannot open the file $file for reading $! \n";
   while (<FH>) {
      if ($_ =~/regressionTests=/) {
              print "Found the string ..replacing..";
	      $_=~s/regressionTests\=.*/$updatedTestList/gi;
	  }
      print TFH $_; 
   }
   close(FH); 
   close(TFH);
   copy ( $tempFile,$file) or die "Cannot copy:$!\n";
   unlink $tempFile;
   
}#End of function.

######################################################################################################################################
###########################################################MAIN#######################################################################
######################################################################################################################################


if ( $help ) {
	print "$0 -t<testListFile> -s<seleniumErrorFile> -h";
        exit 0;
} else {
        if (  -e $seleniumFailListFile && -e $testListProperties ){ 
             my $list =  &getFailTest($seleniumFailListFile);
	     &updateTestList($list,$testListProperties);
       } else {
              print "The main configuration file does not exists..Please check either $testListProperties or  $seleniumFailListFile\n";
	      exit 1;
       }
}

exit 0;
