#!/usr/bin/perl
package IkiWiki::Plugin::format;

use warnings;
use strict;
use IkiWiki 3.00;

sub import {
	hook(type => "preprocess", id => "format", call => \&preprocess);
	hook(type => "getsetup",   id => "format", call => \&getsetup);
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => undef,
			section => "widget",
		},
}

sub preprocess (@) {
	# This plugin uses key-value pairs and single arguments which must
	# have their order maintained.  All parameters are put into the
	# %params hash and then we build the @args list by removing all
	# of the known key/value keys and ordering the remaining keys
	# in the order they were presented.
	my %params=@_;
	my %kv=@_;
	delete $kv{linenumbers};
	delete $kv{numberwidth};
	delete $kv{page};
	delete $kv{destpage};
	delete $kv{preview};
	my @args=();
	foreach (@_) {
		if (defined $kv{$_}) {
			push @args, $_;
		}
	}
	my ($format, $content) = @args;
	my $text=IkiWiki::preprocess($params{page}, $params{destpage}, $content);

	if (! defined $format || ! defined $text) {
		error(gettext("must specify format and text"));
	}
		
	# Other plugins can register htmlizeformat hooks to add support
	# for page types not suitable for htmlize, or that need special
	# processing when included via format. Try them until one succeeds.
	my $ret;
	IkiWiki::run_hooks(htmlizeformat => sub {
		$ret=shift->($format, $text, \%params)
			unless defined $ret;
	});

	if (defined $ret) {
		return $ret;
	}
	elsif (exists $IkiWiki::hooks{htmlize}{$format}) {
		return IkiWiki::htmlize($params{page}, $params{destpage},
		                        $format, $text);
	}
	else {
		error(sprintf(gettext("unsupported page format %s"), $format));
	}
}

1
