package Bitcache;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use IO::Socket;
use IO::Select;
use Bitcache::Config;
use XML::SAX::PurePerl;
use Crypt::RSA::Key;
use Crypt::RSA::Key::Private;

sub new {
     my $class = shift;
     my %args = @_;
     my $self;
     if ((!$args{'Port'}) || (!$args{'Ip'}) || (!$args{'Key'})) {
          my $config_file = $ENV{'HOME'} . "/.bitcache/config.xml";
          if (! -e $config_file) {
               die "must have a Port, Ip and Key argument or a config.xml with such infos...";
          }
          $config_file = "file:/" . $ENV{'HOME'} . "/.bitcache/config.xml";
          my $h = Bitcache::Config->new();
          my $p = XML::SAX::PurePerl->new(Handler => $h);
          my $config = $p->parse_uri($config_file);
          if ((!$config->{'Port'}) || (!$config->{'Ip'}) || (!$config->{'Key'})) {
               die "must have a Port, Ip and Key argument.";
          } else {
               $args{'Port'} = $config->{'Port'};
               $args{'Ip'} = $config->{'Ip'};
               $args{'Key'} = $config->{'Key'};
               $args{'Cache'} = $config->{'Cache'};
          }
     }
     
     $self = bless \%args, $class;
     return $self;
}

sub Run {
     my $self = shift;
     
     
     #figure out where the Bitcache is located...
     my $cache = $self->{'Cache'};
     #other locations???
     if (! $cache ) {
          $cache = $self->{'Bin'} . "/../cache/";
     }
     $self->{'Cache'} = $cache;
               
     #daemon loads up it's last bitcache hash table
     my $main_cache = $cache . "/index/main_cache.xml";
     my $hash_table = $self->process_cachelist($main_cache);

     #daemon loads up it's local bitcache cache and see if table and cache are "consistent"
     my $media = $cache . "/media/";
     opendir(DIR, $media) or die "can't open the bitcache media: $media : $!";
     while (defined(my $object = readdir(DIR))) {
          # match $media/$object to the local hash table
          my $object = $self->get_object($object);
          if (! $hash_table->{$object->{'hash'}} ) {
               #add in this new object to our hash table.
               push @$hash_table, $object;
          }
     }
     closedir(DIR); 
     
     #add hash table to self
     $self->{'Hash_table'} = $hash_table;
     
     my $bitcaches = $self->get_bitcaches();
     #get any new bitcaches from other bitcaches
     $bitcaches = $self->get_remote_bitcaches($bitcaches);
     
     #start the daemon
     my $local_addr = "$self->{Ip}:$self->{Port}";
     my $server = IO::Socket::INET->new(
                         LocalAddr => $local_addr,
                         Type => SOCK_STREAM,
                         Reuse => 1,
                         Listen => 10,
                          )
     or die "Could not bind as a server on ip $self->{Ip} port $self->{Port} : $@\n";
     print "Bitcache $self->{Ip} on port $self->{Port} has started\n";
     
     my $read_set = IO::Select->new(); # create handle set for reading
     $read_set->add($server);           # add the main socket to the set
     while (1) { # forever
             # get a set of readable handles (blocks until at least one handle is ready)
             my ($rh_set) = IO::Select->select($read_set, undef, undef, 0);
             # take all readable handles in turn
             foreach my $rh (@$rh_set) {
               # if it is the main socket then we have an incoming connection and
               # we should accept() it and then add the new socket to the $read_set
               if ($rh == $server) {
                    my $ns = $rh->accept();
                    $read_set->add($ns);
               } else {
                    # otherwise it is an ordinary socket and we should read and process the request
                    my $line = <$rh>;
                    if ($line) {


                         #daemon tells other bitcache's about it's local hash_table and let's other bitcache's decide
                         #if their ruleset(s) determine if they want to mirror this local bitcache
                         
                         #daemon looks at the other bitcaches and based upon this bitcache daemon's ruleset(s)
                         #the daemon will begin to copy from the other bitcaches into it's bitcache
          
                    
                    
                         # remove the socket from the $read_set and close it
                         $read_set->remove($rh);
                         close($rh);
                    }
               }
          }
     }
}

sub get_password {
     my $self = shift;
     print "What is the bitcache daemon password?\n";
     my $user_pass = <STDIN>;
     my $bitkey = $ENV{'HOME'} . "/.bitcache/bitkey";
     my $private_bitkey = $bitkey . ".private";
     my $public_bitkey = $bitkey . ".public";
     my ($public, $private);
     if (! -e $private_bitkey) {
          print "Creating a new bitcache server key pair\n\n";
          print "Please enter a user name for this key pair\n";
          my $user_name = <STDIN>;
          print "Please enter an email address for this user name\n";
          my $email = <STDIN>;
          my $identity = $user_name . " <" . $email . ">";
          #generate a new pub/priv key for this bitcache
          my $keychain = Crypt::RSA::Key->new();
          ($public, $private) = $keychain->generate ( 
                              'Identity'  => $identity,
                              'Size'      => 2048,  
                              'Password'  => $user_pass, 
                              'Verbosity' => 0,
                             );          
     } else {
          #process the bitcache.private file
          $private = new Crypt::RSA::Key::Private (
                    'FileName' => $private_bitkey,
                    'Password' => $user_pass,
          ); 
          $public = new Crypt::RSA::Key::Public (
                    'FileName' => $public_bitkey,
          ); 
          
     }
     $self->{'Private'} = $private;
     $self->{'Public'} = $public;
     return $private;
}

