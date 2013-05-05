# -*- perl -*-

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'ModPerl::RegistryDATA',
    VERSION_FROM   => 'lib/ModPerl/RegistryDATA.pm',
    ABSTRACT_FROM  => 'lib/ModPerl/RegistryDATA.pm',
    AUTHOR         => 'OGATA Tetsuji <tetsuji.ogata at cpan.org>',
    PREREQ_PM      => {
        'ModPerl::RegistryCooker' => 0,
    },
    PMLIBDIRS      => ["lib"],
    META_MERGE     => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/xtetsuji/p5-ModPerl-RegistryDATA/issues',
            repository => 'git://github.com/xtetsuji/p5-ModPerl-RegistryDATA.git',
        },
    },
    LISENSE        => "perl",
    PL_FILES       => {},
    EXE_FILES      => [],
    dist           => {
        SUFFIX => 'gz',
        COMPRESS => 'gzip -9f',
    },
);

# TODO: Better ModPerl::MM than EUMM?
