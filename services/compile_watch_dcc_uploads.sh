#!/bin/bash

cmd='pp -M File::ChangeNotify -M File::ChangeNotify::Watcher -M Email::Sender -M Email::Sender::Role::CommonSending -M Throwable -M Throwable::Error -M StackTrace::Auto -M List::MoreUtils::PP -M Email::Abstract::EmailSimple -c -o watch_dcc_uploads watch_dcc_uploads.pl'
echo $cmd
$cmd
