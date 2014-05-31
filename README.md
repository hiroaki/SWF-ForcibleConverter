# NAME

SWF::ForcibleConverter - Convert SWF file into version 9 format forcibly if version is under 9

# SYNOPSIS

    use SWF::ForcibleConverter;
    
    my $fc = SWF::ForcibleConverter->new;
    my $size = $fc->convert9($input, $output);

# DESCRIPTION

SWF::ForcibleConverter is an utility
that converts SWF file into version 9 format forcibly.

This program processes SWF that has version number of format less than 9.
And version 9 or upper versions will be treated as it is,
without converting, except compressibility change.

A reason of the changing is convenient for my algorithm, it inflates a file once.
But this point does not become a problem.

# CONSTRUCTOR

The constructor new() receives hash reference as an option. 

    my $fc = SWF::ForcibleConverter->new({
                buffer_size => 4096,
                });

The option has following key that is available.

## buffer\_size

Buffer size (bytes) when reading input data.

At least 4096 is required, or croak.

Default is 4096.

# METHOD

On the following explanation,
$input or $output are file path or opened IO object.

Both are omissible.
In that case, it uses STDIN or STDOUT.

As follows, this is convenient because of pipe processing. 

    $ cat in.swf | perl -MSWF::ForcibleConverter -e \
        'SWF::ForcibleConverter->new->convert9' > out.swf

Note that when using STDIO, uncompress() or convert9\*() can be called only once.

## buffer\_size(\[$num\])

This is accessor. When $num is given, it sets the member directly, without validation.
Regularly, please use \[get|set\]\_buffer\_size methods.

## get\_buffer\_size

Get buffer size.

## set\_buffer\_size($num)

Set buffer size.

At least 4096 is required, or croak.

## version($input)

Get version number of SWF file.

## is\_compressed($input)

Return true if $input is compressed.

## uncompress($input, $output)

Convert $input SWF into uncompressed $output SWF.

This method does not change version format,
simply outputs with uncompressing.

## convert9($input, $output)

    my $input   = "/path/to/original.swf";
    my $output  = "converted.swf";
    my $bytes   = $fc->convert9($input, $output);

Convert $input SWF into $output SWF with changing version 9 format forcibly.
And it returns size of $output.

Note that if the $input is compressed format, that is known as CWS,
$output will be CWS as well.
The another case is uncompressed, as FWS.
You can call convert9\_compress() or convert9\_uncompress() instead.

## convert9\_compress($input, $output)

convert9\_compress() is the same as convert9() 
except $output is always compressed (that is CWS).

## convert9\_uncompress($input, $output)

convert9\_uncompress() is the same as convert9() 
except $output is always uncompressed (that is FWS).

# REPOSITORY

SWF::ForcibleConverter is hosted on github https://github.com/hiroaki/SWF-ForcibleConverter

# AUTHOR

WATANABE Hiroaki <hwat@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

SWF::ForcibleConverter was prepared with reference to "ForcibleLoader"
that is produced by Spark project with the kind of respect:

[http://www.libspark.org/wiki/yossy/ForcibleLoader](http://www.libspark.org/wiki/yossy/ForcibleLoader)
