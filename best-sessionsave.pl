#
#
# Copyright 2012 Janis Jansons (janis.jansons@janhouse.lv)
#
# Forked from "Better Sessionsave for Pidgin in Perl" by Stefan Gipper
# https://code.google.com/p/better-sessionsave/
#
#
use Purple;
use Pidgin;
=pod
use Gtk2;

use Clipboard;
my $windowtop = Gtk2::Window->new();#'toplevel'
=cut
use MIME::Base64;
use DBI;#DBD-SQLite
my $mynewsession = time();
my $myoldsession = "";
my $sqlglobalopen = 0;
my $dbrestore = &dbconnect();
use File::Spec;

# Changelog
#
# v0.2 - Started a fork. Looks messy but works on Linux.
#
# v0.1 - 09.12.2011 (DD.MM.YYYY)
#  - Release
#
#
# TODO: 
# * Remove unused code;
# * Tidy up.
#
#

my $des = "Wololotrololo. I be no German.";

our %PLUGIN_INFO = (
	perl_api_version => 2,
	name => "Best SessionSave",
	version => "0.2",
	summary => "SessionSave plugin that works (based on Better Sessionsave by Stefan Gipper",
	description => $des,
	author => "Janis Jansons <janis.jansons\@janhouse.lv>",
	url => "http://www.janhouse.lv",
	load => "plugin_load",
	unload => "plugin_unload",
	#prefs_info => "prefs_info_cb",
	#plugin_action_sub => "plugin_actions_cb",
);

sub plugin_init {
	return %PLUGIN_INFO;
}
=pod
sub plugin_actions_cb {
	my @actions = ("Better Sessionsave");
}

%plugin_actions = (
	"Better Sessionsave" => \&buddysearch,
);

