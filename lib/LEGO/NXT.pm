# vim: sts=2 sw=2

# LEGO NXT Direct Commands API
# Author: Michael Collins michaelcollins@ivorycity.com
# Contributions: Aran Deltac aran@arandeltac.com
#
# Copyright 2006 Michael Collins
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# You may also distribute under the terms of Perl Artistic License, 
# as specified in the Perl README file.
#

package LEGO::NXT;
use strict;

use Net::Bluetooth;
use Exporter qw( import );

our $VERSION = '1.41000';
our @EXPORT;

=head1 NAME

LEGO::NXT - LEGO NXT Direct Commands API.

=head1 SYNOPSIS

  use LEGO::NXT;
  
  # Create a new Bluetooth/NXT object by connecting to
  # a specific bluetooth address and channel.
  my $nxt = LEGO::NXT->new( 'xx:xx:xx:xx:xx:xx', 1 );
  
  $nxt->play_sound_file($NXT_NORET, 0,'! Attention.rso');
  
  $res  = $nxt->get_battery_level($NXT_RET);
  
  # Turn on Motor 1 to full power.
  $res = $nxt->set_output_state(
    $NXT_RET,
    $NXT_SENSOR1,
    100,
    $NXT_MOTORON|$NXT_REGULATED,
    $NXT_REGULATION_MODE_MOTOR_SPEED, 0,
    $NXT_MOTOR_RUN_STATE_RUNNING, 0,
  );

=head1 DESCRIPTION

This module provides low-level control of a LEGO NXT brick over bluetooth
using the Direct Commands API.  This API will not enable you to run programs
on the NXT, rather, it will connect to the NXT and issue real-time commands
that turn on/off motors, retrieve sensor values, play sound, and more.

Users will leverage this API to control the NXT directly from an external box.

This is known to work on Linux. Other platforms are currently untested,
though it should work on any system that has the Net::Bluetooth module.

=head1 IMPORTANT CONSTANTS

All of the following constants are exported in to your namespace by
default, except for the OPCODES.

=head2 RET and NORET

For each request of the NXT, you must specify whether you want the NXT to
send a return value.

 $NXT_RET
 $NXT_NORET

Use $NXT_RET only when you really need a return value as it does have some
overhead because it has do do a second request to retrieve response
data from NXT and then parses that data.

=cut

my $NXT_RET   = 0x00;
my $NXT_NORET = 0x80;

push @EXPORT, qw( $NXT_RET $NXT_NORET );

=head2 IO PORT

  $NXT_SENSOR1
  $NXT_SENSOR2
  $NXT_SENSOR3
  $NXT_SENSOR4
  
  $NXT_MOTOR_A
  $NXT_MOTOR_B
  $NXT_MOTOR_C
  $NXT_MOTOR_ALL

=cut

my $NXT_SENSOR_1  = 0x00;
my $NXT_SENSOR_2  = 0x01;
my $NXT_SENSOR_3  = 0x02; 
my $NXT_SENSOR_4  = 0x03;

my $NXT_MOTOR_A   = 0x00;
my $NXT_MOTOR_B   = 0x01;
my $NXT_MOTOR_C   = 0x02;
my $NXT_MOTOR_ALL = 0xFF;

push @EXPORT, qw(
    $NXT_SENSOR_1 $NXT_SENSOR_2 $NXT_SENSOR_3 $NXT_SENSOR_4
    $NXT_MOTOR_A $NXT_MOTOR_B $NXT_MOTOR_C $NXT_MOTOR_ALL
);

=head2 MOTOR CONTROL CONSTANTS

Output mode:

  $NXT_MOTOR_ON
  $NXT_BRAKE
  $NXT_REGULATED

Output regulation modes:

  $NXT_REGULATION_MODE_IDLE
  $NXT_REGULATION_MODE_MOTOR_SPEED
  $NXT_REGULATION_MODE_MOTOR_SYNC

