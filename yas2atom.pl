#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use v5.24;
use utf8;
$| = 1;

use feature   qw< say unicode_strings >;
use warnings  qw< FATAL utf8 >;
use open      qw< :std :utf8 >;

use File::Basename qw< basename >;
use File::Spec::Functions;
use Getopt::Long;

END { close STDOUT }


# Quote a string using the most appropriate quote-type
sub quote {
	my ($input) = shift;
	if($input =~ m/'/ and $input =~ m/"/){
		$input =~ s/"/\\"/g;
		return qq|"${input}"|;
	}
	if($input =~ m/"/){
		return qq|'${input}'|;
	}
	return qq|"${input}"|;
}

# Enclose a CSON key in quotes if needed
sub quoteKey {
	my ($input) = shift;
	return $input =~ m/[-.,#\@'"`:<>^\s\\+*\/(){}\[\]]/
		? quote($input)
		: $input;
}

# Enclose a value in quotes, or triple-quotes if input:
# - Contains (non-trailing) newlines
# - Doesn't have leading spaces (avoid mixing with tabs)
sub quoteValue {
	my ($input) = shift;
	
	# Triple-quote?
	($_ = $input) =~ s/\n+$//;
	if((scalar split /\n/) > 1 && !m/\n /){
		$_ = "\n${input}";
		s/\n(\n*)\Z/"\n" . ("\\n" x length $1)/e;
		s/"""/\\$&/g;
		s/^/\t/gm;
		return qq|"""$_\n"""|;
	}
	
	# Double or single-quote
	else{
		$input =~ s/\n/\\n/g;
		$input =~ s/\t/\\t/g;
		return quote $input;
	}
}


my %snippets = ();
my %labels = ();

$/ = undef;
while(<>){
	my ($header, $body) = m/\A(.+)\n# --\n(.+)\z/ms;
	my %attr = ($header =~ m/^#\h*([^\s:]+):\h*(.+)$/gm);
	
	# Missing "atom-selector" fields indicate a snippet
	# that we're not supposed to convert.
	next unless defined $attr{"atom-selector"};
	
	# Skip command-type snippets
	next if defined $attr{"type"} and "command" eq $attr{"type"};
	
	# Format body string
	$body =~ s/\\(?=`)//g;                  # Unescape backticks
	$body =~ s/\\\$(?!{?[0-9]|>)/\$/g;      # Unescape dollar signs
	$body =~ s/`\(\)`\Z//;                  # Prune trailing newline hack
	$body =~ s/\\/\\\\/g;                   # Double-escape every backslash
	
	# Convert trailing newlines to `\n`
	$body =~ s/\n(\n*)\Z/"\n" . ("\\n" x length $1)/e;
	
	# Unravel header fields
	my $sel   = $attr{"atom-selector"};
	my $key   = $attr{"key"}  || ($ARGV =~ s/\.yasnippet$//);
	my $name  = $attr{"name"} || $key;
	my %snip  = (prefix => $key, body => $body);
	
	# Optional snippet keys
	foreach my $extraAttr (
		# Used by YASnippets
		"group",
		
		# Used by us
		"atom-selector-label",
		
		# Used by `autocomplete-plus'
		"atom-left-label",
		"atom-left-label-html",
		"atom-right-label-html",
		"atom-description",
		"atom-description-more-url",
	){
		next unless defined $attr{$extraAttr};
		$_ = $extraAttr;
		s/^atom-//;           # Strip leading "atom-"
		s/-(\w)/\U$1/g;       # "kebab-case" -> "camelCase"
		s/(Url|Html)$/\U$1/g; # Fix capitalisation of acronyms
		$snip{$_} = $attr{$extraAttr};
	}
	
	unless(defined $snippets{$sel}){
		$snippets{$sel} = {};
		$snippets{$sel}->{groups} = {};
		$snippets{$sel}->{defs} = {};
	}
	
	# Resolve group attribute, if present
	my $group = $attr{"group"} || "General";
	unless(defined $snippets{$sel}->{groups}{$group}){
		$snippets{$sel}->{groups}{$group} = [];
	}
	
	# Resolve human-readable label for selector
	if(defined $snip{selectorLabel}){
		$labels{$sel} = $snip{selectorLabel};
	}
	
	$snippets{$sel}->{defs}{$name} = \%snip;
	push @{%{$snippets{$sel}->{groups}}{$group}}, $name;
}


# Strip pointless TextMate prefixes from each key
my %shortKeys = map {
	(my $key = $_) =~ s/^\.(?:source|text)\.//i;
	$key => $_;
} keys(%snippets);

# Sort keys
my @sortedKeys = sort {
	my $aIsList = $a =~ m/,/;
	my $bIsList = $b =~ m/,/;
	
	# Move grouped selectors to the end of the list
	if    ($aIsList && !$bIsList) {  1 }
	elsif ($bIsList && !$aIsList) { -1 }
	
	# Otherwise, stick to alphabetical order
	else {$a cmp $b}
} keys %shortKeys;


# Start generating some output
for(@sortedKeys){
	my $selectorName = $shortKeys{$_};
	my $selectorHash = $snippets{$selectorName};
	my %groups       = %{$selectorHash->{groups}};
	my %defs         = %{$selectorHash->{defs}};
	
	# Alphabetise group names, ignoring "General"
	my @sortedGroupKeys = sort {
		if    ($a eq "General") { -1 }
		elsif ($b eq "General") {  1 }
		else  {$a cmp $b}
	} keys %groups;
	
	# Emit selector title, if we have one
	if(defined $labels{$selectorName}){
		print "\n" unless $selectorName eq "*";
		say "# $labels{$selectorName}";
	}
	
	# Emit selector key
	say quoteKey($selectorName) . ":";
	
	# Print each snippet referenced by each group name
	for my $key (@sortedGroupKeys){
		
		# Insert a comment for readability
		unless($key eq "General"){
			# Separate named groups with an extra blank line
			print "\n" unless $key eq $sortedGroupKeys[0];
			say "\t# $key";
		}
		
		for(@{$groups{$key}}){
			my %snippet = %{$defs{$_}};
			say "\t" . quoteKey($_) . ":";
			
			my @attrLines = ();
			my @attrNames = (
				"prefix",
				"body",
				"leftLabel",
				"leftLabelHTML",
				"rightLabelHTML",
				"description",
				"descriptionMoreURL",
			);
			
			# If multiline, place the `body` key last to keep
			# the remaining (single-line) properties visible.
			if($snippet{body} =~ m/\n/){
				splice @attrNames, 1, 1;
				push @attrNames, "body";
			}
			
			for(@attrNames){
				next unless defined $snippet{$_};
				my $line = quoteKey($_) . ": ";
				$line .= quoteValue $snippet{$_};
				push @attrLines, $line;
			}
			
			# Indent and emit each attribute
			my $attr = join "\n", @attrLines;
			$attr =~ s/^/\t\t/gm;
			say "$attr\n";
		}
	}
}

__END__

=head1 SYNOPSIS

B<yas2atom.pl> [I<...files>]

=head1 DESCRIPTION

Compile a list of C<.yasnippet> files into an Atom-compatible CSON file.

=head1 EXAMPLES

Pretty much how you'd expect:

	./yas2atom.pl snippets/*/{**/*,/*}.yasnippet > snippets.cson

=head1 AUTHOR

Copyright E<copy> 2018, Alhadis E<lt>I<gardnerjohng@gmail.com>E<gt>.

=cut
