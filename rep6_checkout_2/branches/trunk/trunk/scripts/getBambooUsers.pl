#!/usr/bin/perl 


#Perl Program to fetch the list of users from Bamboo DB and subversion NIS DB.
#creted By:-Amit Kalia
#Date:-24/12/201e strict;


#Module loading for DB access.
use warnings;
use strict;

use DBI;
use HTML::HTMLDoc;
use Net::NIS;
use Mail::Sender;


#Global Variables 
######################################################################################################
my $db_hostname = "kdb-us-hsgtld03.us.kronos.com";
my $nis_server = "kap-us-peace.us.kronos.com";
my $port=1521;
my $group_name="Groups";
my $sid="bvtqa";
my $rootDir="/tmp";
my $sql_query="select users.name ,users.email,users.fullname,wm_concat(groups.groupname) as $group_name  from users, groups, local\_members where users.id=local\_members.userid and local\_members.groupid=groups.id group by (users.name,users.email,users.fullname) order by users.name asc";
my $to = "amit.kalia\@kronos.com";
my $from = "hsgreleng\@kronos.com";


#########################################################################################################

sub getDBHandle($){

   my $user=shift;
   my $dbh = DBI->connect( "dbi:Oracle:host=$db_hostname;sid=$sid;port=$port", "$user", "$user" )  or die "Can't connect to Oracle database: $DBI::errstr\n";
   $dbh->{warn}=0; 
   
   return $dbh; 

}

sub closeDBHandle($) {

    my $dbh = shift;
    $dbh->disconnect();

}

sub generateReport($$){

   my $html_content = shift;
   my $usr = shift;
   $usr = defined $usr ? $usr : "svn";
   my $htmldoc = new HTML::HTMLDoc();
   $htmldoc->set_html_content($html_content);
   $htmldoc->set_page_size("100x100cm");
   my $pdf = $htmldoc->generate_pdf();
   $pdf->to_file("${rootDir}/${usr}.pdf");
   return 0;
   

}


sub getBambooUsers() {

    my @db_users = ("BAMBOO_KAPUSBAMBOO1","BAMBOO_KAPUSBAMBOO2","BAMBOO_KAPUSBAMBOO3");
    my @db_users_copy = @db_users;
    my @file_names = map ($_ = "$rootDir/". $_."\.pdf", @db_users_copy);

    foreach my $usr (@db_users) {

      print "Getting the list of user for Schema $usr............\n";

      my $html_report = <<HTML;
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
      <html>
      <head>
      <body>
      <table><tr>
HTML

       $html_report = $html_report."<td valign=top align=\"center\"><b> User List for Schema $usr<p>";
       $html_report = $html_report.'<table width="20" cellspacing="1" cellpadding="2" align="left" border="0" width="100%"> <tr><th bgcolor="#FFFF00" width="25%">Name</th> <th bgcolor="#FFFF00" width="25%">Email</th><th bgcolor="#FFFF00" width="40%">Fullname<th bgcolor="#FFFF00" width="10%">Group</th></tr>';

        my $dbh = &getDBHandle($usr);
        my $sth = $dbh->prepare($sql_query);
        $sth->execute();


        while ( my ($name,$email,$fullname,$groups) = $sth->fetchrow_array() ) {

           $html_report = $html_report."<tr><td>$name</td><td>$email</td><td>$fullname</td><td>$groups</td>";
          
         }

         $html_report = $html_report."</table></td>";
         #&closeDBHandle($dbh);
         $html_report = $html_report.'</tr></table></body></html>';
         #my $htmldoc = new HTML::HTMLDoc();
         #$htmldoc->set_html_content($html_report);
         #$htmldoc->set_page_size("100x100cm");
         #my $pdf = $htmldoc->generate_pdf();
         #$pdf->to_file("$usr.pdf");
         &generateReport($html_report,$usr);


      }
      my $sub = "List of Bamboo users";
      my $msg = "Please find the list of Bamboo users";
      print"Sending Mails\n";
      &sendMailAndCleanup($to,$from,$sub,$msg,\@file_names); 
      print"Mail send successfully\n";
      unlink @file_names;
      print "Cleanup of the files done\n";
      return 0;

}

sub sendMailAndCleanup($$$$$){

     my $to = shift;
     my $from = shift;
     my $sub = shift;
     my $msg = shift;
     my $files = shift;
     my $server="smtp.kronos.com";

     print"Constructitng the mail object\n";

    eval {
    
     my $sender = new Mail::Sender{smtp => $server, from => $from};
     $sender->MailFile({to => $to,
                        subject => $sub,
                        msg => $msg,
                        file => $files});
   };
   if ($@) {
    print "Error sending the email: $@\n";
  } else {
    print "The mail was sent.\n";
  }
   return 0;

 }

sub getSvnUsers(){

    my $domain = Net::NIS::yp_get_default_domain( ); 
    my ($status, $info) = Net::NIS::yp_all($domain,"passswd.byname");
    print $info;  

}


##################################################################################################################################################################
#####################################################################MAIN##########################################################################################
####################################################################################################################################################################

print "Getting the list of Bamboo users\n";

&getBambooUsers();
#&getSvnUsers();

