# Miscellaneous utility functions for my LDAP scripts.

package Nullroute::LDAP;
use base "Exporter";
use Nullroute::Lib;

@EXPORT = qw(
	ldap_check
);

sub ldap_format_error {
	my ($res, $dn) = @_;

	my $text = "LDAP error: ".$res->error;
	utf8::decode($text);
	$text .= "\n * error code: ".$res->error_name if $::debug;
	$text .= "\n * failed entry: ".$dn            if $dn;
	$text .= "\n * matched entry: ".$res->dn      if $res->dn;
	return $text;
}

sub ldap_check {
	my ($res, $dn, $ignore) = @_;

	if (!$res->is_error) {
		return;
	}

	if (ref $ignore eq 'ARRAY' &&
	    grep {$res->error_name eq $_} @$ignore) {
		_debug("ignoring ".$res->error_name.($dn ? " for $dn" : ""));
		return;
	}

	my $text = ldap_format_error($res, $dn);
	_die($text);
}

1;
