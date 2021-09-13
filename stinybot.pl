#/
# stinybot main controller
# SQL to view incomming imessages
# applescript to send outgoing messages
# John Craffey
# September 2021

use DBI;
use Switch;
use Text::Parsewords;

my $timeLimit = 5; # number of seconds to look back in SQL query
my %nicknames; # Hash of all the nicknames

# Send message function (message, GUID)
sub send_message {
    `osascript send.scpt "$_[0]" "$_[1]"`;
    return;
}

# Clean out backtick marks to avoid unwanted command line access
sub tick_clean {
    my $cmd = $_[0];
    $cmd =~ s/`//g; #replace ticks with nothing
    return $cmd;
}

# Command functions (argument(s), GUID)
sub thoughts {
    my $target = $_[0];
    for (1..5) {
        send_message("$target, THOUGHTS???", $_[1]);
        sleep(1);
    }
}

# Set new nickname for a given number
sub set_nickname {
    my $number = $_[0];
    my $newNickname = $_[1];
    my $guid = $_[2];
    my $hashKey = $guid;
    
    # Clean off the +1 in phone number
    $number =~ s/^\+\d//;
    
    # Clean ASCII out of guid to use in hashKey
    $hashKey =~ s/^\D+//;
    
    $hashKey += $number;
    
    # Hash the nickname
    $nicknames{"$hashKey"} = $newNickname;

    send_message("$number nickname set to $nicknames{$hashKey}", $guid);
}

# Get a nickname for a given number
sub get_nickname {
    my $number = $_[0];
    my $guid = $_[1];
    my $hashKey = $guid;
    
    # Clean off the +1 in phone number
    $number =~ s/^\+\d//;
    
    # Clean ASCII out of guid to use in hashKey
    $hashKey =~ s/^\D+//;

    $hashKey += $number;
    if ($nicknames{$hashKey}) {
        send_message("Nickname is $nicknames{$hashKey}", $guid);
    }
    else {
        send_message("No nickname found for $number", $guid);
    }
}

# Thank stinybot
sub thanks {
    if ($_[0] eq "stinybot") {
        send_message("<3", $_[1]);
    }
    return;
}

## SQL setup
# get the messages db file
chomp (my $username = `whoami`);
my $dbfile = "/Users/$username/Library/Messages/chat.db";

# DBI config to connect to db
my $dsn      = "dbi:SQLite:dbname=$dbfile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {AutoCommit=>1,RaiseError=>1,PrintError=>0});

# SQL Query
my $sql = "SELECT 
    message.date / 1000000000 + strftime ('%s', '2001-01-01') as message_secs,
    message.text, 
    chat.guid,
    handle.id
FROM
    chat 
    JOIN chat_message_join ON chat. 'ROWID' = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. 'ROWID'
    LEFT JOIN handle ON message.handle_id = handle.'ROWID'
WHERE
    message_secs > strftime ('%s', 'now') - $timeLimit AND message.text like '/%'
ORDER BY
    message_secs ASC;";

# Get a statement handle object
my $sth = $dbh->prepare($sql);

## Main loop
while(1) {
    my $loopStartTime = 
    # Execute the query
    $sth->execute or die "unable to execute query on db\n";
    # Loop through each row of the result set
    while(($timestamp,$command,$guid,$handle_id) = $sth->fetchrow()){
        # Sanitize input
        $command = tick_clean($command);
        
        # Separate the command & arguments
        my @args = split(' ', $command);
        $command = shift(@args);
        my $response = "";
        
        print("Timestamp: $timestamp\tCommand: $command @args\tGUID: $guid\n");
        
        # Get the correct response based on the command
        switch($command) {
            case "/help"        {$response = "This is stinybot.\tUsage: /<command> [arguments]
                If response takes > ~$timeLimit seconds, resend
                                Available commands:
                                /help
                                /date
                                /barf
                                /joke
                                /thoughts <person name>
                                /whoami
                                /setnickname <phone num> <new nickname>
                                /getnickname <phone num>

                                /thanks stinybot"}

            case "/date"        {chomp($response = `date`)}
            case "/barf"        {$response = "Timestamp: $timestamp\tCommand: $command @args\tGUID: $guid"}
            case "/joke"        {$response = "flig lol."}
            case "/thoughts"    {$response = thoughts(join(' ', @args), $guid)}
            case "/whoami"      {$response =  "You are $handle_id"}
            case "/setnickname" {set_nickname(shift(@args), join(' ', @args), $guid)}
            case "/getnickname" {get_nickname(@args[0], $guid)}

            case "/thanks"      {thanks($args[0], $guid)}

            else            {$response = "command not found. Try /help"}
        }

        # Send the response back as a reply
        send_message($response, $guid);                 
    }

    # Delay by time limit factor
    sleep($timeLimit);
}

## Clean up
$sth->finish();
$dbh->disconnect();