Output run states:

  $NXT_MOTOR_RUN_STATE_IDLE
  $NXT_MOTOR_RUN_STATE_RAMPUP
  $NXT_MOTOR_RUN_STATE_RUNNING
  $NXT_MOTOR_RUN_STATE_RAMPDOWN

=cut

my $NXT_MOTOR_ON  = 0x01;
my $NXT_BRAKE     = 0x02;
my $NXT_REGULATED = 0x04;

my $NXT_REGULATION_MODE_IDLE        = 0x00;
my $NXT_REGULATION_MODE_MOTOR_SPEED = 0x01;
my $NXT_REGULATION_MODE_MOTOR_SYNC  = 0x02;

my $NXT_MOTOR_RUN_STATE_IDLE        = 0x00;
my $NXT_MOTOR_RUN_STATE_RAMPUP      = 0x10;
my $NXT_MOTOR_RUN_STATE_RUNNING     = 0x20;
my $NXT_MOTOR_RUN_STATE_RAMPDOWN    = 0x40;

push @EXPORT, qw(
  $NXT_MOTOR_ON $NXT_BRAKE $NXT_REGULATED
  $NXT_REGULATION_MODE_IDLE $NXT_REGULATION_MODE_MOTOR_SPEED $NXT_REGULATION_MODE_MOTOR_SYNC
  $NXT_MOTOR_RUN_STATE_IDLE $NXT_MOTOR_RUN_STATE_RAMPUP $NXT_MOTOR_RUN_STATE_RUNNING $NXT_MOTOR_RUN_STATE_RAMPDOWN
);

=head2 SENSOR TYPE

  $NXT_NO_SENSOR
  $NXT_SWITCH
  $NXT_TEMPERATURE
  $NXT_REFLECTION
  $NXT_ANGLE
  $NXT_LIGHT_ACTIVE
  $NXT_LIGHT_INACTIVE
  $NXT_SOUND_DB
  $NXT_SOUND_DBA
  $NXT_CUSTOM
  $NXT_LOW_SPEED
  $NXT_LOW_SPEED_9V
  $NXT_NO_OF_SENSOR_TYPES

=cut

my $NXT_NO_SENSOR           = 0x00;
my $NXT_SWITCH              = 0x01;
my $NXT_TEMPERATURE         = 0x02;
my $NXT_REFLECTION          = 0x03;
my $NXT_ANGLE               = 0x04;
my $NXT_LIGHT_ACTIVE        = 0x05;
my $NXT_LIGHT_INACTIVE      = 0x06;
my $NXT_SOUND_DB            = 0x07;
my $NXT_SOUND_DBA           = 0x08;
my $NXT_CUSTOM              = 0x09;
my $NXT_LOW_SPEED           = 0x0A;
my $NXT_LOW_SPEED_9V        = 0x0B;
my $NXT_NO_OF_SENSOR_TYPES  = 0x0C;

push @EXPORT, qw(
  $NXT_NO_SENSOR $NXT_SWITCH $NXT_TEMPERATURE $NXT_REFLECTION $NXT_ANGLE
  $NXT_LIGHT_ACTIVE $NXT_LIGHT_INACTIVE $NXT_SOUND_DB $NXT_SOUND_DBA
  $NXT_CUSTOM $NXT_LOW_SPEED $NXT_LOW_SPEED_9V $NXT_NO_OF_SENSOR_TYPES
);

=head2 SENSOR MODE

  $NXT_RAW_MODE
  $NXT_BOOLEAN_MODE
  $NXT_TRANSITION_CNT_MODE
  
  $NXT_PERIOD_COUNTER_MODE
  $NXT_PCT_FULL_SCALE_MODE
  
  $NXT_CELSIUS_MODE
  $NXT_FAHRENHEIT_MODE
  
  $NXT_ANGLE_STEPS_MODE
  $NXT_SLOPE_MASK
  $NXT_MODE_MASK

=cut

