#!/usr/bin/perl

# this program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;

use Getopt::Std;
use Net::HTTP;
our $VERSION = '2013-06-26';

my $langs = 'cz|en|ge|fr|it|la|ru|sp|eo';

sub help {

    my $out = \*STDERR;
    my $ret = 1;
    if ( !$_[0] ) {
        $out = \*STDOUT;
        $ret = 0;
    }

    print {$out}
"slovnik.cz CLI původně napsal David Watzke <slovnik\@watzke.cz> http://www.watzke.cz/cs/\n"
      . "Pouziti: slovnik [prepinace] [retezec]\n\n";
    print {$out} "Chyba: $_[0]\n\n" if $_[0];
    print {$out} "Prepinace:\n"
      . "\t-f[$langs]\tvstupni jazyk\n"
      . "\t-t[$langs]\tvystupni jazyk\n"
      . "\t-r[5-50]\t\t\tpocet vysledku, vychozi 10\n\n"
      . "Poznamky:\n"
      . " Bud vstupni nebo vystupni jazyk musi byt cestina (cz), takze\n"
      . " vychozi je preklad cz->en a zadate-li -f ruzne od cz, tak [f]->cz.\n"

      . " Chyby hlaste na vyse uvedeny e-mail.\n";

    exit $ret;
}

$ARGV[0] or help();

my %opts;
getopt( 'f:t:r:-', \%opts );

$ARGV[0] or help('Nebyl zadan zadny retezec k prelozeni.');

# silene podmineny vychozi hodnoty :-)
# ((not $opts{t} and not $opts{f}) or
# ($opts{f} and $opts{f} eq "cz")) and $opts{t} = "en";
# $opts{f} or $opts{f} = "cz";
# $opts{t} or $opts{t} = "cz";
# $opts{f} ne $opts{t} or &Help("Vstupni a vystupni jazyk nesmi byt stejny.");
# $opts{r} or $opts{r} = 10;
# #print "-f $opts{f} -t $opts{t}\n";

$opts{t} //= 'cz';
$opts{f} //= 'cz' eq $opts{t} ? 'en' : 'cz';
$opts{r} //= 10;
$opts{t} eq $opts{f} and help('Vstupni a vystupni jazyk nesmi byt stejny.');

my $dict = $opts{t} eq 'cz' ? "$opts{f}$opts{t}" : "$opts{t}$opts{f}";

if ( "$dict" =~ /^(?:$langs){2}$/ ) {
    "$dict" =~ /(?:^cz|cz$)/
      or help('Vstupni nebo vystupni jazyk musi byt cestina.');
}
else {
    help("slovnik.cz nepodporuje preklad z '$opts{f}' do '$opts{t}'.");
}

$opts{f} =~ s/cz/cz_d/;
$dict .= ".$opts{f}";

my $http = Net::HTTP->new( Host => 'www.slovnik.cz' ) || die $@;
my $string = $ARGV[0];
shift;
foreach (@ARGV) {
    $string .= " $_";
}

$string =~ s/ /%20/g;
$http->write_request(
    GET => "/bin/mld.fpl?vcb=$string&dictdir=$dict&lines=$opts{r}" );
my ( $status, $mess, %headers ) = $http->read_response_headers;
my $html;
my $buf;

while ( my $n = $http->read_entity_body( $buf, 1024 ) ) {
    defined $n or help("Chyba pri cteni HTML: $!");
    $html .= $buf;
}

# ja vim, ja vim, ale s HTML::Parser jeste neumim...
foreach ( grep { /"pair"/ } split /\n/, $html ) {
    s/(?:^\s*)|(?:<[^>]+>)//g;
    print "$_\n";
}
