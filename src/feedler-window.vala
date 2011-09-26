/**
 * feedler-window.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Window : Gtk.Window
{
	private Feedler.Settings settings;
	private Feedler.Database db;
	private Feedler.OPML opml;
	private Feedler.Toolbar toolbar;	
	private Feedler.Sidebar side;
	private Feedler.History history;
	private weak Feedler.View view;
	private Gtk.HPaned hpane;
	private Gtk.VBox vbox;
	private Gtk.ScrolledWindow scroll_side;
	private Feedler.CardLayout layout;
	
	construct
	{
		Notify.init ("org.elementary.Feedler");
		this.settings = new Feedler.Settings ();
		this.db = new Feedler.Database ();
		this.opml = new Feedler.OPML ();
		this.layout = new Feedler.CardLayout ();
		this.title = "Feedler";
		this.icon_name = "news-feed";
		this.destroy.connect (destroy_app);
		this.set_default_size (settings.width, settings.height);
		this.set_size_request (800, 500);
		
		this.vbox = new Gtk.VBox (false, 0);	
		this.ui_toolbar ();
		if (this.db.created)
			this.ui_feeds ();
		else
			this.ui_welcome ();		
			
		this.add (vbox);
		this.show_all ();
		this.history = new Feedler.History ();
	}
	
	private void ui_toolbar ()
	{
		this.toolbar = new Feedler.Toolbar ();   
        this.vbox.pack_start (toolbar, false, false, 0);
        
        this.toolbar.back.clicked.connect (history_prev);
        this.toolbar.forward.clicked.connect (history_next);
        this.toolbar.update.clicked.connect (update_all);
        this.toolbar.mark.clicked.connect (mark_all);
        this.toolbar.add_new.clicked.connect (create_subscription);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.search.activate.connect (search_list); 
        
        this.toolbar.import_feeds.activate.connect (import_file);
        this.toolbar.export_feeds.activate.connect (export_file);
        this.toolbar.sidebar_visible.toggled.connect (sidebar_update);
	}

	private void ui_workspace ()
	{
		this.side = new Feedler.Sidebar ();
		
		this.scroll_side = new Gtk.ScrolledWindow (null, null);
		this.scroll_side.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		this.scroll_side.add (side);
		
		this.hpane = new Gtk.HPaned ();
		this.hpane.name = "SidebarHandleLeft";
		this.hpane.set_position (settings.hpane_width);
        this.vbox.pack_start (hpane, true);
        this.hpane.add1 (scroll_side);
        this.hpane.add2 (layout);
        
        this.side.cursor_changed.connect (load_channel);
        
		this.layout.append_page (new Feedler.ViewList (), null);
		this.layout.append_page (new Feedler.ViewWeb (), null);
		this.view = (Feedler.View)layout.get_nth_page (0);
		this.view.item_selected.connect (history_add);
		this.view.item_browsed.connect (history_remove);
		this.view.item_readed.connect (mark_channel);
	}
	
	private void ui_feeds ()
	{
		this.ui_workspace ();        
        foreach (Feedler.Folder folder in this.db.select_folders ())
		{
			if (folder.parent != "root")
				this.side.add_folder_to_folder (folder.name, folder.parent);
			else
				this.side.add_folder (folder.name);
		}
			
		foreach (Feedler.Channel channel in this.db.select_channels ())
		{
			if (channel.folder != "root")
				this.side.add_channel_to_folder (channel.folder, channel.title);
			else
				this.side.add_channel (channel.title);
			channel.updated.connect (updated_channel);
			//channel.faviconed.connect (faviconed_channel);
		}			
		this.side.expand_all ();
	}
	
	private void ui_welcome ()
	{
		Granite.Widgets.Welcome welcome = new Granite.Widgets.Welcome ("Get Some Feeds", "Feedler can't seem to find your feeds.");
		welcome.append ("gtk-new", "Import", "Add a subscriptions from OPML file.");
		//welcome.append ("tag-new", "Create", "Add a subscription from URL.");		
		welcome.activated.connect (catch_activated);
		this.vbox.pack_start (welcome, true);
	}
	
	private void ui_welcome_to_workspace ()
	{
		GLib.List<Gtk.Widget> box = this.vbox.get_children ();
		this.vbox.remove (box.nth_data (box.length ()-1));
		this.ui_workspace ();
	}
	
	protected void destroy_app ()
	{
		this.save_settings ();
		Gtk.main_quit ();
	}
	
	protected void save_settings ()
	{
		// Save window geometry
        Gtk.Allocation alloc;
        get_allocation(out alloc); // get_size() is a lie.
        settings.width = alloc.width;
        settings.height = alloc.height;
        // Save sidebar width
        settings.hpane_width = this.hpane.position;
     }
	
	protected void catch_activated (int index)
	{
		stderr.printf ("Activated: %i\n", index);
		switch (index)
		{
			case 0: this.import_file (); break;
			case 1: this.create_subscription (); break;
		}
	}
	
	private int selection_tree ()
	{
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		Gtk.TreeSelection selection = this.side.get_selection ();
		
		if (selection.get_selected (out model, out iter))
		{
			ChannelStore channel;
			model.get (iter, 0, out channel);
			return this.side.subs_map.lookup (channel.channel).get_id ();
		}
		else
			return 0;
	}
	
	protected void history_prev ()
	{
		string side_path = null, view_path = null;
		if (this.history.prev (out side_path, out view_path))
		{
			this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
			this.load_channel ();
			if (view_path != null)
			{
				this.view.select (new Gtk.TreePath.from_string (view_path));
			}
		}
	}
	
	protected void history_next ()
	{
		string side_path, view_path;
		if (this.history.next (out side_path, out view_path))
		{
			this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
			this.load_channel ();
			if (view_path != null)
			{
				this.view.select (new Gtk.TreePath.from_string (view_path));
			}
		}
	}
	
	protected void history_add (string item)
	{	
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
		{
			this.history.add (model.get_path (iter).to_string (), item);
		}
	}
	
	protected void history_remove ()
	{	
		this.history.remove_double ();
	}
		
	protected void update_all ()
	{
		foreach (Feedler.Channel ch in this.db.channels)
		{
			ch.update ();
		}
	}
	
	protected void updated_channel (int channel, int unreaded)
	{
		if (unreaded > 0)
		{
			Feedler.Channel ch = this.db.channels.nth_data (channel-1);
			this.side.add_unreaded (ch.title, unreaded);
			this.db.insert_items (ch.items.nth (ch.items.length () - unreaded), channel);
		}
		//TODO information on sidebar-cell		
	}
		
	protected void mark_all ()
	{
		stderr.printf ("Feedler.App.mark_all ()\n");
		foreach (Feedler.Channel ch in this.db.channels)
		{
			foreach (Feedler.Item it in ch.items)
			{
				if (it.state == State.UNREADED)
				{
					it.state = State.READED;
					ch.unreaded--;
				}
				else if (ch.unreaded > 0)
					continue;
				else
					break;
			}
			this.side.set_unreaded (ch.title, 0);
		}
	}
	
	protected void mark_channel (int item_id)
	{//FIXME: channel->items
		stderr.printf ("Feedler.App.mark_channel ()\n");
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		Gtk.TreeSelection selection = this.side.get_selection ();
			
		if (selection.get_selected (out model, out iter))
		{
			unowned Feedler.Channel ch = this.db.channels.nth_data (this.selection_tree ());
			if (item_id == -1)
			{
				this.side.set_unreaded_iter (iter, 0);
				foreach (Feedler.Item it in this.db.channels.nth_data (this.selection_tree ()).items)
				{
					if (it.state == State.UNREADED)
					{
						it.state = State.READED;
						ch.unreaded--;
					}
					else if (ch.unreaded > 0)
						continue;
					else
						break;
				}
			}
			else
			{
				this.side.dec_unreaded (iter);
				ch.unreaded--;
				unowned Feedler.Item it = ch.items.nth_data (ch.items.length () - item_id - 1);
				it.state = State.READED;
			}
		}
	}
	
	protected void change_mode (Gtk.Widget widget)
	{
		stderr.printf ("Feedler.App.change_mode ()\n");
		this.layout.set_current_page (this.toolbar.mode.selected);
		this.view = (Feedler.View)layout.get_nth_page (this.toolbar.mode.selected);
		this.load_channel ();
	}
	
	protected void search_list ()
	{
		stderr.printf ("Feedler.App.search_list ()\n");
		this.view.refilter (this.toolbar.search.get_text ());
	}
	
	protected void load_channel ()
	{
		stderr.printf ("Feedler.App.load_channel ()\n");
		this.view.clear ();
		string time_format;
		GLib.Time current_time = GLib.Time.local (time_t ());
		foreach (Feedler.Item item in this.db.channels.nth_data (this.selection_tree ()).items)
		{
			GLib.Time feed_time = GLib.Time.local (item.publish_time);
			if (feed_time.day_of_year + 6 < current_time.day_of_year)
				time_format = feed_time.format ("%d %B %Y");
			else
				time_format = feed_time.format ("%A %R");

			this.view.add_feed (time_format, item.title, item.source, item.description, item.author, (bool)item.state);
		}
	}
	
	protected void import (string filename)
	{
		try
		{
			this.opml.import (filename);
			if (!this.db.created)
			{
				this.ui_welcome_to_workspace ();
				this.db.create ();
			}
			
			foreach (Feedler.Folder folder in this.opml.get_folders ())
			{
				if (folder.parent != "root")
					this.side.add_folder_to_folder (folder.name, folder.parent);
				else
					this.side.add_folder (folder.name);
			}

			foreach (Feedler.Channel channel in this.opml.get_channels ())
			{
				if (channel.folder != "root")
					this.side.add_channel_to_folder (channel.folder, channel.title);
				else
					this.side.add_channel (channel.title);
			}
			
			this.db.insert_opml (this.opml.get_folders (), this.opml.get_channels ());
			
			foreach (Feedler.Channel channel in this.db.channels.nth (this.db.channels.length () - this.opml.get_channels ().length ()))
			{
				channel.updated.connect (updated_channel);
			}
			this.side.expand_all ();
		}
		catch (GLib.Error error)
		{
			this.ui_welcome ();
			stderr.printf ("ERROR: %s\n", error.message);
		}
	}
	
	protected void export (string filename)
	{
		try
		{
			this.opml.export (filename, this.db.folders, this.db.channels);
		}
		catch (GLib.Error error)
		{
			stderr.printf ("ERROR: %s\n", error.message);
		}
	}
	
	protected void import_file ()
	{
		var file_chooser = new Gtk.FileChooserDialog ("Open File", this,
                                      Gtk.FileChooserAction.OPEN,
                                      Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            import (file_chooser.get_filename ());
        }
        file_chooser.destroy ();
        this.show_all ();
	}
	
	protected void export_file ()
	{
		var file_chooser = new Gtk.FileChooserDialog ("Save File", this,
                                      Gtk.FileChooserAction.SAVE,
                                      Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                      Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            export (file_chooser.get_filename ());
        }
        file_chooser.destroy ();
	}
	
	protected void create_subscription ()
	{
		var subs_creator = new Feedler.CreateSubs ();
        if (subs_creator.run () == Gtk.ResponseType.ACCEPT) {
            stderr.printf ("Create: OK");
        }
        subs_creator.destroy ();
        this.show_all ();
	}
	
	protected void sidebar_update ()
	{
		this.scroll_side.set_visible (this.toolbar.sidebar_visible.active);
	}
}