my $NXT_RAW_MODE            = 0x00;
my $NXT_BOOLEAN_MODE        = 0x20;
my $NXT_TRANSITION_CNT_MODE = 0x40;

my $NXT_PERIOD_COUNTER_MODE = 0x60;
my $NXT_PCT_FULL_SCALE_MODE = 0x80;

my $NXT_CELSIUS_MODE        = 0xA0;
my $NXT_FAHRENHEIT_MODE     = 0xC0;

my $NXT_ANGLE_STEPS_MODE    = 0xE0;
my $NXT_SLOPE_MASK          = 0x1F;
my $NXT_MODE_MASK           = 0xE0;

push @EXPORT, qw(
  $NXT_RAW_MODE $NXT_BOOLEAN_MODE $NXT_TRANSITION_CNT_MODE
  $NXT_PERIOD_COUNTER_MODE $NXT_PCT_FULL_SCALE_MODE
  $NXT_CELSIUS_MODE $NXT_FAHRENHEIT_MODE
  $NXT_ANGLE_STEPS_MODE $NXT_SLOPE_MASK $NXT_MODE_MASK
);

=head2 OPCODES

These are declared for internal use are not exported.

  $NXT_START_PROGRAM
  $NXT_STOP_PROGRAM
  $NXT_PLAY_SOUND_FILE
  $NXT_PLAY_TONE
  $NXT_SET_OUTPUT_STATE
  $NXT_SET_INPUT_MODE
  $NXT_GET_OUTPUT_STATE
  $NXT_GET_INPUT_VALUES
  $NXT_RESET_SCALED_INPUT_VALUE
  $NXT_MESSAGE_WRITE
  $NXT_RESET_MOTOR_POSITION
  $NXT_GET_BATTERY_LEVEL
  $NXT_STOP_SOUND_PLAYBACK
  $NXT_KEEP_ALIVE
  $NXT_LSGET_STATUS
  $NXT_LSWRITE
  $NXT_LSREAD
  $NXT_GET_CURRENT_PROGRAM_NAME
  $NXT_MESSAGE_READ

=cut

my $NXT_START_PROGRAM            = 0x00;
my $NXT_STOP_PROGRAM             = 0x01;
my $NXT_PLAY_SOUND_FILE          = 0x02;
my $NXT_PLAY_TONE                = 0x03;
my $NXT_SET_OUTPUT_STATE         = 0x04;
my $NXT_SET_INPUT_MODE           = 0x05;
my $NXT_GET_OUTPUT_STATE         = 0x06;
my $NXT_GET_INPUT_VALUES         = 0x07;
my $NXT_RESET_SCALED_INPUT_VALUE = 0x08;
my $NXT_MESSAGE_WRITE            = 0x09;
my $NXT_RESET_MOTOR_POSITION     = 0x0A;
my $NXT_GET_BATTERY_LEVEL        = 0x0B;
my $NXT_STOP_SOUND_PLAYBACK      = 0x0C;
my $NXT_KEEP_ALIVE               = 0x0D;
my $NXT_LSGET_STATUS             = 0x0E;
my $NXT_LSWRITE                  = 0x0F;
my $NXT_LSREAD                   = 0x10;
my $NXT_GET_CURRENT_PROGRAM_NAME = 0x11;
my $NXT_MESSAGE_READ             = 0x13;

my %error_codes = (
  0x20 => "Pending communication transaction in progress",
  0x40 => "Specified mailbox queue is empty",
  0xBD => "Request failed (i.e. specified file not found)",
  0xBE => "Unknown command opcode",
  0xBF => "Insane packet",
  0xC0 => "Data contains out-of-range values",
  0xDD => "Communication bus error",
  0xDE => "No free memory in communication buffer",
  0xDF => "Specified channel/connection is not valid",
  0xE0 => "Specified channel/connection not configured or busy",
  0xEC => "No active program",
  0xED => "Illegal size specified",
  0xEE => "Illegal mailbox queue ID specified",
  0xEF => "Attempted to access invalid field of a structure",
  0xF0 => "Bad input or output specified",
  0xFB => "Insufficient memory available",
  0xFF => "Bad arguments"
);

