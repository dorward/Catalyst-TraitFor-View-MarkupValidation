package Catalyst::TraitFor::View::MarkupValidation;

use Moose::Role;
use Template;
use WebService::Validator::HTML::W3C;
use Syntax::Highlight::Engine::Kate;

use namespace::autoclean;

our $VERSION = '0.001';

after process => sub {
    my ( $self, $c ) = @_;

# Only try to validate when in debug mode, and only handle HTML documents (unless overridden (TODO!))
    if ( ( !$c->debug )
        || $c->res->header('Content-type') !~
        m{(text/html|application/xhtml+xml)}mxs )
    {
        print STDERR "\n\nNot validating! " . $c->debug . "\n\n";
        return;
    }
    
    print STDERR "\n\nValidating!\n\n";

    my $validator_uri = $c->config->{MARKUP_VALIDATOR_URI};
    if (!$validator_uri) {
        warn "MARKUP_VALIDATOR_URI has not been configured. Will skip Catalyst::TraitFor::View::MarkupValidation";
        return;
    }

    my $v = WebService::Validator::HTML::W3C->new(
        detailed      => 1,
        validator_uri => $validator_uri
    );

    # Perform the validation
    my $source = $c->res->body;
    $v->validate( string => $source );

    # Don't switch to error reporting unless there are errors
    if ( $v->is_valid ) {
        warn 'is valid';
        return;
    }

    my $template_html = $c->config->{MARKUP_VALIDATOR_REPORT_TEMPLATE} || \*DATA;

    my $errors = $v->errors();
    my @report = ();
    foreach my $err ( @{$errors} ) {
        push @report, [ $err->line, $err->col, $err->msg ];
    }

    my $hl = Syntax::Highlight::Engine::Kate->new(
        language      => 'HTML',
        substitutions => {
            q[<] => q[&lt;],
            q[>] => q[&gt;],
            q[&] => q[&amp;],
        },
        format_table => {
            # convert Kate's internal representation into
            # <code class="<internal name>"> value </code>
            map { $_ => [ qq{<code class="$_">}, '</code>' ] }
              qw/Alert BaseN BString Char Comment DataType
              DecVal Error Float Function IString Keyword
              Normal Operator Others RegionMarker Reserved
              String Variable Warning/,
        },
    );

    my $highlighted_source = $hl->highlightText($source);

    my $data_for_tt = {
        source => $highlighted_source,
        report => \@report
    };
    my $template = Template->new();
    my $output;
    $template->process( \$template_html, $data_for_tt, \$output );
    #$template->process(\*DATA, $data_for_tt, \$output ) or die($!);
    $c->res->body($output);
};

1;

=head1 NAME

Catalyst::TraitFor::View::MarkupValidation - Validates output and replaces it with an error report if not OK

=head1 SYNOPSIS

    package Catalyst::View::Validation;

    use Moose;
    use namespace::autoclean;

    extends qw/Catalyst::View::TT/;
    with qw/Catalyst::TraitFor::View::MarkupValidation/;

    1;

=head1 DESCRIPTION

This is a Role which which takes generated content that is ready for output and
validates it. If there are errors it replaces the default output with an
error report.

=head1 CAVEATS

This is useful when you're developing your application, as it will identify
validity errors in the markup. In production, however, the performance cost is
likely to be too high, and throwing errors at users that browsers could
probably recover from is unfriendly.

=head1 METHOD MODIFIERS

=head2 after process

Validates document and (in event of an error) replaces it with an error report.

=head1 TODO

=over

=item Make document types that get validated configurable

=item Add line numbering to output

=item Hyperlink from error to source

=back

=head1 BUGS AND LIMITATIONS

Please report any you find using RT.

=over

=item If URI to validation service is incorrect, shows error report w/ 0 errors.

=back

=head1 AUTHOR

=over

=item David Dorward (dorward) C<< <david@dorward.me.uk> >>

=back

=head1 CONTRIBUTORS

=over

=item Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=back

=head1 LICENSE AND COPYRIGHT

This module itself is copyright (c) 2009 David Dorward and is licensed under the
same terms as Perl itself.

=cut

__DATA__
<!doctype html>
<html>
    <head>
        <title>Error report</title>
        <style type="text/css">
        .DataType { color: red; }
        .Normal { color: black; }
        .Keyword { font-weight: bold; }
        .String { font-style: italic; }
        .Others { color: blue; }
        </style>
    </head>
    <body>
        <h1>Error report</h1>
        
        <table>
        <tr>
            <th scope="col">Line</th>
            <th scope="col">Col</th>
            <th scope="col">Error</th>
        </tr>
        [% FOREACH error = report %]
            <tr>
            <td>[% error.0 %]</td>
            <td>[% error.1 %]</td>
            <td>[% error.2 %]</td>
        </tr>
        [% END %]
        </table>
        <pre>[% source  %]</pre>
    </body>
</html>
