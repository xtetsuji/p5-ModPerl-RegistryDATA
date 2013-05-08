use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('ModPerl::RegistryDATA');
    use_ok('ModPerl::RegistryPreforkDATA');
    use_ok('ModPerl::PerlRunDATA');
    use_ok('ModPerl::PerlRunPreforkDATA');
};