=head1 METHODS

=head2 new

  $nxt = LEGO::NXT->new( 'xx:xx:xx:xx:xx:xx', 1 );

Creates a new NXT object, however a connection is not established until
the first direct command is issued. Argument 1 should be the bluetooth
address of your NXT (from "hcitool scan" for instance). Argument 2 is
the channel you wish to connect on -- 1 or 2 seems to work.

=cut

sub new
{
  my ($pkgnm,$btaddr,$channel) = @_;
  my $this = {
    'btaddr'  => $btaddr,
    'channel' => $channel,
    'fh'      => undef,
    'error'   => undef,
    'errstr'  => undef,
    'status'  => undef,
    'result'  => undef
  };
  
  bless $this, $pkgnm;
  return $this;
}

=head2 initialize_ultrasound_port

  $nxt->initialize_ultrasound_port($NXT_SENSOR_4);

Sets the port of your choosing to use the ultrasound digital sensor.

=cut

sub initialize_ultrasound_port
{
  my ($this,$port) = @_;
  $this->set_input_mode($NXT_RET,$port,$NXT_LOW_SPEED_9V,$NXT_RAW_MODE); 
}

=head2 get_ultrasound_measurement_units 

  $nxt->get_ultrasound_measurement_units($NXT_SENSOR_4);

Returns the units of measurement the US sensor is using (cm? in?)

=cut

sub get_ultrasound_measurement_units
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,7,pack("CC",0x02,0x14));
}

=head2 get_ultrasound_measurement_byte

  $nxt->get_ultrasound_measurement_byte($NXT_SENSOR_4);

Returns the distance reading from the NXT

=cut

sub get_ultrasound_measurement_byte
{
  my ($this,$port,$byte) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x42+$byte));
}

=head2 get_ultrasound_continuous_measurement_interval

  $nxt->get_ultrasound_measurement_interval($NXT_SENSOR_4);

Returns the time period between ultrasound measurements.

=cut

sub get_ultrasound_continuous_measurement_interval
{
  my ($this,$port)=@_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x40));
}

=head2 get_ultrasound_read_command_state

  $nxt->get_ultrasound_read_command_state($NXT_SENSOR_4);

Returns whether the sensor is in one-off mode or continuous measurement
mode (the default).

=cut

sub get_ultrasound_read_command_state
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x41));
}

=head2 get_ultrasound_actual_zero

  $nxt->get_ultrasound_actual_zero($NXT_SENSOR_4);

Returns the calibrated zero-distance value for the sensor

=cut

sub get_ultrasound_actual_zero
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x50));
}

=head2 get_ultrasound_actual_scale_factor

  $nxt->get_ultrasound_actual_scale_factor($NXT_SENSOR_4);

Returns the scale factor used to compute distances

=cut

sub get_ultrasound_actual_scale_factor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x51));
}

=head2 get_ultrasound_actual_scale_divisor

  $nxt->get_ultrasound_actual_scale_divisor($NXT_SENSOR_4);

Returns the scale divisor used to compute distances

=cut

sub get_ultrasound_actual_scale_divisor
{
  my ($this,$port) = @_;
  return $this->ls_request_response($port,2,1,pack("CC",0x02,0x52));
}

=head2 set_ultrasound_off

  $nxt->set_ultrasound_off($NXT_SENSOR_4);

Turns the ultrasound sensor off

=cut

sub set_ultrasound_off
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x00));
}

=head2 set_ultrasound_single_shot

  $nxt->set_ultrasound_single_shot($NXT_SENSOR_4);

Puts the sensor in single shot mode - it will only store a value in a register once each time this function is called

=cut

sub set_ultrasound_single_shot
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x01));
}

=head2 set_ultrasound_continuous_measurement

  $nxt->set_ultrasound_continuous_measurement($NXT_SENSOR_4);