sub buddysearch {
	$windowtop->set_title('Better Sessionsave');
	$windowtop->set_default_size( 600, 600 );
	$windowtop->set_border_width(8);

	my $window = Gtk2::Frame->new();
	$window->set_label(" Sessions ");
	$window->set_label_align( 0.98, 0.49 );

	my $table = Gtk2::VBox->new(FALSE,3);
	$scroller = Gtk2::ScrolledWindow->new;

	$replacemodel2 = create_model4();
	$filestreeview = Gtk2::TreeView->new ($replacemodel2);
	$filestreeview->set_rules_hint(1);
	$filestreeview->get_selection->set_mode('single');
	$filestreeview->set_search_column(0);
	$filestreeview->set_enable_tree_lines(1);
	$filestreeview->set_grid_lines('vertical');#vertical, horizontal, none, both
	#$buffer = Gtk2::TextBuffer->new();
	#$textview = Gtk2::TextView->new_with_buffer($buffer);
	$treeview = add_columns4($filestreeview);

	$scroller->set_size_request(480,210);
	#$entry = Gtk2::Entry->new();
	#$entry->select_region( 0, length( $entry->get_text() ) );
	#$entry->set_text($newtext);

	$scroller->add($filestreeview);
	#$scroller->add($textview);
	my $button = Gtk2::Button->new( " Save " );

	my $buttonchat = Gtk2::Button->new( " Open " );
	my $send_sig4 = $buttonchat->signal_connect ('clicked' => sub {
			if($treeview->get_selection()){
				my $selection = $treeview->get_selection();
				my($tmp_model, $tmp_iter) = $selection->get_selected();
				my $sessionid = $tmp_model->get($tmp_iter, 1);

				my $sth = $dbrestore->prepare("SELECT * FROM `data` WHERE session = '$sessionid'");
				$sth->execute;
				while(my $row = $sth->fetchrow_hashref){
					my $account = decode_from_db($row->{account});
					my $accountproto = decode_from_db($row->{proto});
					my $first = decode_from_db($row->{to});
					my $accountx = Purple::Accounts::find($account, $accountproto);#"prpl-icq"
					my $conv = Purple::Conversation->new(1, $accountx, $first);#4329758265
					my $sendmsg = $conv->get_im_data();
				}
				$sth->finish;
			}
		}
	);

	my $buttonchat5 = Gtk2::Button->new( " Refresh " );
	my $send_sig5 = $buttonchat5->signal_connect ('clicked' => sub {
			if($treeview->get_selection()){
				&cell_clicked();
			}
		}
	);

	my $buttonchat3 = Gtk2::Button->new( " Del " );
	my $send_sig3 = $buttonchat3->signal_connect ('clicked' => sub {
			if($treeview->get_selection()){
				my $selection = $treeview->get_selection();
				my($tmp_model, $tmp_iter) = $selection->get_selected();
				my $sessionid = $tmp_model->get($tmp_iter, 1);

				$replacemodel2->clear;
				$dbrestore->do("DELETE FROM `data` WHERE session = '$sessionid'");
				&rebuilddata();
			}
		}
	);

	my $buttonchat2 = Gtk2::Button->new( " Copy " );
	my $send_sig4 = $buttonchat2->signal_connect ('clicked' => sub {
			if($treeview->get_selection()){
				my $selection = $treeview->get_selection();
				my($tmp_model, $tmp_iter) = $selection->get_selected();
				my $sessionid = $tmp_model->get($tmp_iter, 1);
				my $sessiont = $tmp_model->get($tmp_iter, 2);

				my $button2;
				my $sth = $dbrestore->prepare("SELECT * FROM `data` WHERE session = '$sessionid' ORDER BY time DESC");
				$sth->execute;
				while(my $row = $sth->fetchrow_hashref){
					$button2 .= decode_from_db($row->{to}) . " (".decode_from_db($row->{proto}).")\n";
				}
				$sth->finish;

				my $CLIP = Win32::Clipboard();#only win32
				$CLIP->Set("Session: $sessionid ($sessiont)\n".$button2);
			}
		}
	);


	my $send_sig2 = $button->signal_connect ('clicked' => sub {#Save
			my $selection = $treeview->get_selection();
			my($tmp_model, $tmp_iter) = $selection->get_selected();
			my $sessionid = $tmp_model->get($tmp_iter, 1);

			$replacemodel2->clear;
			$dbrestore->do("DELETE FROM `data` WHERE session = '$mynewsession'");

			my @convs = Purple::get_conversations();
			foreach my $conv (@convs){
				my $account = encode_for_db($conv->get_name(),'');
				my $type = encode_for_db($conv->get_type(),'');
				my $accountproto = encode_for_db($conv->get_account()->get_protocol_id(),'');
				my $accountself = encode_for_db($conv->get_account()->get_username(),'');

				my $time = time;
				my $sth = $dbrestore->prepare("INSERT INTO `data` ( 
				`type`,
				`to`,
				`account`,
				`proto`,
				`time`,
				`session`
				) VALUES (
				'$type',
				'$account',
				'$accountself',
				'$accountproto',
				'$time',
				'$mynewsession'
				)");
				$sth->execute;
				#my $mysql_insertid = $sth->{'mysql_insertid'};
				$sth->finish;
			}
			&rebuilddata();
		}
	);

	$scroller2 = Gtk2::ScrolledWindow->new;
	$buffer2 = Gtk2::TextBuffer->new();
	$textview2 = Gtk2::TextView->new_with_buffer($buffer2);
	$scroller2->set_size_request(300,100);
	$scroller2->add($textview2);

	my $table3 = Gtk2::HBox->new(FALSE,10);
	$table3->pack_end_defaults($buttonchat5);
	$table3->pack_end_defaults($buttonchat3);
	$table3->pack_end_defaults($button);
	$table3->pack_end_defaults($buttonchat2);
	$table3->pack_end_defaults($buttonchat);

	my $layout3 = Gtk2::Layout->new($hadjustment2, $vadjustment2);
	$layout3->put( $table3, 0, 0);
	$layout3->put( $scroller, 0, 35);
	$layout3->set_size( 400, 200);

	$table->pack_end_defaults($scroller2);
	$table->pack_end_defaults($layout3);
	$window->add($table);

	$window->add($table);
	$windowtop->add($window);

	&rebuilddata();

	$windowtop->show_all;
}

