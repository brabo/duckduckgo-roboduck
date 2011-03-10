package RoboDuck;

use Moses;
use namespace::autoclean;

our $VERSION ||= '0.0development';

use WWW::DuckDuckGo;

server 'irc.freenode.net';
nickname 'RoboDuck';
channels '#duckduckgo';

has ddg => (
	isa => 'WWW::DuckDuckGo',
	is => 'rw',
	default => sub { WWW::DuckDuckGo->new( http_agent_name => __PACKAGE__.'/'.$VERSION ) },
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

__PACKAGE__->run unless caller;

1;
