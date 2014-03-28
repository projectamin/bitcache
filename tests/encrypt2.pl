#!/usr/bin/perl

use strict;
use Crypt::RSA;

my $message = "this is my message";

my $rsa = Crypt::RSA->new();
my ($public, $private) = 
     $rsa->keygen ( 
          Identity  => 'Lord Macbeth <macbeth@glamis.com>',
          Size      => 1024,  
          Password  => 'A day so foul & fair', 
          Verbosity => 1,
     ) or die $rsa->errstr();


my $cyphertext = 
     $rsa->encrypt ( 
          Message    => $message,
          Key        => $public,
          Armour     => 1,
     ) || die $rsa->errstr();


my $plaintext = 
     $rsa->decrypt ( 
          Cyphertext => $cyphertext, 
          Key        => $private,
          Armour     => 1,
     ) || die $rsa->errstr();


my $signature = 
     $rsa->sign ( 
          Message    => $message, 
          Key        => $private
     ) || die $rsa->errstr();


my $verify = 
     $rsa->verify (
          Message    => $message, 
          Signature  => $signature, 
          Key        => $public
     ) || die $rsa->errstr();

use Data::Dumper;
warn Dumper ("public", $private );
print "public: " . $public->serialize() . "\n\n";
print "private: " . $private->serialize() . "\n\n";
print "cypher: $cyphertext\n\n";
print "plain: $plaintext\n\n";
print "signature: $signature\n\n";
print "verify: $verify\n\n";




