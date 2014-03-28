#!/usr/bin/perl

use Crypt::Blowfish_PP;

my $key = "testkeys";

my @files = qw(file1.png file2.jpg file3.png);

foreach my $file (@files) {
     $file = "../cache/media/$file";
     open ('FILE', "< $file");
     my $pack = pack("H16", $file);     
     print "pack: $pack\n";
     my $encryptor = Crypt::Blowfish_PP->new($pack);
     print "file: $file\n";
     my $cachething = $encryptor->encrypt(<FILE>);
     close(FILE);
     $cachething = unpack("H16", $cachething);
     print "$cachething\n";
     
     my $cachetext =  pack("H16", $cachething);
     my $new_file = $encryptor->decrypt($cachetext);     
     
     print "$new_file\n";
     
}