Puts the sensor in continuous measurement mode.  

=cut

sub set_ultrasound_continuous_measurement
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x02));
}

=head2 set_ultrasound_event_capture_mode

  $nxt->set_ultrasound_event_capture_mode($NXT_SENSOR_4);

In this mode the US sensor will detect only other ultrasound sensors in the vicinity.

=cut

sub set_ultrasound_event_capture_mode
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x03)); 
}

=head2 ultrasound_request_warm_reset

  $nxt->ultrasound_request_warm_reset($NXT_SENSOR_4);

I won't lie - I don't know what a "warm reset" is, but it sounds like a nice 
new beginning to me. =)

=cut

sub ultrasound_request_warm_reset
{
  my ($this,$port) = @_;
  return $this->ls_write($NXT_RET,$port,3,0,pack("CCC",0x02,0x41,0x04));
}

=head2 set_ultrasound_continuous_measurement_interval

  $nxt->set_ultrasound_continuous_measurement_interval($NXT_SENSOR_4);

Sets the sampling interval for the range sensor.

TODO: Document valid values...

=cut

sub set_ultrasound_continuous_measurement_interval
{
  my ($this,$port,$interval) = @_;
  return $this->ls_write($NXT_RET,3,0,pack("CCC",0x02,0x40,$interval));
}

=head2 set_ultrasound_actual_zero

  $nxt->set_ultrasound_actual_zero($NXT_SENSOR_4);

Sets the calibrated zero value for the sensor.

=cut

sub set_ultrasound_actual_zero
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x50,$value));
}

=head2 set_ultrasound_actual_scale_factor

  $nxt->set_ultrasound_actual_scale_factor($NXT_SENSOR_4);

Sets the scale factor used in computing range.

=cut

sub set_ultrasound_actual_scale_factor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x51,$value));
}

=head2 set_ultrasound_actual_scale_divisor

  $nxt->set_ultrasound_actual_scale_divisor($NXT_SENSOR_4);

Sets the scale divisor used in computing range.

=cut

sub set_ultrasound_actual_scale_divisor
{
  my ($this,$port,$value) = @_;
  return $this->ls_write($port,3,0,pack("CCC",0x02,0x52,$value));
}

=head2 start_program

  $nxt->start_program($NXT_NORET,$filename)

Start a program on the NXT called $filename 

=cut

sub start_program
{
  my ($this,$needsret,$file) = @_;
  my $strlen = 1+length($file);
  my $ret    = $this->_do_cmd(
    pack("v",3+$strlen).
    pack("CCZ[$strlen]",$needsret,$NXT_START_PROGRAM,$file),
    $needsret
  );

  return if $needsret==$NXT_NORET;

  $this->_parse_generic_ret($ret);
}

=head2 stop_program

  $nxt->stop_program($NXT_NORET)

Stop the currently executing program on the NXT

=cut

sub stop_program
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_STOP_PROGRAM),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 play_tone

  $nxt->play_tone($NXT_NORET,$pitch,$duration)

Play a Tone in $pitch HZ for $duration miliseconds

=cut

sub play_tone
{
  my ($this,$needsret,$pitch,$duration) = @_;

  my $ret = $this->_do_cmd(
    pack("v", 6).
    pack("CCvv",0x80,$NXT_PLAY_TONE,$pitch,$duration),
    $needsret
  );

  return if $needsret==$NXT_NORET;

  $this->_parse_generic_ret($ret);
}

=head2 play_sound_file

  $nxt->play_sound_file($NXT_NORET,$repeat,$file)

Play a NXT sound file called $file. Specify $repeat=1 for infinite repeat, 0 to play only once.

=cut

sub play_sound_file
{
  my ($this,$needsret,$repeat,$file) = @_;
  my $strlen = 1+length($file);
  my $ret    = $this->_do_cmd( 
    pack("v",3+$strlen).
    pack("CCCZ[$strlen]",$needsret,$NXT_PLAY_SOUND_FILE,$repeat,$file), 
    $needsret
  );
  
  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);
}