sub rebuilddata {
	my @searchdata = ();
	my $sth = $dbrestore->prepare("SELECT * FROM `data` GROUP BY session ORDER BY time DESC");
	$sth->execute;
	while(my $row = $sth->fetchrow_hashref){
		my %data = (
			text => $row->{id},
			replace => $row->{session},
			name => &mydatetime($row->{time}),
			datumsort => $row->{time}
		);
		push(@searchdata,\%data);
	}
	$sth->finish;

	my $data = \@searchdata;
	my @filesdata = ();

	foreach my $selectdata (@$data){
		push(@filesdata, \%$selectdata );
	}
	$replacemodel2->clear;
	foreach my $d (@filesdata) {
		my $iter = $replacemodel2->append;
		$replacemodel2->set ($iter,
		   0, $d->{text},
		   1, $d->{replace},
		   2, $d->{name},
		   3, $d->{datumsort}
		);
	}
}

sub create_model4 {
	my $store = Gtk2::ListStore->new (
		'Glib::Int',
		'Glib::String',
		'Glib::String',
		'Glib::Int',
	);

	foreach my $d (@searchdata) {
		my $iter = $store->append;
		$store->set ($iter,
		   0, $d->{name},
		   1, $d->{text},
		   2, $d->{replace},
		   3, $d->{datumsort}
		);
	}
	return $store;
}

sub add_columns4 {
	my $treeview = shift;
	my $model = $treeview->get_model;
	my $sel = $treeview->get_selection();
	$sel->signal_connect ('changed' => sub { cell_clicked($sel) }, $model);

	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => sub {
			my ($cell, $text_path, $new_text, $model) = @_;
			my $path = Gtk2::TreePath->new_from_string ($text_path);
			my $iter = $model->get_iter ($path);

			$model->set ($iter, 0, $new_text);
		}, $model);
	$renderer->set_property('editable', 1);
	my $column = Gtk2::TreeViewColumn->new_with_attributes ("ID",
						       $renderer,
						       text => 0);
	$column->set_resizable(1);
	$column->set_sort_column_id(0);
	$treeview->append_column ($column);

	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => sub {
			my ($cell, $text_path, $new_text, $model) = @_;
			my $path = Gtk2::TreePath->new_from_string ($text_path);
			my $iter = $model->get_iter ($path);

			$model->set ($iter, 1, $new_text);
		}, $model);
	$renderer->set_property('editable', 1);
	my $column = Gtk2::TreeViewColumn->new_with_attributes ("Session",
						       $renderer,
						       text => 1);
	$column->set_resizable(1);
	$column->set_sort_column_id(1);
	$treeview->append_column ($column);

	my $renderer = Gtk2::CellRendererText->new;
	$renderer->signal_connect (edited => sub {
			my ($cell, $text_path, $new_text, $model) = @_;
			my $path = Gtk2::TreePath->new_from_string($text_path);
			my $iter = $model->get_iter($path);

			$model->set ($iter, 2, $new_text);
		}, $model);
	$renderer->set_property('editable', 1);

	my $column = Gtk2::TreeViewColumn->new_with_attributes ("Datum",
						       $renderer,
						       text => 2);
	$column->set_resizable(1);
	$column->set_sort_column_id(3);
	$treeview->append_column ($column);
	return $treeview;
}

sub cell_clicked {
	if($treeview->get_selection()){
		my $selection = $treeview->get_selection();
		my($tmp_model, $tmp_iter) = $selection->get_selected();

		$buffer2->delete ($buffer2->get_start_iter,$buffer2->get_end_iter);
		my $sessionid = $tmp_model->get($tmp_iter, 1);
		my $sessiont = $tmp_model->get($tmp_iter, 2);

		my $button2;
		my $sth = $dbrestore->prepare("SELECT * FROM `data` WHERE session = '$sessionid' ORDER BY time DESC");
		$sth->execute;
		while(my $row = $sth->fetchrow_hashref){
			$button2 .= decode_from_db($row->{to}) . " (".decode_from_db($row->{proto}).")\n";
		}
		$sth->finish;
		$buffer2->set_text("Session: $sessionid ($sessiont)\n".$button2);
	}
}
=cut
sub signed_on {
	my $conn = shift;

	my $accountproto = encode_for_db($conn->get_account()->get_protocol_id(),'');
	my $accountself = encode_for_db($conn->get_account()->get_username(),'');

#Purple::Debug::misc("sessionsaveperl", "SELECT * FROM `data` WHERE account = $accountself AND proto = $accountproto AND session = $myoldsession"."\n");

	&dbmsg("SELECT * FROM `data` WHERE account = $accountself AND proto = $accountproto AND session = $myoldsession");
	my $sth = $dbrestore->prepare("SELECT * FROM `data` WHERE account = $accountself AND proto = $accountproto AND session = $myoldsession");
	$sth->execute;
	while(my $row = $sth->fetchrow_hashref){
		
		
		
		my $account = decode_from_db($row->{account});
		my $accountproto = decode_from_db($row->{proto});
		my $first = decode_from_db($row->{to});

		my $accountx = Purple::Accounts::find($account, $accountproto);#"prpl-icq"
		
		#&dbmsg($account."-".$accountproto."-".$accountx);
		
		my $conv = Purple::Conversation->new(1, $accountx, $first);#4329758265
		my $sendmsg = $conv->get_im_data();
	}
	$sth->finish;

	&dbmsg("signed-on (" . $conn->get_account()->get_username() . ")");
}

