package LEGO::NXT::BlueComm;

use Net::Bluetooth;
use LEGO::NXT::Constants;
use strict;

=head1 NAME

LEGO::NXT::BlueComm - The Bluetooth Communication Module For the NXT

=head1 SYNOPSIS

  use LEGO::NXT::BlueComm;

  $comm = new LEGO::NXT::BlueComm('xx:xx:xx:xx',0);

=head1 DESCRIPTION

Presents a Bluetooth comm interface to the LEGO NXT for internal use in the L<LEGO::NXT> module.

=head1 METHODS

=head2 new

  $btaddr = 'xx:xx:xx:xx';
  $port   = 0;
  $comm   = new LEGO::NXT:BlueComm($btaddr,$port);
  $nxt    = LEGO::NXT->new( $comm );

Creates a new Bluetooth comm object. $btaddr is the bluetooth address of your NXT - can be obtained by "hcitool scan" on Linux platforms. $port should be 0 or 1.

=cut

sub new
{
  my ($pkg,$btaddr,$channel) = @_;

  my $this = {
    'btaddr'  => $btaddr ,
    'channel' => $channel || 0, 
    'fh'      => undef ,
    'status'  => 0
  };

  bless $this, $pkg;
  $this;
}


sub connect
{ 
  my ($this) = @_;

  my $bt = Net::Bluetooth->newsocket("RFCOMM");
  die "Socket could not be created!" unless(defined($bt));

  if($bt->connect($this->{btaddr}, $this->{channel} ) != 0) {
      die "connect error: $!";
  }

  $this->{fh} = $bt->perlfh();
  $| = 1; #just in case our pipes are not already hot. 

  $bt;
}

sub do_cmd
{
  my ($this,$msg,$needsret) = @_;

  $this->connect() unless defined $this->{fh};

  my $fh = $this->{fh};

  syswrite( $fh, $msg, length $msg );
  return if( $needsret == $NXT_NORET );

  #Begin reading response, if requested.
  
  my ($rin, $rout) = ('','');
  my $rbuff;
  my $total;
  
  vec ($rin, fileno($fh), 1) = 1;
  
  while( select($rout=$rin, undef, undef, 1) )
  {
		my $char = '';
		my $nread=0;
  
		eval
		{
			local $SIG{ALRM} = sub { die "alarm\n" };
			alarm 1;
			$nread = sysread $fh, $char, 1;
			alarm 0;
		};
		$rbuff .= $char;
  }
  return $rbuff;
}

sub type { 'blue' }

1;
