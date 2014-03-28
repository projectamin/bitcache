package Bitcache::Opts;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Getopt::Long;

sub new {
     my $class = shift;
     my %args = @_;
     my $self;
     $self = bless \%args, $class;
     return $self;
}

sub get_opts {
    my $opts = shift;
    my ($help, $version, $daemon);
    
    my $opts_ok = &GetOptions( "h|help"    => \$help,
                   "d|daemon" => \$daemon,
                   "v|version" => \$version,
    );

    if ( $help ) {
            $opts->print_help();
            exit 1;
    }
    if ($daemon) {
        $opts->daemon($daemon);
    } 
    if ($version) {
        $opts->print_version();
                exit 1;
    } 
    if (!$opts_ok) {
            $opts->print_usage();
            exit 1;
    };
    if ((!$help) && (!$version) && (!$daemon)) {    
        $opts->print_usage();
        exit  1;
    }
}

sub print_version {
     my $self = shift;
     my $version = shift || $self->version;
     my $head = "Version: $version";
     print $head,  "\n";
}

sub print_usage {
     my $self = shift;
     my $usage = shift || $self->usage;
        my $head = "Usage: $0 ";
        print $head,   "\n\n";
        print $usage, "\n";
}

sub print_help {
     my $self = shift;
     my $help = shift || $self->help;
     my $head = "Help: ";
     print $head, "\n";
     print $help, "\n";
}

sub help {
     my $self = shift;
     if (@_) { $self->{HELP} = shift;}
     return $self->{HELP};
}

sub usage {
     my $self = shift;
     if (@_) { $self->{USAGE} = shift;}
     return $self->{USAGE};
}

sub version {
     my $self = shift;
     if (@_) { $self->{VERSION} = shift;}
     return $self->{VERSION};
}

sub daemon {
     my $self = shift;
     if (@_) { $self->{DAEMON} = shift;}
     return $self->{DAEMON};
}

1;
