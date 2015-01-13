mpps
====

Multipurpos SMS Server
----------------------
```
# Multipurpose Party Server, Version 01
# global variables
# Message of the day
# Places of the day
# special Settings
# Open connection to Siemens SL45 via COM1
# Test communication with Siemens SL45
# MPPS started
# Main Loop ####################################################
        # set message of the day
        # Loop of the day
# close connection to Siemens SL45
# Procedures ####################################################
# read incoming SMS and answer with the message of the day
        # open log-file
        # Read new SMS from Siemens SL45 (0:new 1:read 4:all)
        # print "--\n$result--\n";
        # Delete SMS from Siemens SL45 (1:all read 2:all read+sent 4:all)
        # print "--\n$result--\n";
        # Loop incoming messages
                # decode PDU message
                # detect ADMIN Message
                # encode PDU message
                # Send answer SMS via Siemens SL45
# handle administrator messages
        # stopping MPPS by admin SMS
        # reset message of the day
        # send help message
        # set new message
```
