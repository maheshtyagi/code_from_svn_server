# A perl script to fetch environment variables and
# save them to a property file
use Net::FTP;
use Cwd;

#$ftp_dir_root      = "/export/data/dev-ftp/azetra/packages/8.7/8.7.7.0/";  #need to add function to append bom sr number

##################################################################################
# Get the latset BOM version by looking at the ftp site for the greatest 
# 
# 
  $maxdir = 0;
  $host = $ARGV[0];
  #$directory = "export/data/dev-ftp/azetra/packages/8.7/8.7.8.0/";
  $directory = $ARGV[1];
  $bomDirectory = "";
  
  print "arg 1: " .$ARGV[0];
  print "arg 2: " .$ARGV[1];
  
   print "find max dir is";
  
  $ftp=Net::FTP->new($host,Timeout=>240) or $newerr=1;
  push @ERRORS, "Can't ftp to $host: $!\n" if $newerr;
  myerr() if $newerr;
  print "Connected\n";

  $ftp->login("azetra","azetra123") or $newerr=1;
  #$ftp->login("rebuild","Rb20081216") or $newerr=1;
  print "Getting file list\n";
    push @ERRORS, "Can't login to $host: $!\n" if $newerr;
    $ftp->quit if $newerr;
    myerr() if $newerr; 
  print "Logged in\n";

print "first dir " . $directory . "\n";
  $ftp->cwd($directory) or $newerr=1; 
    push @ERRORS, "Can't cd  $!\n" if $newerr;
    myerr() if $newerr;
    $ftp->quit if $newerr;

  @files=$ftp->ls or $newerr=1;
    push @ERRORS, "Can't get file list $!\n" if $newerr;
    myerr() if $newerr;
  print "Got  file list\n";   
  foreach(@files) {
    print "$_\n";
    }

  foreach $dir (@files)
  {
  print "current BOM number is : " . $dir . "\n";
    if ($maxdir < $dir)
    {
      $maxdir = $dir;
    }
  }
   $ftp->cwd();
  
  $bomDirectory = $directory . $maxdir;
  $ftp->cwd($bomDirectory) or $newerr=1;
  push @ERRORS, "Can't cd  $!...\n" if $newerr;
  myerr() if $newerr;
      
  #$ftp->delete("NotVerified_ReadMe.txt");
    
  open(README, ">Verified_ReadMe.txt");
  print README "This BOM version : " . $maxdir . " has been verified.\n";
  print README "The user is : " . $ENV{USERNAME} . "\n";
    
  ($sec,$min,$hour,$mday,$mon,$year,$wday,
  $yday,$isdst)=localtime(time);
  printf README "Verified at : %4d-%02d-%02d %02d:%02d:%02d\n",
  $year+1900,$mon+1,$mday,$hour,$min,$sec;
    
  #$ftp->put("Verified_ReadMe.txt")
  
  $ftp->quit;

sub myerr {
  print "Error: \n";
  print @ERRORS;
  #exit 0;
}
