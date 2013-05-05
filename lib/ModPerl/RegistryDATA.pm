# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
package ModPerl::RegistryDATA;

use strict;
use warnings FATAL => 'all';

#use Apache2::RequestUtil ();
use File::Basename ();

use constant D_NONE    => 0;
use constant D_ERROR   => 1;
use constant D_WARN    => 2;
use constant D_COMPILE => 4;
use constant D_NOISE   => 8;

use constant DEBUG => 0;

# we try to develop so we reload ourselves without die'ing on the warning
no warnings qw(redefine); # XXX, this should go away in production!

#our $VERSION = '1.99';
our $VERSION = '0.01';

use base qw(ModPerl::RegistryCooker);

sub handler : method {
    my $class = (@_ >= 2) ? shift : __PACKAGE__;
    my $r = shift;
    return $class->new($r)->default_handler();
}

my $parent = 'ModPerl::RegistryCooker';
# the following code:
# - specifies package's behavior different from default of $parent class
# - speeds things up by shortcutting @ISA search, so even if the
#   default is used we still use the alias
my %aliases = (
    new             => 'new',
    init            => 'init',
    #default_handler => 'default_handler',
    run             => 'run',
    can_compile     => 'can_compile',
    make_namespace  => 'make_namespace',
    namespace_root  => 'namespace_root',
    namespace_from  => 'namespace_from_filename',
    is_cached       => 'is_cached',
    should_compile  => 'should_compile_if_modified',
    flush_namespace => 'NOP',
    cache_table     => 'cache_table_common',
    cache_it        => 'cache_it',
    read_script     => 'read_script',
    shebang_to_perl => 'shebang_to_perl',
    get_script_name => 'get_script_name',
    chdir_file      => 'NOP',
    get_mark_line   => 'get_mark_line',
    compile         => 'compile',
    error_check     => 'error_check',
    #strip_end_data_segment             => 'strip_end_data_segment',
    #convert_script_to_compiled_handler => 'convert_script_to_compiled_handler',
);

# in this module, all the methods are inherited from the same parent
# class, so we fixup aliases instead of using the source package in
# first place.
$aliases{$_} = $parent . "::" . $aliases{$_} for keys %aliases;

__PACKAGE__->install_aliases(\%aliases);

# Note that you don't have to do the aliases if you use defaults, it
# just speeds things up the first time the sub runs, after that
# methods are cached.
#
# But it's still handy, since you explicitly specify which subs from
# the parent package you are using
#

# META: if the ISA search results are cached on the first lookup, may
# be we need to alias only those methods that override the defaults?

sub strip_end_data_segment {
    my $self = shift;
    ${$self->{CODE}} =~ s/^__(END|DATA)__(.*)//ms;
    my ($end_or_data, $data_section) = ($1, $2);

    return if !$end_or_data;

    # stash strings to package global variable.
    my $package = $self->{PACKAGE};
    {
        no strict 'refs';
        ${"$package\::DATA"} = $data_section;
    }
}

sub convert_script_to_compiled_handler {
    my $self = shift;

    my $rc = Apache2::Const::OK;

    $self->debug("Adding package $self->{PACKAGE}") if DEBUG & D_NOISE;

    # get the script's source
    $rc = $self->read_script;
    return $rc unless $rc == Apache2::Const::OK;

    # convert the shebang line opts into perl code
    my $shebang = $self->shebang_to_perl;

    # mod_cgi compat, should compile the code while in its dir, so
    # relative require/open will work.
    $self->chdir_file;

#    undef &{"$self->{PACKAGE}\::handler"}; unless DEBUG & D_NOISE; #avoid warnings
#    $self->{PACKAGE}->can('undef_functions') && $self->{PACKAGE}->undef_functions;

    my $line = $self->get_mark_line;

    $self->strip_end_data_segment;

    # see: https://gist.github.com/xtetsuji/5022763
    # see: https://gist.github.com/xtetsuji/3825975
    # Is this a persistent or per-request exec?
    my $data_section = do {
        no strict 'refs';
        ${"$self->{PACKAGE}\::DATA"};
    };
    my $data_localize_line = '';
    my $data_install_line = '';
    my $data_seek_rewind_line = '';
    if ( $data_section ) {
        # DATA is internal package local.

        $data_localize_line = "local *DATA;\n";

        $data_install_line = sprintf <<'END_SECTION', $self->{PACKAGE};
{ no strict 'refs'; open \*DATA, '<', \${"%s::DATA"}; }
END_SECTION

        # scalar reference fh seek is ok.
        $data_seek_rewind_line = qq(\n;\nseek(*DATA, 0, 0);\n);;
    }

    # handle the non-parsed handlers ala mod_cgi (though mod_cgi does
    # some tricks removing the header_out and other filters, here we
    # just call assbackwards which has the same effect).
    my $base = File::Basename::basename($self->{FILENAME});
    my $nph = substr($base, 0, 4) eq 'nph-' ? '$_[0]->assbackwards(1);' : "";
    my $script_name = $self->get_script_name || $0;

    my $eval = join '',
                    'package ',
                    $self->{PACKAGE}, ";",
                    $data_localize_line,
                    "sub handler {",
                    $data_install_line, # local'lize of *DATA.
                    "local \$0 = '$script_name';",
                    $nph,
                    $shebang,
                    $line,
                    ${ $self->{CODE} },
                    # last line comment without newline?
                    # in $data_seek_rewind_line
                    $data_seek_rewind_line, # seek rewind *DATA
                    "\n}";

#     if ( open my $fh, '>', '/tmp/registry-data.txt' ) {
#         # for debug
#         print {$fh} "eval script is:\n";
#         print {$fh} $eval;
#     }

    $rc = $self->compile(\$eval);
    return $rc unless $rc == Apache2::Const::OK;
    $self->debug(qq{compiled package \"$self->{PACKAGE}\"}) if DEBUG & D_NOISE;

    $self->chdir_file(Apache2::ServerUtil::server_root());

#    if(my $opt = $r->dir_config("PerlRunOnce")) {
#        $r->child_terminate if lc($opt) eq "on";
#    }

    $self->cache_it;

    return $rc;
}


1;
__END__

=head1 NAME

ModPerl::RegistryDATA - Run unaltered CGI scripts persistently under mod_perl

=head1 Synopsis

  # httpd.conf
  PerlModule ModPerl::RegistryDATA
  Alias /perl/ /home/httpd/perl/
  <Location /perl>
      SetHandler perl-script
      PerlResponseHandler ModPerl::RegistryDATA
      #PerlOptions +ParseHeaders
      #PerlOptions -GlobalRequest
      Options +ExecCGI
  </Location>

=head1 Description

B<THIS MODULE IS ALPHA VERSION. IF YOU USE IT, BE CAREFUL!>

This modules is compatible of L<ModPerl::Registry>.

But L<ModPerl::Registry> trashes "__DATA__ section".
This module L<ModPerl::RegistryDATA> is insert "__DATA__ section"
to DATA filehandle.

=head1 Authors

OGATA Tetsuji E<lt>tetsuji.ogata {at} gmail.comE<gt>

=head1 See Also

L<ModPerl::Registry>

=cut
