use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'SWF::ForcibleConverter',
    'VERSION_FROM'  => 'lib/SWF/ForcibleConverter.pm', # finds $VERSION
    'PREREQ_PM'     => {
        Test::More              => '0.32',
        IO::File                => '0',
        IO::Handle              => '0',
        IO::Uncompress::Inflate => '0',
        IO::Compress::Deflate   => '0',
    },
);
