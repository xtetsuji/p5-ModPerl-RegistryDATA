package ModPerl::RegistryPreforkDATA;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

use base qw(ModPerl::RegistryDATA);

if ($ENV{MOD_PERL}) {
    require Apache2::MPM;
    die "This package can't be used under threaded MPMs"
        if Apache2::MPM->is_threaded;
}

sub handler : method {
    my $class = (@_ >= 2) ? shift : __PACKAGE__;
    my $r = shift;
    return $class->new($r)->default_handler();
}

*chdir_file = \&ModPerl::RegistryCooker::chdir_file_normal;

1;
__END__

=head1 NAME

ModPerl::RegistryPreforkDATA - Can read __DATA__ section ModPerl::Registry* family.

=head1 Synopsis

  # httpd.conf
  PerlModule ModPerl::RegistryPreforkDATA
  Alias /perl-run/ /home/httpd/perl/
  <Location /perl-run>
      SetHandler perl-script
      PerlResponseHandler ModPerl::RegistryPreforkDATA
      PerlOptions +ParseHeaders
      Options +ExecCGI
  </Location>

=head1 Description

B<THIS MODULE IS ALPHA VERSION. IF YOU USE IT, BE CAREFUL!>

This modules is compatible of L<ModPerl::RegistryPrefork>.

But L<ModPerl::RegistryPrefork> trashes "__DATA__ section".
This module L<ModPerl::RegistryPreforkDATA> is insert "__DATA__ section"
to DATA filehandle.

=head1 Authors

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

=head1 See Also

L<ModPerl::RegistryPrefork>

=cut
