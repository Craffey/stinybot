-- imessage database is located at ~/Library/Messages/chat.db
SELECT
    -- message date / 1 billion = seconds since 1/1/01
    -- so add the 1/1/01 epoch time to the imessage time
    message.date / 1000000000 + strftime ("%s", "2001-01-01") as message_secs,
    message.text, -- content of message
    chat.guid -- GUID of the message used for sending
FROM
    chat -- imessage top level db
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
WHERE
    -- only return if timestamp of the message is within x seconds ago from now
    -- and the message content matches a keyword
    message_secs > strftime ("%s", "now") -600 AND message.text like '%/whoami%'
ORDER BY
    -- ascending order list
    message_secs ASC;