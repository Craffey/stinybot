-- imessage database is located at ~/Library/Messages/chat.db
SELECT
    -- message date / 1 billion = seconds since 1/1/01
    message.date / 1000000000 + strftime ("%s", "2001-01-01") as message_secs,
    message.text,
    chat.guid
FROM
    chat
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
WHERE
    message_secs > strftime ("%s", "now") -600 AND message.text like '%/whoami%'
ORDER BY
    message_secs ASC;