sub signed_off {
	my $conn = shift;#Close all conversations for this account?
	&dbmsg("signed-off (" . $conn->get_account()->get_username() . ")");
}

sub conv_conversation_created {
	my $conv = shift;#Typ 1=IM, 2=Chat
	if($conv->get_type ne 2){#Only IM
		if($conv->get_name() ne "Global" or $conv->get_name() ne "SpamScanner"){#IRC
			my $account = encode_for_db($conv->get_name(),'');
			my $type = encode_for_db($conv->get_type(),'');
			my $accountproto = encode_for_db($conv->get_account()->get_protocol_id(),'');
			my $accountself = encode_for_db($conv->get_account()->get_username(),'');

			my $sth = $dbrestore->prepare("SELECT * FROM `data` WHERE `type` = $type AND `to` = $account AND account = $accountself AND proto = $accountproto AND session = $mynewsession LIMIT 1");
			$sth->execute;
			my $row = $sth->fetchrow_hashref;
			$sth->finish;

			my $time = time;
			unless($row->{id}){
				my $sth = $dbrestore->prepare("INSERT INTO `data` ( 
				`type`,
				`to`,
				`account`,
				`proto`,
				`time`,
				`session`
				) VALUES (
				$type,
				$account,
				$accountself,
				$accountproto,
				$time,
				$mynewsession
				)");
				$sth->execute;
				#my $mysql_insertid = $sth->{'mysql_insertid'};
				$sth->finish;
			}

			&dbmsg("created conv (" . $conv->get_type . " - " . $conv->get_name() . " - " . $conv->get_account()->get_username() . ")");
		}
	}
}

sub conv_deleting_conversation {
	my $conv = shift;#Typ 1=IM, 2=Chat
	if($conv->get_type ne 2){#Only IM
		if($conv->get_name() ne "Global" or $conv->get_name() ne "SpamScanner"){#IRC
			my $account = encode_for_db($conv->get_name(),'');
			my $type = encode_for_db($conv->get_type(),'');
			my $accountproto = encode_for_db($conv->get_account()->get_protocol_id(),'');
			my $accountself = encode_for_db($conv->get_account()->get_username(),'');

			&dbmsg("delete conv (" . $conv->get_type . " - " . $conv->get_name() . " - " .  $conv->get_account()->get_username() . ")");
			$dbrestore->do("DELETE FROM `data` WHERE type = $type AND `to` = $account AND account = $accountself AND proto = $accountproto");# AND session = $mynewsession");
			#&dbmsg("DELETE FROM `data` WHERE type = '$type' AND to = '$account' AND account = '$accountself' AND proto = '$accountproto' AND session = '$mynewsession'");
		}
	}
}

