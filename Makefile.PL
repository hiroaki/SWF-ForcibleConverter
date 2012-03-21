use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'SWF::ForcibleConverter',
    'VERSION_FROM' => 'lib/SWF/ForcibleConverter.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
