#!/usr/bin/perl
use Tie::File;
use Data::Dumper;
use DBI;

my $dbh = DBI->connect('DBI:mysql:openaccess', 'root', 'toor') || die "Could not connect to database: $DBI::errstr";
my $sth = $dbh->prepare('SELECT * FROM log');
$sth->execute();
my $result = $sth->fetchall_hashref("created");

print "ALREADY IN DB: \n";
warn Dumper $result;
print "\n\n";

# general syntax
#INSERT INTO table_name (column1,column2,column3,...) VALUES (value1,value2,value3,...);
# db: id, date (mysql_iso), tag (номер тега), user (0.200), reader (1.2), type (0 - checkin, 1 - entrance)

$sth->finish();

#2009-06-04 19:14:20 sql timestamp format 

# 20:4:51  3/5/14 WED User 7359339 presented tag at reader 1
# 20:4:51  3/5/14 WED 20:4:51  3/5/14 WED User 199 authenticated.
# 20:4:51  3/5/14 WED User  granted access at reader 1
# 20:4:51  3/5/14 WED Alarm level changed to 0
# 20:4:51  3/5/14 WED Alarm armed level changed to 0
# Door 1 unlocked
# Door 1 locked

# 15:38:1  3/6/14 THU User 7357456 presented tag at reader 1
# 15:38:1  3/6/14 THU User not found

# http://stackoverflow.com/questions/14343914/how-to-look-at-the-next-line-of-a-file-in-perl
# http://habrahabr.ru/post/61391/
#http://stackoverflow.com/questions/6978799/comparing-two-hashes-with-the-keys-and-values


tie my @file, 'Tie::File', "access_log_example.txt" or die $!;

my $hash;
my @arr;
my $i=0;

for my $linenr (0 .. $#file) {             # loop over line numbers
    if ($file[$linenr] =~ /^(\d{1,2}:\d{1,2}:\d{1,2})\s{2}(\d{1,2}\/\d{1,2}\/\d{1,2})\s([A-Z]{3})\sUser\s(\d{7})\spresented\stag\sat\sreader\s(\d{1})/) {
    	#print "date: ".$2." time :".$1." day : ".$3." user : ".$4." tag : ".$5."\n";
     	my @date = split('/', $2);
     	if ( length $date[0] == 1 )  { $date[0] = "0".$date[0]; }
		if ( length $date[1] == 1 )  { $date[1] = "0".$date[1]; }
     	my $true_date = "20".$date[2]."-".$date[0]."-".$date[1];
     	#$true_date =~ s/\//\-/g;
     	my @time = split(':', $1);
     	for (@time) { 
     		if (length $_ == 1) { $_ = "0".$_ ; } 
     	}

     	my $true_time = $time[0].":".$time[1].":".$time[2];

     	$hash->{'created'} = $true_date." ".$true_time;
     	$hash->{'tag'} = $4;
     	$hash->{'reader'} = $5;

     	if ($file[$linenr+1] =~ /User\s(\d{1,3})\sauthenticated/) {
			$hash->{'user'} = $1;
		}

		if ($file[$linenr+1] =~ /User\snot\sfound/) {
			$hash->{'user'} = "null";
			$hash->{'type'} = "0";			
		}

		if ($file[$linenr+2] =~ /granted access/) {
			$hash->{'type'} = "1";	# entrance
		}
 	
 	push @arr, $hash;
    $hash={};
    }
    
}
untie @file;

my $from_file = { map { $_->{'created'} => $_ } @arr };


for (sort keys %$from_file ) {
    if (exists $result->{$_} ) {
    print  "do nothing\n";
	} 
	else {
    $sth = $dbh->prepare("INSERT into log (created,tag,user,reader,type) VALUES (?, ?, ?, ?, ?)") or die $dbh->errstr;
    $sth->execute($from_file->{$_}->{'created'}, $from_file->{$_}->{'tag'}, $from_file->{$_}->{'user'}, $from_file->{$_}->{'reader'}, $from_file->{$_}->{'type'})  or die $sth->errstr;
    print "insert";
	}
}


$dbh->disconnect();
#print scalar @arr;