=head2 set_output_state

  $nxt->set_output_state($NXT_NORET,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit)

Set the output state for one of the motor ports.

  $port        One of the motor port constants.
  $power       -100 to 100 power level.
  $mode        An bitwise or of output mode constants.
  $regulation  One of the motor regulation mode constants.
  $runstate    One of the motor runstate constants.
  $tacholimit  Number of rotation ticks the motor should turn before it stops.

=cut

sub set_output_state
{
  my ($this,$needsret,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit) = @_;
  my $ret = $this->_do_cmd(
    pack("v",12).
    pack("CCCcCCcCV",$needsret,$NXT_SET_OUTPUT_STATE,$port,$power,$mode,$regulation,$turnratio,$runstate,$tacholimit),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);
}

=head2 set_input_mode

  $nxt->set_input_mode($NXT_NORET,$port,$sensor_type,$sensor_mode)

Configure the input mode of a sensor port.

  $port         A sensor port constant.
  $sensor_type  A sensor type constant.
  $sensor_mode  A sensor mode constant.

=cut

sub set_input_mode
{
  my ($this,$needsret,$port,$sensor_type,$sensor_mode) = @_;

  my $ret = $this->_do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$NXT_SET_INPUT_MODE,$port,$sensor_type,$sensor_mode),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_generic_ret($ret);  
}

=head2 get_output_state

  $ret = $nxt->get_output_state($NXT_RET,$port)

Retrieve the current ouput state of $port.

  $ret  A hashref containing the port attributes.

=cut

sub get_output_state
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_GET_OUTPUT_STATE,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  
  $this->_parse_get_output_state($ret);
}

=head2 get_input_values

  $ret = $nxt->get_input_values($NXT_RET,$port)

Retrieve the current sensor input values of $port.

  $ret  A hashref containing the sensor value attributes.

=cut

sub get_input_values
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_GET_INPUT_VALUES,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_input_values($ret);
}

=head2 reset_input_scaled_value

  $nxt->reset_input_scaled_value($NXT_NORET,$port)

If your sensor port is using scaled values, reset them.

=cut

sub reset_input_scaled_value
{
  my ($this,$needsret,$port) = @_;
  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_RESET_SCALED_INPUT_VALUE,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 message_write

  $nxt->message_write($NXT_NORET,$mailbox,$message)

Write a $message to local mailbox# $mailbox.

=cut

sub message_write
{
  my ($this,$needsret,$mailbox,$message) = @_;
  my $mlen = 1+length($message);

  my $ret = $this->_do_cmd(
    pack("v",4+$mlen).
    pack("CCCCZ[$mlen]",$needsret,$NXT_MESSAGE_WRITE,$mailbox,$mlen,$message),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 reset_motor_position

  $nxt->reset_motor_position($NXT_NORET,$port,$relative)

TODO: Specifics

=cut

sub reset_motor_position
{
  my ($this,$needsret,$port,$relative) = @_;

  my $ret = $this->_do_cmd(
    pack("v",4).
    pack("CCCC",$needsret,$NXT_RESET_MOTOR_POSITION,$port,$relative),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 get_battery_level

  $ret = $nxt->get_battery_level($NXT_RET)

  $ret  A hash containing battery attributes - voltage in MV

=cut

sub get_battery_level
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_GET_BATTERY_LEVEL),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_battery_level($ret);
}

=head2 set_stop_sound_playback

  $nxt->set_stop_sound_playback($NXT_NORET)

Stops the currently playing sound file

=cut

sub set_stop_sound_playback
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_STOP_SOUND_PLAYBACK),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);
}

=head2 keep_alive

  $nxt->keep_alive($NXT_NORET)

Prevents the NXT from entering sleep mode

=cut