sub get_object {
     my $self = shift;
     my $filename = shift;
     my $private = $self->{'Private'} || $self->get_password();
     my $public = $self->{'Public'};
     my $rsa = Crypt::RSA->new();
     my %local_object;
     $local_object{'timedate'} = time();

     $local_object{'signature'} = $rsa->sign ('Message' => $filename, 'Key' => $private);;
     $local_object{'identity'} = $private->{'Identity'};
     $local_object{'public_key'} = $public->{'n'};

     my @paths = split(/\//, $filename);

     $local_object{'file'} = pop @paths;
     $local_object{'path'} = join("/", @paths);
     $local_object{'hash_file'} =  $self-{'Cache'} . "/index/" . $local_object{'path'} . "/" . $local_object{'signature'} . ".xml";

     if (-e $local_object{'signature'}) {
          my $o = Bitcache::Object->new();
          my $p = XML::SAX::PurePerl->new(Handler => $o);
          return $p->parse_file($local_object{'hash_file'});
     } else {
          my $file = (<<END);
<bc:object xmlns:bc="http://projectamin.org/ns/bc/">
     <bc:date>$local_object{'timedate'}</bc:date>
     <bc:hash>$local_object{'signature'}</bc:hash>
     <bc:signer>
          <bc:hash>$local_object{'public_key'}</bc:hash>
          <bc:name>$local_object{'identity'}</bc:name>
     </bc:signer>
</bc:object>     
END

          open (FILE, "> $local_object{'hash_file'}");
          print FILE $file;
          close (FILE);
          return \%local_object;
     }
}     



sub get_bitcaches {
     my $self = shift;
     my $bitcache_file = shift || $self->{'Cache'} . "/index/main_bitcache.xml";
     #daemon gets list of last-known bitcache daemons
     my $bitcaches = $self->read_bitcaches($bitcache_file);
     return $bitcaches;
}

sub get_remote_bitcaches {
     my $self = shift;
     #daemon looks up new and previous known bitcache daemons through a bitcache daemon search
     my $bitcaches = $self->{'Bitcaches'};
     foreach my $bitcache (keys %$bitcaches) {
          my $socket = IO::Socket::INET->new(PeerAddr => $bitcache->{'ip'},
                         PeerPort => $bitcache->{'port'},
                         Proto    => "tcp",
                         Type     => SOCK_STREAM)
          or die "Couldn't connect to $bitcache->{'ip'}:$bitcache->{'port'} : $@\n";
          my $text = $bitcache->{'search'} . "/get_bitcaches";
          $socket->print($text);
          my $output = <$socket>;
          $socket->close();
          foreach my $new_bitcache (%$output) {
               if (! $bitcaches->{$new_bitcache->{'name'}} ) {
                    $bitcaches->{$new_bitcache->{'name'}} = $new_bitcache;
               }
          }
     }
     return $bitcaches;
}

sub process_object {
    my ($self, $object, $bitcache) = @_;
    my $out;
    if ($bitcache) {
        my $bc = $self->parse_bitcache($bitcache);
        foreach my $bitcache (keys %$bc) {
            my $protocol = $bc->{$bitcache}->{protocol};
            $out .= $protocol->parse($bc->{$bitcache}, $object);
        }
    } else {
        $out = $self->parse($object);
    }
    my $formatted = $self->parse_CLIOutput($out);
    return $formatted;
}

sub process_cachelist {
    my ($self, $cachelist, $cachelist_map) = @_;

    $cachelist = $self->parse_cachelist($cachelist);

    if($cachelist_map) {
        $cachelist_map = $self->parse_cachelistmap($cachelist_map);
    }
    my @types = qw(object bitcache cachelist);
    my ($objects, $cachelists, $bitcache);
    if (defined $cachelist_map) {
        ($objects, $cachelists, $bitcache) = $self->get_types(\@types, $cachelist_map);
        ($objects, $bitcache) = $self->get_cachelists($objects, $cachelists, $bitcache, $cachelist_map);
    } else {
        #no mapping
        ($objects, $cachelists, $bitcache) = $self->get_types(\@types, $cachelist);
        ($objects, $bitcache) = $self->get_cachelists($objects, $cachelists, $bitcache);
    }

    my $text;
    foreach my $object (@$objects) {
        $text .= $self->process_object($object, $bitcache);
    }
    return $text;
}

1;