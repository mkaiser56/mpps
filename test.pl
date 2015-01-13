#!D:\Programme\Perl\bin\perl -w
#
use strict;
use English;
use warnings;
#use Win32::SerialPort;
use TestSerialPort;

# global variables and settings
use vars qw( $sl45 $config $result );
$OUTPUT_AUTOFLUSH = 1;

# Open connection to Siemens SL45 via COM1
$config = 'COM1_SL45.cfg';
#$sl45 = Win32::SerialPort->start ($config);
$sl45 = TestSerialPort->start ($config);
die "Can't open serial port COM1 from $config $^E\n" unless ($sl45);

# Test communication with Siemens SL45
$sl45->write ("AT+CGMI\r");
sleep 1;
$result = $sl45->input;
print ">$result<\n";
die "Siemens SL45 not ready - Shutdown\n" unless $result =~ /SIEMENS/;

# close connection to Siemens SL45  
undef $sl45;


