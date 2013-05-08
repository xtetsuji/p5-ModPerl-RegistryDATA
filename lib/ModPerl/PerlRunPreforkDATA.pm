package ModPerl::PerlRunPreforkDATA;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

use base qw(ModPerl::PerlRunDATA);

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

ModPerl::PerlRunPrefork - Run unaltered CGI scripts under mod_perl

=head1 Synopsis

  # httpd.conf
  PerlModule ModPerl::PerlRunPreforkDATA
  Alias /perl-run/ /home/httpd/perl/
  <Location /perl-run>
      SetHandler perl-script
      PerlResponseHandler ModPerl::PerlRunPreforkDATA
      PerlOptions +ParseHeaders
      Options +ExecCGI
  </Location>

=head1 Description

B<THIS MODULE IS ALPHA VERSION. IF YOU USE IT, BE CAREFUL!>

This modules is compatible of L<ModPerl::PerlRunPrefork>.

But L<ModPerl::PerlRunPrefork> trashes "__DATA__ section".
This module L<ModPerl::PerlRunPreforkDATA> is insert "__DATA__ section"
to DATA filehandle.

=head1 Authors

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

=head1 See Also

L<ModPerl::PerlRunPrefork>

=cut
