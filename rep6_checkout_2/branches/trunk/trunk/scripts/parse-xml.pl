#!/usr/bin/perl 

#SVN Hook script which will parse the XML files
#and spell check the en_US contents.
#Created By:- Amit Kalia 09/05/2012.
 
use strict;

use XML::Simple;
use Data::Dumper;
use Text::Aspell;


my $speller = Text::Aspell->new;
die unless $speller;

$speller->set_option('lang','en_US');
$speller->set_option('sug-mode','fast');

my $string = undef;
my $textSearchString=undef;

my $locale = XMLin(\*STDIN);

#print Dumper($locale);

#The main logic to parse XML file and get the en_US contents.
#Tokenize the string and feed it into the spell checker.

if ( defined $locale->{property}->{localeQuestion} ) {
         #check for the Question.
         $string = $locale->{property}->{localeQuestion}->{item}->{en_US}->{class}->{property}->{questionText}->{value};
} elsif ( defined $locale->{property}->{localeDisplayText} ) {  
        #check for the Display Text.
		$string = $locale->{property}->{localeDisplayText}->{item}->{en_US}->{class}->{uniqueKeyMap}->{localeDisplayText};
} elsif ( defined $locale->{uniqueKeyMap}->{displaySetName} ) {
           #check for the Dislplay Set.
		   $textSearchString = $locale->{uniqueKeyMap}->{displaySetName};
	       #$string = $locale->{property}->{members}->{item}->{class}->{property}->{localeDisplaySetValue}->{item}->{en_US}->{class}->{uniqueKeyMap}->{localeDisplayValue};
	       foreach my $key  ( keys %{ $locale->{property}->{members}->{item} } ) {
	           if ( $key =~/$textSearchString/ig ) {
			       $string = $locale->{property}->{members}->{item}->{$key}->{class}->{property}->{localeDisplaySetValue}->{item}->{en_US}->{class}->{uniqueKeyMap}->{localeDisplayValue};
				   last;
			   }
	       }
} elsif ( defined $locale->{property}->{localeAnswer} ) {
       #Check for the Answers.
	   $string = $locale->{property}->{localeAnswer}->{item}->{en_US}->{class}->{property}->{answerText}->{value};
}elsif ( defined $locale->{property}->{mailTemplateContents}) {
       #Check for the Mail Template.
	   if ( $locale->{property}->{localeMailTemplate}->{item}->{class}->{uniqueKeyMap}->{localeName} =~ /en_US/i ) {
	       $string = $locale->{property}->{localeMailTemplate}->{item}->{class}->{property}->{description}->{value};
	   }
} else { 
    print "Nothing to Parse..Skipped parsing\n";
}

#print $string;
#my $value = $locale->{property}->{guuid}->{object};

#Clear of whitespaces..
chomp $string;

#The below logic will not parse HTML tags 
#in the en_US contents and will give speciel meaning to the word
#attached with the speciel characters.

if ( defined $string ) {
         my @words = split (/\s/,$string);
		 my $html = undef;
         foreach my $list ( @words ) {
		     $html = 0;
		     chomp($list);
		     if ( $html == 0 ) {
			       if ( $list !~/\W/ ) {
			           my $found = $speller->check( $list );
			           if ( $found == 0 ) {
                          print "Please check the word $list in the string $string\n";
				          exit 1;
				       }
			      }    
		   }
		   
         }
}

#If you have reached here .. then it means we are through with
#the spell check.

if ( defined $string ) {
    print "The Spell check completed\n";
} else {
    print "Nothing to do\n";
}
