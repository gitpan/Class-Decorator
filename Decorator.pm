package Class::Decorator;

use vars qw ( $VERSION $METH );

$VERSION = '0.01';
my $auto_1;
my $auto_2;
my $auto_3;

sub new
{
    my ($caller, %args) = @_;
    my $class = ref($caller) || $caller;
    bless {
	pre  => $args{pre}  || sub {}, # performed before dispatched method
	post => $args{post} || sub {}, # performed after dispatched method
	obj  => $args{obj}  || die("decorator must be constructed with a component to be decorated")
	}, $class;
}

sub DESTROY {}

sub AUTOLOAD
{
    my ($self, @args) = @_;
    $AUTOLOAD =~ /.+::(.+)$/;
    $METH = $1;
    my $auto = '';
    $auto .= $auto_1;
    $auto .= '        @return_values = $decorator->{obj}->'.$METH.'(@args);';
    $auto .= $auto_2;
    $auto .= '        $return_value = $decorator->{obj}->'.$METH.'(@args);';
    $auto .= $auto_3;
    eval($auto);
    *{$AUTOLOAD} = $auto;
    if (wantarray) {
	my @return_values = $auto->($self, @args);
	return @return_values;
    } else {
	my $return_value = $auto->($self, @args);
	return $return_value;
    }
}

$auto_1 = <<'EO1';
$auto = sub {
    my ($decorator, @args) = @_;
    $AUTOLOAD =~ /.+::(.+)$/;
    $METH = $1;
    if (wantarray) {
        my @null;
        my @return_values;
        @null = $decorator->{pre}->(@args);
EO1

$auto_2 = <<'EO2';

        @null = $decorator->{post}->(@args);
        return @return_values;
    } else {
        my $return_value;
        $decorator->{pre}->(@args);
EO2

$auto_3 = <<'EO3';

        $decorator->{post}->(@args);
        return $return_value;
    }
}
EO3

1;
__END__

=head1 NAME

Class::Decorator - Attach additional responsibilites to an object. A generic wrapper.

=head1 SYNOPSIS

  use Class::Decorator;
  my $object = Foo::Bar->new(); # the object to be decorated
  my $logger = Class::Decorator->new(
    obj  => $object,
    pre  => sub{print "before method\n"},
    post => sub{print "after method\n"}
  );
  $logger->some_method_call(@args);

=head1 DESCRIPTION

Decorator objects allow additional functionality to be dynamically added to objects. In this implementation, the user can supply two subroutine references (pre and post) to be performed before (pre) and after (post) any method call to an object (obj).

Both 'pre' and 'post' arguments to the contructor are optional. The 'obj' argument is mandated.

The pre and post methods receive the arguments that are supplied to the decorated method, and therefore Class::Decorator can be used effectively in debugging or logging applications. Return values from pre and post are ignored.

Decorator objects can themselves be decorated. Therefore, it is possible to have an object that performs work, which is decorated by a logging decorator, which in turn is decorated by a debugging decorator.

=head2 VARIABLES

$Class::Decorator::METH is set to the name of the current method being called. So, a simple debugging script might decorate an object like this:

  my $debugger = Class::Decorator->new(
    obj  => $object,
    pre  => sub{print "entering $Class::Decorator::METH\n"},
    post => sub{print "leaving $Class::Decorator::METH\n"}
  );

Arguments are supplied to the pre- and post- methods, but return values are ignored. Note that the first argument in the list of arguments supplied to pre- and post- is the decorated object (i.e. the second argument $_[1] is the start of the true list of arguments).

=head2 WARNING

The DESTROY method is currently disabled. This is only important to those users who have implemented DESTROY for cleaning up circular references or for some other reason.

=head1 SEE ALSO

L<Class::Null> - an alternative to wrapping an object is providing an object that performs nothing (i.e. removing functionality when it isn't needed, rather than adding it when required).

=head1 AUTHOR

Nigel Wetters, E<lt>nwetters@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Nigel Wetters, E<lt>nwetters@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
