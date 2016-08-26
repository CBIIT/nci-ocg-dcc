#!/bin/bash

if [ $# -ne 1 ]
then
    echo "Usage $0 watch_dcc_(uploads|data)"
    echo "Requires PAR::Packer"
    exit 1
fi

cmd="pp \
-M File::ChangeNotify \
-M File::ChangeNotify::Watcher \
-M Email::Sender \
-M Email::Sender::Role::CommonSending \
-M Throwable \
-M Throwable::Error \
-M StackTrace::Auto \
-M List::MoreUtils::PP \
-M Email::Abstract::EmailSimple \
-c -o $1 $1.pl"
echo $cmd
$cmd
