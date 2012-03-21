package SWF::ForcibleConverter;

use strict;
use warnings;
use vars qw($VERSION $DEFAULT_BUF_SIZE $DEBUG);
$VERSION            = '0.01_01';
$DEFAULT_BUF_SIZE   = $ENV{SWF_FORCIBLECONVERTER_DEFAULT_BUF_SIZE} || 4096;
$DEBUG              = $ENV{SWF_FORCIBLECONVERTER_DEBUG};

use IO::File;
use IO::Handle;

use constant HEADER_SIZE => 8;

sub new {
    my $class = shift;
    $class = ref $class || $class;
    
    my $args = shift || {};
    my $self = $args;
    bless $self, $class;

    $self->{_r_io} = undef;
    $self->{_w_io} = undef;

    return $self;
}

sub buffer_size {
    my $self = shift;
    return @_ ? $self->{buffer_size} = shift : $self->{buffer_size};
}

sub _open_r {
    my $self = shift;
    my $file = shift; # or STDIN
    unless( $self->{_r_io} ){
        my $io;
        if( defined $file ){
            if( ref($file) ){
                $io = $file; # it sets opend file handle that is a "IO"
            }else{
                $io = IO::File->new;
                $io->open($file,"r") or die "Cannot open $file: $!";
            }
        }else{
            $io = IO::Handle->new;
            $io->fdopen(fileno(STDIN),"r") or die "Cannot open STDIN: $!";
        }
        $self->{_r_io} = $io;
    }
    return $self->{_r_io};
}

sub _open_w {
    my $self = shift;
    my $file = shift; # or STDOUT
    unless( $self->{_w_io} ){
        my $io;
        if( defined $file ){
            $io = IO::File->new;
            $io->open($file,"w") or die "Cannot open $file: $!";
        }else{
            $io = IO::Handle->new;
            $io->fdopen(fileno(STDOUT),"w") or die "Cannot open STDOUT: $!";
        }
        $self->{_w_io} = $io;
    }
    return $self->{_w_io};
}

sub _close_r {
    my $self = shift;
    if( $self->{_r_io} ){
        $self->{_r_io}->close;
        $self->{_r_io} = undef;
    }
}

sub _close_w {
    my $self = shift;
    if( $self->{_w_io} ){
        $self->{_w_io}->close;
        $self->{_w_io} = undef;
    }
}

sub _version {
    my $self    = shift;
    my $header  = shift;
    return ord(substr($header, 3, 1));
}

sub _set_version_9 {
    my $self    = shift;
    my $header  = shift;
    substr($header, 3, 1, 0x09);
    return $header;
}

sub _is_compressed {
    my $self    = shift;
    my $header  = shift;
    my $char = substr($header, 0, 1);
    $char eq "\x43";
}

sub _get_body_position {
    my $self    = shift;
    my $the_9th = shift; # 9th char

    my $result  = 0;
    $result += 3; # "FWS" or "CWS"
    $result += 1; # version
    $result += 4; # length

    my $rectNBits = int( ord($the_9th) >> 3 );  # unsigned right shift
    $result += int( (5 + $rectNBits * 4) / 8 ); # stage(rect)
    $result += 2; # ?
    $result += 1; # frame rate
    $result += 2; # total frames
    
    return $result;
}

sub version {
    my $self    = shift;
    die "TODO";
}

sub is_compressed {
    my $self    = shift;
    die "TODO";
}

sub uncompress {
    my $self    = shift;
    die "TODO";
}

