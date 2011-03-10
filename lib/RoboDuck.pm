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
	if (my $zci = $self->ddg->zci($msg)) {
		my $reply;
		if ($zci->has_abstract) {
			$reply = $zci->abstract;
		} elsif ($zci->has_answer) {
			$reply = $zci->answer;
		} elsif ($zci->has_definition) {
			$reply = $zci->definition;
		} else {
			$reply = "no clue...";
		}
		$self->privmsg( $channel => "$nick: ".$reply );
	} else {
		$self->privmsg( $channel => "$nick: 0 :(" );
	}
};

1;
