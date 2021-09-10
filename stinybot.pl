# stiny bot main controller
# SQL to view incomming imessages
# applescript to send outgoing messages
# John Craffey
# September 2021

use DBI;
use Switch;

# config variables
my $timeLimit = 5; # number of seconds to look back in SQL query

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
    chat.guid
FROM
    chat 
    JOIN chat_message_join ON chat. 'ROWID' = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. 'ROWID'
WHERE
    message_secs > strftime ('%s', 'now') - $timeLimit AND message.text like '/%'
ORDER BY
    message_secs ASC;";

# get a statement handle object
my $sth = $dbh->prepare($sql);

while(1) {
    # execute the query
    $sth->execute or die "unable to execute query on db\n";
    # loop through each row of the result set
    while(($timestamp,$command,$guid) = $sth->fetchrow()){
        # Separate the command from the arguments
        my @arguments = split(' ', $command);
        $command = shift(@arguments);
        my $response = "";
        print("Timestamp: $timestamp\tCommand: $command @arguments\tGUID: $guid\n");
        # get the correct response based on the command
        switch($command) {
            case "/help"    {$response = "This is stinybot.\tUsage: /<command> [arguments]
                                Available commands:
                                /help
                                /date
                                /barf"}

            case "/date"    {chomp($response = `date`)}
            case "/barf"    {$response = "Timestamp: $timestamp\tCommand: $command @arguments\tGUID: $guid"}
            
            else            {$response = "command not found. Try /help"}
    }
    # send the response back as a reply
    `osascript send.scpt "$response" "$guid"`;                 
    }
# delay by time limit factor
sleep($timeLimit);
}

# clean up
$sth->finish();
$dbh->disconnect();