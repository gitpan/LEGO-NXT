package LEGO::NXT::MacBlueComm;

use Device::SerialPort;
use LEGO::NXT::Constants;
use strict;

=head1 NAME

LEGO::NXT::MacBlueComm - The Mac Bluetooth Communication Module For the NXT 

=head1 SYNOPSIS

  use LEGO::NXT:MacBlueComm;

  $comm = new LEGO::NXT::MacBlueComm();

=head1 DESCRIPTION

Presents a bluetooth comm interface to the LEGO NXT on the Mac for internal use in the L<LEGO::NXT> module.

=cut

my $DEFAULT_DEVICE = '/dev/tty.NXT-DevB-1';

=head1 METHODS

=head2 new

  $serial_port = '/dev/tty.NXT-DevB-1'; 
  $comm = new LEGO::NXT:MacBlueComm($serial_port) 
  $nxt = LEGO::NXT->new( $comm );

Creates a new Mac Bluetooth comm object based on a Mac Bluetooth serial port. 

=cut

sub new
{
  my ($pkg,$device) = @_;

  my $this = {
    'device'      => $device || $DEFAULT_DEVICE,
    'fh'          => undef ,
    'status'    => 0
  };

  bless $this, $pkg;
  $this;
}


sub connect
{ 
  my ($this) = @_;
 
  my $dev = new Device::SerialPort( $this->{device}, 0 )
       || die "Can't open ".$this->{device}.": $!\n";

  $dev->baudrate(9600);
  $dev->parity("none");
  $dev->databits(8);
  $dev->stopbits(1);
  $dev->handshake("none");
  $dev->write_settings	|| die "fail write setting";

  $|=1; #HOT PIPES
  $this->{fh} = $dev;
  $dev;
}

sub do_cmd
{
  my ($this,$request,$needsret) = @_;

  $this->connect unless $this->{fh};

  my $dev = $this->{fh};

  my $count = $dev->write( $request ); 

  return if( $needsret == $NXT_NORET );

  $|=1; 

  my $msgbytes  = $this->myread(2);
  my ( $msgsz ) = unpack('v',$msgbytes);
  my $msg       = $this->myread( $msgsz );  

  return $msgbytes.$msg;  
}

sub myread
{
  my ( $this, $br ) = @_;
  my $msgbytes      = '';
  my $dev           = $this->{fh};

  return if $br < 1;

  while( my ($tc,$tbytes) = $dev->read( $br ) )
  {
    $br -= $tc;
    $msgbytes .= $tbytes;
    last if $br < 1;
  }

  return $msgbytes;
}


sub type { 'blue' }

1;