sub plugin_load {
	my $plugin = shift;

	my $conn = Purple::Connections::get_handle();
	Purple::Signal::connect($conn, "signed-on", $plugin,
					\&signed_on, 0);
	#Purple::Signal::connect($conn, "signed-off", $plugin,
	#				\&signed_off, 0);

	my $conv = Purple::Conversations::get_handle();
	Purple::Signal::connect($conv, "conversation-created", $plugin,
					\&conv_conversation_created, "created conversation");
	Purple::Signal::connect($conv, "deleting-conversation", $plugin,
					\&conv_deleting_conversation, "deleting conversation");

=pod
	Purple::Cmd::register($plugin, "sessionsave", "s", Purple::Cmd::Priority::DEFAULT,
			Purple::Cmd::Flag::IM | Purple::Cmd::Flag::CHAT,
			0, \&buddysearch,"",$plugin);
=cut
	&dbmsg("plugin_load() - Better Sessionsave Plugin in Perl loaded.");

	my $sth = $dbrestore->prepare("SELECT * FROM `data` GROUP BY session ORDER BY session DESC,time DESC LIMIT 1");
	$sth->execute;
	my $row = $sth->fetchrow_hashref;
	$sth->finish;

	unless($row->{id}){#Lastsession
		my @convs = Purple::get_conversations();

		foreach my $conv (@convs){
			my $account = encode_for_db($conv->get_name(),'');
			my $type = encode_for_db($conv->get_type(),'');
			my $accountproto = encode_for_db($conv->get_account()->get_protocol_id(),'');
			my $accountself = encode_for_db($conv->get_account()->get_username(),'');

			my $time = time;
			my $sth = $dbrestore->prepare("INSERT INTO `data` ( 
			`type`,
			`to`,
			`account`,
			`proto`,
			`time`,
			`session`
			) VALUES (
			$type,
			$account,
			$accountself,
			$accountproto,
			$time,
			$mynewsession
			)");
			$sth->execute;
			#my $mysql_insertid = $sth->{'mysql_insertid'};
			$sth->finish;
		}
		$myoldsession = $mynewsession;
	}else{
		$myoldsession = $row->{session};
	}

	#my @wins = Pidgin::Conversation::Windows::get_list();
	#foreach my $win (@wins){
		#my $conv_count = $win->get_gtkconv_count();
		#my @conversation = $win->get_gtkconvs();

		#foreach my $conv (@conversation){#gtkconv!
		#
		#}
	#}
	

}

sub plugin_unload {
	my $plugin = shift;

	&dbmsg("plugin_unload() - Better Sessionsave Plugin in Perl unloaded.");
	&dbdisconnect($dbrestore);
#	$windowtop->destroy;
}
=pod
sub prefs_info_cb {
	my ($frame, $ppref);
	$newtext = "";
	&buddysearch();
}
=cut
sub dbmsg {
	my $msg = shift;
	Purple::Debug::misc("sessionsaveperl", $msg."\n");
}

sub dbconnect {
	my $base_dirname=File::Spec->rel2abs( __FILE__ );
	$base_dirname=substr($base_dirname, 0, rindex($base_dirname, '/'));
	my $dbrestore = DBI->connect('dbi:SQLite:'.$base_dirname.'/.bettersessionsave.db', '', '', {'RaiseError' => 1,'PrintError' => 1});
	$sqlglobalopen = 1;

	$dbrestore->do(qq(CREATE TABLE IF NOT EXISTS `data` (
		  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
		  `type` text NOT NULL,
		  `to` text NOT NULL,
		  `account` text NOT NULL,
		  `proto` text NOT NULL,
		  `time` decimal(14,0) NOT NULL,
		  `session` decimal(14,0) NOT NULL
		)
	));
	return($dbrestore);
}

sub dbdisconnect {
	my($dbrestore) = @_;
	$dbrestore->disconnect();
}

sub mydatetime {
	my($mytime) = @_;
	return "no data" unless($mytime);
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mytime);
	$mon++;
	$hour = "0$hour" if($hour < 10);
	$min = "0$min" if($min < 10);
	$sec = "0$sec" if($sec < 10);
	$year += 1900;
	$mon = "0$mon" if($mon < 10);
	$mday = "0$mday" if($mday < 10);
	return("$mday\.$mon\.$year\/$hour:$min");
}


sub encode_for_db {
	my($string, $stuff) = @_;
	return $dbrestore->quote($string);
	#return $dbrestore->quote(remove_crap($string));
	#return encode_base64($string, $stuff);
}

sub decode_from_db {
	my($string) = @_;
	return $string;
	#return decode_base64($string);
}


sub remove_crap {
	my($s) = @_;
	return substr($s, 0, index($s, "\/"));
}
