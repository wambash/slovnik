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

use Getopt::Long;
use Net::HTTP;
our $VERSION = '2015-09-01';

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

my $to='cz';
my $from;
my $results=10;

GetOptions(
    "from=s" => \$from,
    "to=s" => \$to,
    "results=i" => \$results,
);

$ARGV[0] or help('Nebyl zadan zadny retezec k prelozeni.');

$from //= 'cz' eq $to ? 'en' : 'cz';
$from eq $to  and help('Vstupni a vystupni jazyk nesmi byt stejny.');

my $dict = $to eq 'cz' ? "$from$to" : "$to$from";

if ( "$dict" =~ /^(?:$langs){2}$/ ) {
    "$dict" =~ /(?:^cz|cz$)/
      or help('Vstupni nebo vystupni jazyk musi byt cestina.');
}
else {
    help("slovnik.cz nepodporuje preklad z '$from' do '$to'.");
}

$from =~ s/cz/cz_d/;
$dict .= ".$from";

my $http = Net::HTTP->new( Host => 'www.slovnik.cz' ) or die $@;
my $string = join '%20', @ARGV;

$http->write_request(
    GET => "/bin/mld.fpl?vcb=$string&dictdir=$dict&lines=$results" );
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