sub convert9 { # with close handles
    my $self    = shift;
    my $input   = shift; # or STDIN
    my $writer  = shift; # or STDOUT

    my ($buf, $size);
    my $header      = undef; # keep original header is 8 bytes
    my $header_v9   = undef; # converted header
    my $buf_size    = $self->buffer_size || $DEFAULT_BUF_SIZE;

    # ready to read
    my $r = $self->_open_r($input);

    # read header, 8 bytes from origin
    $size = $r->read($header, HEADER_SIZE);
    die "Failed to read the header" if( ! defined $size or $size != HEADER_SIZE );
    $header_v9 = $header;

    # check compressed
    if( $self->_is_compressed($header) ){
        $DEBUG and say STDERR "compressed";
        require IO::Uncompress::Inflate;
        $r = IO::Uncompress::Inflate->new($r)
            or die "Cannot create IO::Uncompress::Inflate: $IO::Uncompress::Inflate::InflateError";
        substr($header_v9, 0, 1, "\x46"); # "C"WS to "F"WS
    }


    # read first chunk that includes info for body position
    my $first = undef;
    $size = $r->read($first, $buf_size);
    die "Failed to read the first chunk" if( ! defined $size or $size != $buf_size );
    my $pos = $self->_get_body_position(substr($first, 0, 1));

    # read and write header with updating the version to 9
    my $version = $self->_version($header);
    $DEBUG and say STDERR "version: $version";

    if( $version < 9 ){
        $header_v9 = $self->_set_version_9($header_v9);
    }

    # ready to output
    if( ref($writer) ne 'CODE' ){
        my $w = $self->_open_w($writer);
        $writer = sub {
            $w->print($_[0]);
        };
    }

    my $total = 0;
    if( 9 <= $version ){
        # simply, copy (but uncompressed)

        $writer->($header_v9);
        $total += length $header_v9;
        
        $writer->($first);
        $total += length $first;
        
        while( ! $r->eof ){
            undef $buf;
            $size = $r->read($buf, $buf_size);
            if( ! defined $size or $size != $buf_size ){
                if( ! $r->eof ){
                    die "Failed to read a chunk";
                }
            }
            $writer->($buf);
            $total += length $buf;
        }
    
    }elsif( 8 <= $version ){
        # find file attributes position

        die "Version of swf is 8, it does not be implemented yet";
        
    }else{

        $writer->($header_v9);
        $total += length $header_v9;
        
        $buf = substr($first, 0, $pos - HEADER_SIZE );
        $writer->($buf);
        $total += length $buf;
        
        # magic
        $buf = "\x44\x11\x08\x00\x00\x00";
        $writer->($buf);
        $total += length $buf;
    
        # remains
        $buf = substr($first, $pos - HEADER_SIZE );
        $writer->($buf);
        $total += length $buf;
    
        while( ! $r->eof ){
            undef $buf;
            $size = $r->read($buf, $buf_size);
            if( ! defined $size or $size != $buf_size ){
                if( ! $r->eof ){
                    die "Failed to read a chunk";
                }
            }
            $writer->($buf);
            $total += length $buf;
        }
    }

    $self->_close_w;
    $self->_close_r;
    
    return $total;
}

1;
__END__


=pod

=head1 NAME

SWF::ForcibleConverter - forcible convert SWF version

=head1 SYNOPSIS

    use SWF::ForcibleConverter;
    
    my $fc = SWF::ForcibleConverter->new;
    my $size = $fc->convert9($input, $output);

=head1 DESCRIPTION

Forcibly convert SWF file into version 9 format if it is less than 9.

=head1 CONSTRUCTOR

An constructor new() accepts an hash reference as options.

Following key / value pairs are available.

=head2 buffer_size

Buffer size (Bytes) when reading input data. Default is 4096.

=head1 METHOD

=head2 buffer_size

    my $size = $fc->buffer_size; # getter
    $fc->buffer_size($integer);  # setter

An access method to buffer_size.

=head2 convert9

    my $input   = "/path/to/original.swf";
    my $output  = "converted.swf";
    my $bytes   = $fc->convert9($input, $output);

Convert input SWF into output with changing format version 9.
It will return output bytes.

Both input and output is omissible.
In that case, STDOUT/STDERR is used.

    $ cat in.swf | perl -MSWF::ForcibleConverter -e \
        'SWF::ForcibleConverter->new->convert9' > out.swf

Note that an output is always uncompressed.

=head1 AUTHOR

WATANABE Hiroaki E<lt>hwat@mac.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

SWF::ForcibleConverter was prepared with reference to "ForcibleLoader"
that is produced by Spark project with the kind of respect:

L<http://www.libspark.org/wiki/yossy/ForcibleLoader>

=cut
