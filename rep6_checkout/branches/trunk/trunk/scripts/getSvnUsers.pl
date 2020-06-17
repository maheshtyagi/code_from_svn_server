#!/usr/bin/perl 


#Perl Program to fetch the list of users from Bamboo DB and subversion NIS DB.
#creted By:-Amit Kalia
#Date:-24/12/201e strict;


#Module loading for DB access.
use warnings;
use strict;

#use DBI;
use HTML::HTMLDoc;
use Mail::Sender;


#Global Variables 
######################################################################################################
#my $db_hostname = "kdb-us-hsgtld03.us.kronos.com";
#my $nis_server = "kap-us-peace.us.kronos.com";
#my $port=1521;
#my $group_name="Groups";
#my $sid="bvtqa";
my $rootDir="/tmp";
my $ypcat ="/usr/bin/ypcat";
my $map = "passwd.byname";
#my $sql_query="select users.name ,users.email,users.fullname,wm_concat(groups.groupname) as $group_name  from users, groups, local\_members where users.id=local\_members.userid and local\_members.groupid=groups.id group by (users.name,users.email,users.fullname) order by users.name asc";
my $to = "amit.kalia\@kronos.com";
my $from = "hsgreleng\@kronos.com";


#########################################################################################################


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

      my @svn_users = ("SVN");
      my @svn_users_copy = @svn_users;
      my @file_names = map ($_ = "$rootDir/". $_."\.pdf", @svn_users_copy); 

      my @user = undef;
      my $maps = undef;
      open(YPCAT,"$ypcat $map |");
      while (<YPCAT>){
           #print $_;
           my @list = split(":",$_);
           #print @list;
           push (@user,$list[0]);
     }
     #print @user;  

     my $html_report = <<HTML;
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
      <html>
      <head>
      <body>
      <div align="center"><table><tr>
HTML

       $html_report = $html_report."<td valign=top align=\"center\"><b> User List  for subversion <p>";
       $html_report = $html_report.'<table width="20" cellspacing="1" cellpadding="2" align="center" border="0" width="100%"> <tr><th bgcolor="#FFFF00" width="50%">S.No</th> <th bgcolor="#FFFF00" width="50%">User</th></tr>';
      my $count = 1;
      my @sort_user = sort @user;    
      foreach my $element   ( @sort_user ) {
         if ( defined ($element) ){
            $html_report = $html_report."<tr><td>$count</td><td>$element";
            $count++;
         }
      } 

         #&closeDBHandle($dbh);
      $html_report = $html_report."</table></td>";
      $html_report = $html_report.'</tr></table></div></body></html>';
      &generateReport($html_report,$svn_users[0]);

      my $sub = "List of SVN users";
      my $msg = "Please find the list of SVN users";
      print"Sending Mails\n";
      &sendMailAndCleanup($to,$from,$sub,$msg,\@file_names);
      print"Mail send successfully\n";
      unlink @file_names;
      print "Cleanup of the files done\n";
      return 0;

}



##################################################################################################################################################################
#####################################################################MAIN##########################################################################################
####################################################################################################################################################################

print "Getting the list of svn users\n";

#&getBambooUsers();
&getSvnUsers();