sub keep_alive
{
  my ($this,$needsret) = @_;
  
  my $ret = $this->_do_cmd(
    pack("v",2).
    pack("CC",$needsret,$NXT_KEEP_ALIVE),
    $needsret	    
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);    
}

=head2 ls_get_status

  $nxt->ls_get_status($NXT_RET,$port)

Determine whether there is data ready to read from an I2C digital sensor.
NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_get_status
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_LSGET_STATUS,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_ls_get_status($ret);		      
}

=head2 ls_write

  $nxt->ls_write($NXT_RET,$port,$txlen,$rxlen,$txdata)

Send an I2C command to a digital I2C sensor.

  $port    The sensor port of the I2C sensor
  $txlen   The length of $txdata
  $rxlen   The length of the expected response (sensor/command specific)
  $txdata  The I2C command you wish to send in packed byte format.
           NOTE: The NXT will suffix the command with a status byte R+0x03,
           but you dont need to worry about this. Do not send it as part of
           $txdata though - it will result in a bus error.

NOTE: The Ultrasonic Range sensor is such a sensor and must be interfaced via the ls* commands

=cut

sub ls_write
{
  my ($this,$needsret,$port,$txlen,$rxlen,$txdata) = @_;

  my $ret = $this->_do_cmd(
    pack("v",5+$txlen).
    pack("CCCCC",$needsret,$NXT_LSWRITE,$port,$txlen,$rxlen).
    $txdata,
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_generic_ret($ret);		      
}

=head2 ls_read

  $nxt->ls_read($NXT_RET,$port)

Read a pending I2C message from a digital I2C device.

=cut

sub ls_read
{
  my ($this,$needsret,$port) = @_;

  my $ret = $this->_do_cmd(
    pack("v",3).
    pack("CCC",$needsret,$NXT_LSREAD,$port),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_ls_read($ret);  
}

=head2 ls_request_response

  $nxt->ls_request_response($port,$txlen,$rxlen,$txdata)

Higher level I2C request-response routine. Loops to ensure data is ready
to read from the sensor and returns the result. 

=cut

sub ls_request_response
{
  my ($this,$port,$txlen,$rxlen,$data) = @_;

  $this->ls_write($NXT_NORET,$port,$txlen,$rxlen,$data);

  my $lsstat;

  do{ $lsstat=$this->ls_get_status($NXT_RET,$port); } while ( $lsstat->{bytesready} < $rxlen );

  $this->ls_read($NXT_RET,$port);
}

=head2 get_current_program_name

  $ret = $nxt->get_current_program_name($NXT_RET)

$ret is a hash containing info on the current;y running program.

=cut

sub get_current_program_name
{
  my ($this,$needsret) = @_;

  my $ret = $this->_do_cmd(
     pack("v",2).
     pack("CC",$needsret,$NXT_GET_CURRENT_PROGRAM_NAME),
     $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_get_current_progran_name($ret);
}

=head2 message_read

  $ret = $nxt->message_read($NXT_RET,$remotebox,$localbox,$remove)

Read a message.

=cut

sub message_read
{
  my ($this,$needsret,$remotebox,$localbox,$remove) = @_;
  
  my $ret = $this->_do_cmd(
    pack("v",5).
    pack("CCCCC",$needsret,$NXT_MESSAGE_READ,$remotebox,$localbox,$remove),
    $needsret
  );

  return if $needsret==$NXT_NORET;
  $this->_parse_message_read($ret);
}

=head1 PRIVATE METHODS

=head2 _do_cmd

=cut

sub _do_cmd
{
  my ($this,$msg,$needsret) = @_;

  $this->_bt_connect() unless defined $this->{fh};

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

=head2 _bt_connect

=cut

sub _bt_connect
{
  my ($this) = @_;
  my $bt = Net::Bluetooth->newsocket("RFCOMM");
  die "Socket could not be created!" unless(defined($bt));

  if($bt->connect($this->{btaddr}, $this->{channel} ) != 0) {
      die "connect error: $!";
  }

  $this->{fh} = $bt->perlfh();
  $| = 1; #just in case our pipes are not already hot.
}

=head2 _parse_get_output_state

=cut

sub _parse_get_output_state
{
  my ($this,$ret) = @_;
  my 
  (
   $len,
   $rval,
   $status,
   $port,
   $power,
   $mode,
   $regulation,
   $turn_ratio,
   $runstate,
   $tacho_limit,
   $tacho_count,
   $block_tacho_count,
   $rotation_count
  ) 
  = unpack( "vvCCcCCcCVlll", $ret );
  
  return 
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok',
    'port'              => $port,
    'power'             => $power,
    'mode'              => $mode,
    'regulation'        => $regulation,
    'turn_ratio'        => $turn_ratio,
    'runstate'          => $runstate,
    'tacho_limit'       => $tacho_limit,
    'tacho_count'       => $tacho_limit,
    'block_tacho_count' => $block_tacho_count,
    'rotation_count'    => $rotation_count
  };
}

=head2 _parse_get_input_values

=cut

sub _parse_get_input_values
{
  my ($this,$ret) = @_;
  my
  (
    $len,
    $rval,
    $status,
    $port,
    $valid,
    $calibrated,
    $sensor_type,
    $sensor_mode,
    $raw_value,
    $normal_value,
    $scaled_value,
    $calibrated_value
  )
  = unpack( "vvCCCCCvvss", $ret );

  return
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok',
    'port'              => $port,
    'valid'             => $valid,
    'calibrated'        => $calibrated,
    'sensor_type'       => $sensor_type,
    'sensor_mode'       => $sensor_mode,
    'raw_value'         => $raw_value,
    'normal_value'      => $normal_value,
    'scaled_value'      => $scaled_value,
    'calibrated_value'  => $calibrated_value # **currently unused**
  };
}

=head2 _parse_get_battery_level

=cut

sub _parse_get_battery_level
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$battery) = unpack( "vvCv", $ret );

  return
  {
   'status'     => $status,
   'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
   'battery_mv' => $battery      
  };		  
}

