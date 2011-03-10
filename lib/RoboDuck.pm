package RoboDuck;
# ABSTRACT: The IRC bot of the #duckduckgo Channel

sub POE::Kernel::USE_SIGCHLD () { 1 }

use Moses;
use namespace::autoclean;
use Cwd;

our $VERSION ||= '0.0development';

use WWW::DuckDuckGo;

with qw(
	MooseX::Daemonize
);

server $ENV{USER} eq 'roboduck' ? 'irc.freenode.net' : 'irc.perl.org';
nickname $ENV{USER} eq 'roboduck' ? 'RoboDuck' : 'RoboDuckDev';
channels '#duckduckgo';
username 'duckduckgo';

after start => sub {
	my $self = shift;
	return unless $self->is_daemon;
	# Required, elsewhere your POE goes nuts
	POE::Kernel->has_forked if !$self->foreground;
	POE::Kernel->run;
};

has ddg => (
	isa => 'WWW::DuckDuckGo',
	is => 'rw',
	traits => [ 'NoGetopt' ],
	lazy => 1,
	default => sub { WWW::DuckDuckGo->new( http_agent_name => __PACKAGE__.'/'.$VERSION ) },
);

has '+pidbase' => (
	default => sub { getcwd },
);

event irc_bot_addressed => sub {
	my ( $self, $nickstr, $channel, $msg ) = @_[ OBJECT, ARG0, ARG1, ARG2 ];
	my ( $nick ) = split /!/, $nickstr;
	$self->debug($nick.' told me "'.$msg.'" on '.$channel);
	my $reply;
	my $zci;
	if ($msg =~ /your order/i or $msg =~ /your rules/i) {
		$reply = "1. Serve the public trust, 2. Protect the innocent, 3. Uphold the law, 4. .... and dont track you! http://donttrack.us/";
	} elsif ($zci = $self->ddg->zci($msg)) {
		if ($zci->has_abstract) {
			$reply = $zci->abstract;
			$reply .= " (".$zci->abstract_source.")" if $zci->has_abstract_source;
			$reply .= " ".$zci->abstract_url if $zci->has_abstract_url;
		} elsif ($zci->has_answer) {
			$reply = $zci->answer;
			$reply .= " (".$zci->answer_type.")";
		} elsif ($zci->has_definition) {
			$reply = $zci->definition;
			$reply .= " (".$zci->definition_source.")" if $zci->has_definition_source;
			$reply .= " ".$zci->definition_url if $zci->has_definition_url;
		} else {
			$reply = "no clue...";
		}
	} else {
		$reply = '0 :(';
	}
	$self->privmsg( $channel => "$nick: ".$reply );
};

1;
