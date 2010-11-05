package App::gh::Command::All;
use utf8;
use warnings;
use strict;
use base qw(App::gh::Command);
use File::Path qw(mkpath);
use App::gh::Utils;
use LWP::Simple qw(get);
use JSON;

=head1 NAME

App::gh::Command::All - clone/update all repositories from one

=head1 DESCRIPTION

If you need a mirror of repos from one, you will need this command.

If repos exists, clone command will pull changes for these repos from remotes.

=head1 OPTIONS

Genernal Options:

    --prompt        
        prompt when cloning every repo.

    --into          
        a path for repos.

    --skip-exists, -s
        skip existed repos.

    --verbose

Clone URL format:

    --ssh

    --http

    --https

    --git

=cut

sub options { (
        "verbose" => "verbose",
        "prompt" => "prompt",
        "into=s" => "into",
        "s|skip-exists" => "skip_exists",

        "ssh" => "protocal_ssh",    # git@github.com:c9s/repo.git
        "http" => "protocal_http",  # http://github.com/c9s/repo.git
        "https" => "https",         # https://github.com/c9s/repo.git
        "git|ro"   => "git"         # git://github.com/c9s/repo.git
    ) }


sub run {
    my $self = shift;
    my $acc  = shift;

    $self->{into} ||= $acc;

    die 'Need account id.' unless $acc;

    _info "Getting repository list from github: $acc";

    my $data = api_request(  "repos/show/$acc" );
    return if @{ $data->{repositories} } == 0;

    if( $self->{into} ) {
        print STDERR "Cloning all repositories into @{[ $self->{into} ]}\n";
        mkpath [ $self->{into} ];
        chdir  $self->{into};
    }

    _info "Will clone repositories below:";
    print " " x 8 . join " " , map { $_->{name} } @{ $data->{repositories} };
    print "\n";

    if( $self->{prompt} ) {
        print "Clone them [Y/n] ? ";
        my $ans = <STDIN>;
        chomp( $ans );
        $ans ||= 'Y';
        return if( $ans =~ /n/ );
    }


    for my $repo ( @{ $data->{repositories} } ) {
        my $repo_name = $repo->{name};
        my $local_repo_name = $repo_name;
        $local_repo_name =~ s/\.git$//;

        if( $self->{prompt} ) {
            print "Clone $repo_name [Y/n] ? ";
            my $ans = <STDIN>;
            chomp( $ans );
            $ans ||= 'Y';
            next if( $ans =~ /n/ );
        }

        my $uri = $self->gen_uri( $acc, $repo_name );
        print $uri . "\n" if $self->{verbose};


        if( -e $local_repo_name ) {
            print("Found $local_repo_name, skipped.\n"),next if $self->{skip_exists};

            chdir $local_repo_name;
            print "Updating $local_repo_name from remotes ...\n";

            my $flags = qq();
            $flags .= qq{ -q } unless $self->{verbose};

            qx{ git pull $flags --rebase --all };

#             my @remotes = split /\n/,qx{git remote 2>&1 };
#             for my $r ( @remotes ) {
#                 print "  Updating [$r]  ";
#                 qx{git pull --rebase $r master };
#                 print "  - ok\n";
#             }
            chdir "../";
        }
        else {
            print "Cloning " . $repo->{name} . " ...\n";

            my $flags = qq();
            $flags .= qq{ -q } unless $self->{verbose};

            qx{ git clone $flags $uri };
        }
    }




}


1;
