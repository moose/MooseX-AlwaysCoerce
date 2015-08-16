package MooseX::AlwaysCoerce;
# ABSTRACT: Automatically enable coercions for Moose attributes
# KEYWORDS: Moose extension type constraint coerce coercion

our $VERSION = '0.23';

use strict;
use warnings;

use namespace::autoclean 0.12;
use MooseX::ClassAttribute 0.24 ();
use Moose::Exporter;
use Moose::Util::MetaRole;

Moose::Exporter->setup_import_methods;

=pod

=for stopwords coercions

=head1 SYNOPSIS

    package MyClass;

    use Moose;
    use MooseX::AlwaysCoerce;
    use MyTypeLib 'SomeType';

    has foo => (is => 'rw', isa => SomeType); # coerce => 1 automatically added

    # same, MooseX::ClassAttribute is automatically applied
    class_has bar => (is => 'rw', isa => SomeType);

=head1 DESCRIPTION

Have you ever spent an hour or more trying to figure out "Hey, why did my
coercion not run?" only to find out that you forgot C<< coerce => 1 >> ?

Just load this module in your L<Moose> class and C<< coerce => 1 >> will be
enabled for every attribute and class attribute automatically.

Use C<< coerce => 0 >> to disable a coercion explicitly.

=cut

{
    package # hide from PAUSE
        MooseX::AlwaysCoerce::Role::Meta::Attribute;
    use namespace::autoclean;
    use Moose::Role;

    around should_coerce => sub {
        my $orig = shift;
        my $self = shift;

        my $current_val = $self->$orig(@_);

        return $current_val if defined $current_val;

        return 1 if $self->type_constraint && $self->type_constraint->has_coercion;
        return 0;
    };

    package # hide from PAUSE
        MooseX::AlwaysCoerce::Role::Meta::Class;
    use namespace::autoclean;
    use Moose::Role;
    use Moose::Util::TypeConstraints ();

    around add_class_attribute => sub {
        my $next = shift;
        my $self = shift;
        my ($what, %opts) = @_;

        if (exists $opts{isa}) {
            my $type = Moose::Util::TypeConstraints::find_or_parse_type_constraint($opts{isa});
            $opts{coerce} = 1 if not exists $opts{coerce} and $type->has_coercion;
        }

        $self->$next($what, %opts);
    };
}

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(

    install => [ qw(import unimport) ],

    class_metaroles => {
        attribute   => ['MooseX::AlwaysCoerce::Role::Meta::Attribute'],
        class       => ['MooseX::AlwaysCoerce::Role::Meta::Class'],
    },

    role_metaroles => {
        (Moose->VERSION >= 1.9900
            ? (applied_attribute => ['MooseX::AlwaysCoerce::Role::Meta::Attribute'])
            : ()),
        role                => ['MooseX::AlwaysCoerce::Role::Meta::Class'],
    }
);

sub init_meta {
    my ($class, %options) = @_;
    my $for_class = $options{for_class};

    MooseX::ClassAttribute->import({ into => $for_class });

    # call generated method to do the rest of the work.
    goto $init_meta;
}

1;
# vim:et sts=4 sw=4 tw=0:
__END__

=for Pod::Coverage
    init_meta

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-alwayscoerce at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-AlwaysCoerce>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find more information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-AlwaysCoerce>

=for stopwords AnnoCPAN

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-AlwaysCoerce>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-AlwaysCoerce>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-AlwaysCoerce/>

=back

=head1 ACKNOWLEDGEMENTS

My own stupidity, for inspiring me to write this module.

=for stopwords Rolsky

Dave Rolsky, for telling me how to do it the L<Moose> way.

=cut
