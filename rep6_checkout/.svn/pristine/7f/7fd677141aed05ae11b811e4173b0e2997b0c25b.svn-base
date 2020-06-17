# A perl script to fetch environment variables and
# save them to a property file
use Net::FTP;
use Cwd;

$home=cwd(); 


$propfile          = "antBomUpgradeLocal.properties";
$jboss_config_file = "$ENV{'JBOSS_HOME'}/server/production/deploy/jboss-web.deployer/server.xml";
$jboss_boot_log    = "$ENV{'JBOSS_HOME'}/server/production/log/boot.log";
$atao_custom_props = "$ENV{'JBOSS_HOME'}/server/production/deploy/atao.ear/atao.war/WEB-INF/classes/custom.properties";
$atao_env_props    = "./env.properties";
$atao_file_props   = "./file.properties";
$major_release_num = $ARGV[0];
$current_release   = $ARGV[1];
$is_dev_ftp        = $ARGV[2];  # true\false
$manual_BOM_path   = $ARGV[3];  # /exports/rebuild/bamboo2/xml-data/build-dir/V88SR1-BOM-JOB1/checkout/atao/relWorkArea/*zip
$is_manual_BOM     = $ARGV[4];  # true\false
$manual_BOM_version  = $ARGV[5]; # special_65043
$manual_BOM_zip_version = $ARGV[6];  #65432
$is_test_BOM = $ARGV[7];
$branch = $ARGV[8];

#$username = $ARGV[7];  #user
#$password = $ARGV[8];  #pass


#Set the ftp_dir_root with test BOM location 
#if both the paramanets is_test_BOM and branch 
#is true.

if ( defined $is_test_BOM and $is_test_BOM eq "true" ) {

   if ( defined $branch ){
       print "The current release is".$current_release."\n";
       $ftp_dir_root      = "/export/data/dev-ftp/azetra/packages/BOM.test/".$branch."/".$major_release_num."/".$current_release."/";
       print "The FTP dir root is".$ftp_dir_root."\n";
   
   } else {

       die("Required Parmeters missing:Define both properties is_test_BOM and branch\n"); 
   }

} else {

    $ftp_dir_root      = "/export/data/dev-ftp/azetra/packages/" . $major_release_num . "/" . $current_release. "/";
}

$atao_version      = "";
$latest_bom_number = "";


print "arg0 is $major_release_num \n";
print "arg1 is $current_release \n";

print "arg2 is $is_dev_ftp \n";
print "arg3 is $manual_BOM_path \n";
print "arg4 is $is_manual_BOM \n";
print "arg5 is $manual_BOM_version \n";


@jbossprops        =
  ( 'jboss.partition.name', 'jboss.partition.udpGroup','jboss.server.home.dir', 'bind.address' )
  ;                 # an array of boot.log properties
my (%boot_hash);    # a  hash table to hold the boot.log data

# get some env variables
$java_home =$ENV{'JAVA_HOME'};
$jboss_home =$ENV{'JBOSS_HOME'};

# get OS specific parameters
print "Getting OS specific values...\n";
&SetupByOs();


# Get the port number from server.xml
open( CONFIG, $jboss_config_file )
  or print "$jboss_config_file not found";

while (<CONFIG>) {

	# search for the jboss.bind.address
	if ( $_ =~ /UTF8/ ) {
		$match = index( $_, 8 );
		$port = substr( $_, $match, 4 );
	}
}
close CONFIG;


# Get the db server alias
open( CUSTOM, $atao_custom_props )
  or print "$atao_custom_props";

while (<CUSTOM>) {

	# search for the jboss.bind.address	
	if ( $_ =~ /atao.persist.logical.db/ ) {
			@line = split( /\=/, $_ );    #split the line on whitespace
			$db_alias = $line[1];
			chomp $db_alias;
	}
}
close CUSTOM;

# Get the udp.address and cluster.group from the jboss boot.log
open( BOOTLOG, $jboss_boot_log )
  or print "$jboss_boot_log not found";

# Read the boot.log file
while (<BOOTLOG>) {
	foreach $token (@jbossprops) {

		#search for a match
		if ( $_ =~ /$token/ ) {
			@line = split( /\s+/, $_ );    #split the line on whitespace
			$temp = $line[4];
			$temp =~ s/\\/\//mg; #change the backslash to forward 
			$boot_hash{$token} = $temp;
		}
	}

}

