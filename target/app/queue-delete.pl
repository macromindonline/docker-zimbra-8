#!/usr/bin/perl

$exp = shift || die "Please set the expression to search and delete";
@fila = qx</opt/zimbra/common/sbin/postqueue -p>;

for (@fila) {
    
    if (/^(\w+)(\*|\!)?\s/) {
        $queue_id = $1;
    }

    if ($queue_id) {
        if (/$exp/i) {
            $Q{$queue_id} = 1;
            $queue_id = "";
        }
    }
}

open(POSTSUPER,"|/opt/zimbra/common/sbin/postsuper -d - ") || die "Impossible to use postsuper!";

foreach (keys %Q) {
    print POSTSUPER "$_\n";
}

close(POSTSUPER);