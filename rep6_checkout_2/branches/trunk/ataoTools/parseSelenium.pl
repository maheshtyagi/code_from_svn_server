#!/usr/bin/perl 

#Author :-Amit Kalia
#Date:-03/07/2012

#Loading modules for the utility.
use strict;
use HTML::TagParser;
use Getopt::Std;
use File::Copy;


#Global Variables.
my  ( $testListProperties,$seleniumFailListFolder,$help );
our ($opt_t,$opt_s,$opt_h);

getopts('t:s:h');

$testListProperties=$opt_t;
$seleniumFailListFolder=$opt_s;
$help=$opt_h;


#Getting the list of Failed test from from 
#the report folder under functional test 
#of the build area.

sub getFailAndErrorsTest($) {

    my $folder = shift;
    my $file_fails = "$folder/alltests-fails.html";
    my $file_errors = "$folder/alltests-errors.html";
    my $textJava = "";
    my $textJava = &parseHtmlFile($file_fails,$textJava);
    my $textJava = &parseHtmlFile($file_errors,$textJava);
   
   #Replace the starting comma with null.
   if ( $textJava == "" ) {
        print "No Failed test case found so exiting..\n";
        exit 1;
   }

   $textJava=~s/^,//;
   return $textJava;

}#End of functions.


sub parseHtmlFile ($$) {
    
     my $file = shift;
     my $textJava = shift;

     my $html = HTML::TagParser->new($file);
     my @list = $html->getElementsByTagName( "a" );
     foreach my $elem ( @list ) {
         my $tagname = $elem->tagName;
         my $attr = $elem->attributes;
         my $text = $elem->innerText;
         if ($attr->{href}=~/\.html$/i ) {
             if ( $text eq "" ) {
               print " />\n";
             } else {
               print "$text\n";
               $textJava=$textJava.",$text";
            }
        }

   }

   return $textJava; 

}


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
	print "$0 -t<testListFile> -s<seleniumErrorFolder> -h";
        exit 0;
} else {
        if (  -d $seleniumFailListFolder && -e $testListProperties ){ 
             my $list =  &getFailAndErrorsTest($seleniumFailListFolder);
	     &updateTestList($list,$testListProperties);
       } else {
              print "The main configuration file does not exists..Please check either $testListProperties or folder $seleniumFailListFolder exsists\n";
	      exit 1;
       }
}

exit 0;