if (! jboss.partition.udpGroup){
	print "WARNING jboss.partition.udpGroup was not found. Setting default: 230.0.0.4\n";
	$boot_hash{"jboss.partition.udpGroup"} = "230.0.0.13";
}

if (! $port){
	print "WARNING jboss.port was not found. Setting default: 8080\n";
	$port = "8080";
}
# Open a file for output
#open( PROPFILE, ">$propfile" );
#
#print PROPFILE "java.home=$java_home\n";
#print PROPFILE "jboss.home=$jboss_home\n";
#print PROPFILE "\n# The user who owns this install\n";
#print PROPFILE "atao.username=$user\n";
#print PROPFILE "\n# The jboss server IP or name\n";
#print PROPFILE "application.server=$host\n\n";
#
#
#print PROPFILE "\n# Jboss boot log parameters\n";
#while ( ( $key, $value ) = each(%boot_hash) ) {
#	print PROPFILE "$key=$value\n";
#}
#
#print PROPFILE "\n# antBomInstallCommonSettings parameters\n";
#print PROPFILE "target.db.alias=$user\n";
#print PROPFILE "target.db=$db_alias\n";
#print PROPFILE "jboss.port=$port\n";
#print PROPFILE "jvm.max.mem=1536M\n";
#print PROPFILE "database.sid=$ENV{'ORACLE_SID'}\n";
#
#print PROPFILE "\n# Misc helpful parameters\n";
#print PROPFILE "cwd=$home";
#
#
# We're done
#close(PROPFILE);

print "Please verify all properties  set in $propfile";


##################################################################################
# Set the runtime variables by OS
# 
# 


sub SetupByOs (){

  #Take care of any OS specific details. The test machine can be unix or nt
  if ($^O eq "MSWin32"){
        #Set for Windows
        $host = $ENV{'COMPUTERNAME'};
        $user; # = $ENV{USERNAME};
        $jboss_home =~ s/\\/\//mg; #change the backslash to forward
        $java_home =~ s/\\/\//mg;

  }else {
        #For non-windows
        $host = $ENV{'HOSTNAME'};
        $user;# = $ENV{'USER'}
        print "The user that is running this script is : " . $ENV{'USER'} . "\n";
        print "The hostname that is discovered is this is : " . $ENV{'HOSTNAME'} . "\n";
        print "The jboss homdir is : " . $ENV{'JBOSS_HOME'} . "\n";

        

  # Get the db server alias
open( ENV, $atao_env_props )
  or print "$atao_env_props";

while (<ENV>) {

        # search for the jboss.bind.address
        if ( $_ =~ /database.username/ ) {
                        @line = split( /\=/, $_ );    #split the line on whitespace
                        $user = $line[1];

                chomp $user;
        }
}
close ENV;

  }
  
  # get the latest BOM version
$maxBOMNumber = 0;
print "Getting bom number.\n";

$env_prop_file = "../../../env.properties";
$pwd="";
open(PRIMENV, $env_prop_file);
while (<PRIMENV>)
{
        $pwd = $_;
}
close (PRIMENV);


if( $is_dev_ftp ne "true")
{
  print "is_dev_ftp is not true \n";
  if($is_manual_BOM ne "true")
  {   
    print "is_manual_bom is not true \n";
    # just a bom number like 60123 
    $maxBOMNumber = GetBOMVersion();

    open(ENV, ">>$atao_file_props" );
    print ENV "\n$pwd\n";
    print ENV "ftp.dir=" . $ftp_dir_root .  $maxBOMNumber . "\n";
    print ENV "ftp.file=" . $current_release . "." . $maxBOMNumber . ".zip\n";
    close (ENV);
    print "ftpdir is : " . "ftp.dir=" . $ftp_dir_root .  $maxBOMNumber . "\n";

  }
  else 
  {
    print "is_dev_ftp is not true \n";
    print "is_manual_bom is true \n";
    # bom number is passed in
    $maxBOMNumber = $manual_BOM_version;
    
    open(ENV, ">>$atao_file_props" );
    print ENV "\n$pwd\n";
    print ENV "ftp.dir=" . $ftp_dir_root .  $maxBOMNumber . "\n";
    print ENV "ftp.file=" . $current_release . "." . $manual_BOM_zip_version . ".zip\n";
    close (ENV);
    print "ftpfile is : " . "ftp.file=" . $ftp_dir_root .  $maxBOMNumber . "/" . $current_release . "." . $manual_BOM_zip_version. ".zip\n";
  }
}
else 
{ 
  print "is_dev_ftp is true \n";
  # a full zip file name like 8.8.1.0.70631.zip
  $maxBOMNumber = GetDevBOMVersion();
  
  open(ENV, ">>$atao_file_props" );
  print ENV "\n$pwd\n";
  print ENV "ftp.dir=" . $manual_BOM_path . "\n";
  print ENV "ftp.file=" . $maxBOMNumber . "\n";
  close (ENV);
  print "ftpdir is : " . "ftp.dir=" . $manual_BOM_path .  $maxBOMNumber . "\n";
}

print "User is : " . $user . "\n";

}

