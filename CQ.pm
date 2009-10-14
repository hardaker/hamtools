=pod

=head1 NAME

CQ - base class which does very little but offers documentation

=head1 Hooks

The following hooks are called at various times:

  call_hooks('set_current_channel', $newchannel);
  call_hooks('start_history', $channel, $historylabel, $time);
  call_hooks('set_history_label', $channel, $historylabel);
  call_hooks('close_history', $channel, $historylabel);

To register for a hook call:

   main::register_hook('set_current_channel', \&function, @extraargs);


=cut

