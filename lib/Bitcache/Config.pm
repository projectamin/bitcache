package Bitcache::Config;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org
use strict;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);
my %config;

sub start_element {
    my ($self, $element) = @_;
    my %attrs = %{$element->{Attributes}};
    $self->element($element);
    if ($element->{LocalName} eq "opt") {
        $self->name($attrs{'{}name'}->{Value});
    }
}

sub characters {
    my ($self, $chars) = @_;
    my $data = $chars->{Data};
    my $element = $self->{"ELEMENT"};
    if ($element->{LocalName} eq "opt") {
        $self->opt($data);
    }
}

sub end_element {
    my ($self, $element) = @_;
    if ($element->{LocalName} eq "opt") {
        $config{$self->name} = $self->opt;
    }
}

sub end_document {
    my $self = shift;
    return \%config;
}

sub element {
    my $self = shift;
    $self->{ELEMENT} = shift if @_;
    return $self->{ELEMENT};
}

sub name {
    my $self = shift;
    $self->{NAME} = shift if @_;
    return $self->{NAME};
}

sub opt {
    my $self = shift;
    $self->{OPT} = shift if @_;
    return $self->{OPT};
}


=head1 Name

Bitcache::Config - simple config.xml reader

=head1 Description

This SAX Filter will read a config.xml configuration file. This
file looks like

  <config>
     <opt name="port">8000</opt>
     <opt name="ip">192.168.1.200</opt>
     <opt name="key">testkeys</opt>
     <opt name="other">other</opt>
  </config>

=back

=cut








1;