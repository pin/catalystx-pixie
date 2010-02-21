use strict;
use warnings;

use ExtUtils::MakeMaker;
#use File::ShareDir::Install;

#install_share 'xsl';

WriteMakefile(
    NAME                => 'CatalystX::Pixie',
    AUTHOR              => 'Dmitri Popov <operator@cv.dp-net.com>',
    VERSION_FROM        => 'lib/CatalystX/Pixie.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/Pixie.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Media::Bucket' => 0,
        'XML::LibXSLT' => 0,
        'File::ShareDir' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-Pixie-*' },
);