##################################################################################
# Get the latset BOM version by looking at the ftp site for the greatest 
# 
# 

sub GetBOMVersion ()
{
  $maxdir = 0;
  $host = "dev-ftp.deploy.com";
  #$directory = "export/data/dev-ftp/azetra/packages/8.7/8.7.8.0/";
  #$directory = "/export/data/dev-ftp/azetra/packages/BOM.test/SR90Spectrum/9.0/9.0.7.0

  if ( defined $is_test_BOM and $is_test_BOM eq "true" ) {

     $directory = "./packages/BOM.test/".$branch."/".$major_release_num . "/" . $current_release . "/";
     print "The Directory is ".$directory."\n";

  } else {

     $directory = "BOMs/". $major_release_num . "/" . $current_release . "/";

  }
  
  $ftp=Net::FTP->new($host,Timeout=>240) or $newerr=1;
  push @ERRORS, "Can't ftp to $host: $!\n" if $newerr;
  myerr() if $newerr;
  print "Connected\n";

  $ftp->login("azetra","azetra123") or $newerr=1;
  print "Getting file list\n";
    push @ERRORS, "Can't login to $host: $!\n" if $newerr;
    $ftp->quit if $newerr;
    myerr() if $newerr; 
  print "Logged in\n";

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
  $ftp->quit;

  foreach $dir (@files)
  {
  print "current BOM number is : " . $dir . "\n";
    if ($maxdir < $dir)
    {
      $maxdir = $dir;
    }
  }
  print "BOM number is : " . $maxdir . "\n";
  return $maxdir;
}

##################################################################################
# Get the latset BOM version by looking at the ftp site for the greatest 
# 
# 

sub GetDevBOMVersion ()
{
  $maxdir = 0;
  $host = "kws-us-bomspectrum.us.kronos.com";
  #$directory = "export/data/dev-ftp/azetra/packages/8.7/8.7.8.0/";
  $directory = $manual_BOM_path;
  
  $ftp=Net::FTP->new($host,Timeout=>240) or $newerr=1;
  push @ERRORS, "Can't ftp to $host: $!\n" if $newerr;
  myerr() if $newerr;
  print "Connected\n";

  $ftp->login($username,$password) or $newerr=1;
  print "Getting file list\n";
    push @ERRORS, "Can't login to $host: $!\n" if $newerr;
    $ftp->quit if $newerr;
    myerr() if $newerr; 
  print "Logged in\n";

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
  $ftp->quit;
  $zipName = "";
  $maxZipName = "";

  foreach $dir (@files)
  {
      # in this location there should only be one zip file;
      if($dir =~ m/ zip/)
      {
        $zipName = substr($dir, -9, 5);
      
        print "current BOM number is : " . $zipName . "\n";
        if ($maxdir < $zipName)
        {
          $maxdir = substr($dir, -9, 5);
          $maxZipName = $dir;
        }
    }
  }
  print "BOM number is : " . $maxdir . "\n";
  return $maxZipName;
}

sub myerr {
  print "Error: \n";
  print @ERRORS;
  #exit 0;
}


