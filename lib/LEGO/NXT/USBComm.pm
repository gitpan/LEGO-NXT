package LEGO::NXT::USBComm;

use Device::USB;
use LEGO::NXT::Constants;
use strict;

=head1 NAME

LEGO::NXT::USBComm - The USB Communication Module For the NXT 

=head1 SYNOPSIS

  use LEGO::NXT::USBComm;

  $comm = new LEGO::NXT::USBComm();

=head1 DESCRIPTION

Presents a USB comm interface to the LEGO NXT for internal use in the L<LEGO::NXT> module.

=cut

my $USB_ID_VENDOR_LEGO = 0x0694;
my $USB_ID_PRODUCT_NXT = 0x0002;
my $USB_OUT_ENDPOINT   = 0x01;
my $USB_IN_ENDPOINT    = 0x82;
my $USB_TIMEOUT        = 1000;
my $USB_READSIZE       = 64;
my $USB_INTERFACE      = 0;

=head1 METHODS

=head2 new

  $interface = 0; 
  $comm = new LEGO::NXT:USBComm($interface) 
  $nxt = LEGO::NXT->new( $comm );

Creates a new USB comm object. $interface will usually be 0 unless you're using more than one NXT. 

=cut

sub new
{
  my ($pkg,$interface) = @_;

  my $this = {
    'interface'   => $interface || $USB_INTERFACE,
    'fh'          => undef ,
    'device_name' => undef ,
    'id'          => undef ,
    'serial'      => undef ,
    'status'    => 0
  };

  bless $this, $pkg;
  $this;
}


sub connect
{ 
  my ($this) = @_;
 
  my $usb = Device::USB->new();

  my $dev = $usb->find_device($USB_ID_VENDOR_LEGO, $USB_ID_PRODUCT_NXT);
     die "Device not found.\n" unless defined $dev;

  $dev->open();
  $dev->reset();

  $this->{device_name} = $dev->filename();
  $this->{id}          = sprintf("%04x:%04x", $dev->idVendor(), $dev->idProduct() );
  $this->{serial}      = $dev->serial_number();

  $dev->claim_interface($USB_INTERFACE);
  $this->{fh} = $dev;
  $|=1; #HOT PIPES
  $dev;
}

sub do_cmd
{
  my ($this,$request,$needsret) = @_;

  $this->connect unless $this->{fh};

  my $dev = $this->{fh};

  $dev->bulk_write($USB_OUT_ENDPOINT, $request, length($request), $USB_TIMEOUT);

  return if( $needsret == $NXT_NORET );

  my $buf = "\0" x $USB_READSIZE;
  my $response ='';
  my $len;
  my $nread;
  $|=1; 

  $dev->bulk_read($USB_IN_ENDPOINT, $buf, $USB_READSIZE, $USB_TIMEOUT);

  $buf;  
}



sub type { 'usb' }

1;