=head2 _parse_ls_get_status

=cut

sub _parse_ls_get_status
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$bytesready) = unpack( "vvCC", $ret );

  return
  {
    'status'      => $status,
    'statstr'     => $status>0 ? $error_codes{$status} : 'ok',
    'bytesready'  => $bytesready
  };
}

=head2 _parse_ls_read

=cut

sub _parse_ls_read
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$nread,$rxdata) = unpack( "vvCCC[16]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'length'     => $nread,
    'data'       => $rxdata 
  };		   
}

=head2 _parse_get_current_program_name

=cut

sub _parse_get_current_program_name
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status,$name) = unpack( "vvC[19]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'filename'   => $name
  };
}

=head2 _parse_message_read

=cut

sub _parse_message_read
{
  my ($this,$ret) = @_;
  
  my ($len,$rval,$status,$localbox,$length,$message) = unpack( "vvCCC[58]", $ret );

  return
  {
    'status'     => $status,
    'statstr'    => $status>0 ? $error_codes{$status} : 'ok',
    'localbox'   => $localbox,
    'length'     => $length,
    'message'    => $message
  };
}

=head2 _parse_generic_ret

=cut

sub _parse_generic_ret
{
  my ($this,$ret)=@_;
  my ($len,$rval,$status) = unpack( "vvC", $ret );

  return
  {
    'status'            => $status,
    'statstr'           => $status>0 ? $error_codes{$status} : 'ok'
  };
}

1;
__END__

=head1 AUTHOR

Michael Collins <michaelcollins@ivorycity.com>

=head1 CONTRIBUTORS

Aran Deltac <bluefeet@cpan.org>

=head1 LICENSE

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 COPYRIGHT

The LEGO::NXT module is Copyright (c) 2006 Michael Collins. USA.
All rights reserved.

=head1 SUPPORT / WARRANTY

LEGO::NXT is free open source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
