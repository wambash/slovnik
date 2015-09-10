#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Readonly;
use HTML::TreeBuilder;
use URI;

binmode STDOUT, ':encoding(UTF-8)';

our $VERSION = '2015-09-01';

Readonly my @SUPORTED_DICTS => qw{
  encz.en encz.cz gecz.ge
  gecz.cz frcz.fr frcz.cz
  itcz.it itcz.cz spcz.sp
  spcz.cz rucz.ru rucz.cz
  lacz.la lacz.cz eocz.eo
  eocz.cz eosk.eo eosk.sk
  plcz.pl plcz.cz
};
Readonly my @LANGS = qw{cz en ge fr it la ru sp eo pl};
Readonly my $DEFAULT_SHOWED_RESULTS => 10;

sub make_dictdir {
    my $from = shift;
    my $to   = shift;
    $from //= 'cz' eq $to ? 'en' : 'cz';

    $from eq $to
      and pod2usage('Vstupní a výstupní jazyk nesmí být stejný.');
    {
        no warnings 'experimental::smartmatch';
        $from ~~ @LANGS and $to ~~ @LANGS
          or pod2usage("slovnik.cz nepodporuje překlad z '$from' do '$to'.");
    }
    ( $from eq 'cz' or $to eq 'cz' )
      or pod2usage('Vstupní nebo výstupní jazyk musí být čeština.');

    my $dictdir = $to eq 'cz' ? "$from$to" : "$to$from";
    $dictdir .= ".$from";
    return $dictdir;
}

my $from;
my $to = 'cz';
my $dictdir;
my $results = $DEFAULT_SHOWED_RESULTS;
my $man     = 0;
my $help    = 0;

GetOptions(
    'from=s'          => \$from,
    'to=s'            => \$to,
    'dictdir=s'       => \$dictdir,
    'results|lines=i' => \$results,
    'help'            => \$help,
    'man'             => \$man,
);

$help and pod2usage( -exitval => 1, -verbose => 1 );
$man  and pod2usage( -exitval => 0, -verbose => 2 );

$ARGV[0]
  or pod2usage( -msg => 'Nebyl zadán žádný řetězec k přeložení.' );

$dictdir //= make_dictdir( $from, $to );

{
    no warnings 'experimental::smartmatch';
    $dictdir ~~ @SUPORTED_DICTS
      or pod2usage(
"Slovník $dictdir není podporován, musí být jeden z @SUPORTED_DICTS."
      );
}

my $slovnik_url = URI->new('http://www.slovnik.cz/');
$slovnik_url->path('bin/mld.fpl');
$slovnik_url->query_form(
    dictdir => $dictdir,
    vcb     => "@ARGV",
    lines   => $results,
);

my $html = HTML::TreeBuilder->new_from_url( $slovnik_url->as_string );

say join qq{\n}, map { $_->as_text } $html->look_down( 'class' => 'pair' );

__END__

=encoding utf-8

=head1 NAME

 slovnik.pl - cli pro slovnik.cz

=head1 USAGE

 slovnik.pl [-f cz|en|ge|fr|it|la|ru|sp|eo|pl] [-t cz|en|ge|fr|it|la|ru|sp|eo|pl] slovíčko
 slovnik.pl -d slovník.směrpřekladu slovíčko
 slovnik.pl -h
 slovnip.pl -m

=head1 REQUIRED ARGUMENTS

slovíčko - slovo nebo fráze k přeložení

=head1 OPTIONS

=over 4

=item B<-f[rom]> jazyk

vstupní jazyk  jeden z cz|en|ge|fr|it|la|ru|sp|eo|pl, výchozí cz (pokud je výstupní jazyk cz, tak je výchozí en)

=item B<-t[o]> jazyk

výstupní jazyk jeden z cz|en|ge|fr|it|la|ru|sp|eo|pl, výchozí cz
;
=item B<-r[esults]|-l[ines]> číslo

počet výsledků [5-25], výchozí 10

=item Poznámka

Buď vstupní nebo výstupní jazyk musí být čeština (cz).

=item B<-d[ictdir]> slovník.směrpřekladu

Slovník a směr překladu (z jazyka) musí nabývat jednu z následujících hodnot:
encz.en, encz.cz, gecz.ge, gecz.cz, frcz.fr, frcz.cz, itcz.it, itcz.cz, spcz.sp, spcz.cz, rucz.ru, rucz.cz, lacz.la, lacz.cz, eocz.eo, eocz.cz, eosk.eo, eosk.sk, plcz.pl, plcz.cz.

=item B<-h[elp]>

Zobrazí krátkou nápovědu.

=item B<-m[an]>

Zobrazí manuálovou stránku.

=back

=head1 DESCRIPTION

Neoficiální cli pro webové stránky slovnik.cz. Umožňuje pomocí příkazové řádky překládat slova (fráze) do a z češtiny.

=head1 DIAGNOSTICS

=head1 EXIT STATUS

 pokud vše proběhne v pořádku tak vrátí 0
 -h vrátí 1
 libovolná chyba vrátí 2

=head1 CONFIGURATION

=over 2

=item *
 Pro změnu podporovaných slovníků (parametr -d) změňte C<@SUPORTED_DICTS>

=item *
 Pro změnu podporovaných jazyků (-f,-t)  změňte C<@LANGS>

=item *
 Pro změnu počtu standardně zobrazovaných výsledků (-l|-r) změňte C<$DEFAULT_SHOWED_RESULTS>

=back

=head1 DEPENDENCIES

 L<Getopt::Long>
 L<Pod::Usage>
 L<Readonly>
 L<HTML::TreeBuilder>
 L<URI>


=head1 INCOMPATIBILITIES

Žádné nenahlášeny.

=head1 BUGS AND LIMITATIONS

Žádné chyby nejsou nahlášeny.

Chyby prosím nahlaste na L<https://github.com/wambash/slovnik/issues>.

=head1 AUTHOR

 Jan Krňávek <Jan.Krnavek@gmail.com>
 Původní slovnik.pl napsal David Watzke <slovnik@watzke.cz> http://www.watzke.cz/cs/

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.



=cut
