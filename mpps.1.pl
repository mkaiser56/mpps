#!/usr/local/ActivePerl-5.6/bin/perl -w
#
# mpps.pl
#
# Multipurpose Party Server, Version 01

use strict;
use English;
use warnings;
use Win32::SerialPort;
use PDU;

# global variables
use vars qw( $sl45 $config $result $msg );
use vars qw( $sec $min $hour $month_day $month $year $week_day $now );

# Message of the day
my $defmsg = "Heute abend:";
# Places of the day
my @places = ( 'Capri Bar','Cargo Bar','NT Areal','Alpenblick','Hirscheneck','Grenzwert' );
# special Settings
my $logfile = "mpps.log";
my $passwd = "mpps";
my $help = 'ADMIN:<passwd> STOP ->stops service, RESET ->sets message to default, HELP ->sends SMS help file';

sub HandleMessage ();

$OUTPUT_AUTOFLUSH = 1;

# Open connection to Siemens SL45 via COM1
$config = 'COM1_SL45.cfg';
$sl45 = Win32::SerialPort->start ($config);
die "Can't open serial port COM1 from $config $^E\n" unless ($sl45);

# Test communication with Siemens SL45
$sl45->write ("AT+CGMI\r");
sleep 1;
$result = $sl45->input;
die "Siemens SL45 not ready - Shutdown\n" unless $result =~ /SIEMENS/;

# MPPS started
print "Multipurpose Party Server started (terminate with ctrl-c)\n";

# Main Loop ####################################################
while () {
	# set message of the day
	($sec, $min, $hour, $month_day, $month, $year, $week_day) = gmtime();
	my $today = $week_day;
	$msg = "$defmsg $places[rand(scalar(@places))]";
	# Loop of the day
	while ($today eq $week_day) {
		($sec, $min, $hour, $month_day, $month, $year, $week_day) = gmtime();
		$now = localtime();
		HandleMessage();
		sleep 10;
	}
}
# close connection to Siemens SL45  
undef $sl45;


# Procedures ####################################################
# read incoming SMS and answer with the message of the day
sub HandleMessage() {
	use vars qw( @sms $pdu $tpdu $pdustring);
	use vars qw( $phonenumber $servicecenteraddress $timestamp $datacodingscheme $payload $validityperiod $userdataincluded $msglength);

	# open log-file
	open LOG, ">>$logfile" or die "Couldn't open  open log-file for output ($OS_ERROR)\n";
	# Read new SMS from Siemens SL45 (0:new 1:read 4:all) 
	$sl45->write ("AT^SMGL=0\r");
	sleep 1;
	$result = $sl45->input;
	my @sms = split /\n/, $result;
	@sms = grep { m<^0791> } @sms;
	# print "--\n$result--\n";

	# Delete SMS from Siemens SL45 (1:all read 2:all read+sent 4:all) 
	sleep 1;
	$sl45->write ("AT+CMGD=1\r");
	sleep 1;
	$result = $sl45->input;
	# print "--\n$result--\n";

	# Loop incoming messages
	$pdu = GSM::SMS::PDU->new();
	while ($pdustring = shift @sms) {

		# decode PDU message
	 	$tpdu = $pdu->SMSDeliver($pdustring);
		$phonenumber = $tpdu->{'TP-OA'};
		$servicecenteraddress = $tpdu->{'TP-SCN'};
		$timestamp = $tpdu->{'TP-SCTS'};
		$datacodingscheme = $tpdu->{'TP-DCS'};
		$payload = $tpdu->{'TP-UD'};
		print "\n$now incoming <<< $phonenumber: $payload";
		print LOG "$now incoming <<< $phonenumber: $payload\n";
		
		# detect ADMIN Message
		if ($payload =~ s/^ADMIN:$passwd\s*//) { AdminMessage(); }
		else { $payload = $msg; }

		# encode PDU message
		$servicecenteraddress = '+41794999000';
		$datacodingscheme = '00';
		($validityperiod, $userdataincluded) = undef;
	    $pdustring = $pdu->SMSSubmit( 
	                        $servicecenteraddress, 
	                        $phonenumber, 
	                        $payload, 
	                        $datacodingscheme, 
	                        $validityperiod, 
	                        $userdataincluded );
		$msglength = (length($pdustring)/2) - 8;

		# Send answer SMS via Siemens SL45
		$sl45->write ("AT+CMGS=$msglength\r");
		sleep 1;
		$result = $sl45->input;
		$sl45->write ("$pdustring\cz");
		sleep 4;
		$result = $sl45->input;
		print "\n$now outgoing >>> $phonenumber: $payload\n";
		print LOG "$now outgoing >>> $phonenumber: $payload\n";

	}	
	undef $pdu;
	close LOG;
	print ".";
}

# handle administrator messages
sub AdminMessage() {
	print "\n$now adminmessage $phonenumber: $payload";
	print LOG "$now adminmessage $phonenumber: $payload\n";
	
	# stopping MPPS by admin SMS
	die "\nMPPS stopped by admin SMS\n" if ($payload =~ m/^STOP/);

	# reset message of the day
	if ($payload =~ m/^RESET/) 
	{ 
		$payload = "$defmsg $places[rand(scalar(@places))]"; 
		$msg = $payload; 
	}

	# send help message
	elsif ($payload =~ m/^HELP/) { $payload = "$help"; }	
	
	# set new message
	else { $msg = $payload; }
	
}