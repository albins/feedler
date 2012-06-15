/**
 * sidebar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class ChannelStore : GLib.Object
{
	public int id;
    public string channel { set; get; }
    public int unread { set; get; }
    public int mode { set; get; }
    
    public ChannelStore (int id, string channel, int unread, int mode)
    {
		this.id = id;
		this.channel = channel;
		this.unread = unread;
		this.mode = mode; //0-Folder;1-Channel;2-ERROR
	}
}

public class Feedler.Sidebar : Gtk.TreeView
{
	internal Gtk.TreeStore store;
	private Feedler.SidebarCell scell;
    private Gee.AbstractMap<int, Gtk.TreeIter?> folders;
    private Gee.AbstractMap<int, Gtk.TreeIter?> channels;
	private Gtk.TreeIter iter;
	
	construct
	{
		this.store = new Gtk.TreeStore (1, typeof (ChannelStore));
		this.scell = new Feedler.SidebarCell ();
		this.name = "SidebarContent";
        this.get_style_context ().add_class ("sidebar");
		this.headers_visible = false;
		this.enable_search = false;
        this.model = store;
        //this.reorderable = true;       

        var column = new Gtk.TreeViewColumn.with_attributes ("ChannelStore", scell, null);
		column.set_sizing (Gtk.TreeViewColumnSizing.FIXED);
		column.set_cell_data_func (scell, render_scell);
		this.insert_column (column, -1); 
        this.folders = new Gee.HashMap<int, Gtk.TreeIter?> ();
		this.channels = new Gee.HashMap<int, Gtk.TreeIter?> ();
		//this.set_no_show_all (true);
//this.add_folder_ (2, "KUTAS", 0);
//Gtk.TreeIter folder_iter;
//        this.store.append (out iter, null);
//        this.store.set_value (iter, 0, new ChannelStore (1, "TEST", 0, 0));
//        this.folders.set (1, iter);
//this.add_folder_ (1, "TEST", 0);
//this.add_channel (1, "AAA", 1, 0);
//int folder = 0;
//int id = 1;
//string name = "AAA";
//this.add_folder_ (2, name, 0);
//Gtk.TreeIter folder_iter;
		/*if (folder > 0)
            this.store.append (out folder_iter, this.folders.get (folder));
        else
            this.store.append (out folder_iter, null);*/
		/*this.store.append (out folder_iter, this.folders.get (folder));
        this.store.set_value (folder_iter, 0, new ChannelStore (id, name, 0, 0));
        this.folders.set (id, folder_iter);
		this.store.append (out folder_iter, this.folders.get (1));
        this.store.set_value (folder_iter, 0, new ChannelStore (2, name, 0, 0));
        this.folders.set (2, folder_iter);*/
	}

    public void add_folder (Model.Folder f)
    {
        this.add_folder_ (f.id, f.name, f.parent);
    }

    public void add_folder_ (int id, string name, int folder)
    {
        Gtk.TreeIter folder_iter;
		if (folder > 0)
            this.store.append (out folder_iter, this.folders.get (folder));
        else
            this.store.append (out folder_iter, null);
        this.store.set_value (folder_iter, 0, new ChannelStore (id, name, 0, 0));
        this.folders.set (id, folder_iter);
    }

    public void add_channel (int id, string name, int folder, int unread = 0)
	{
		Gtk.TreeIter channel_iter;
        if (folder > 0)
            this.store.append (out channel_iter, this.folders.get (folder));
        else
            this.store.append (out channel_iter, null);
        this.store.set_value (channel_iter, 0, new ChannelStore (id, name, unread, 1));
        this.channels.set (id, channel_iter);
	}

	public void remove_folder (int id)
	{
		Gtk.TreeIter folder_iter = folders.get (id);
		this.store.remove (folder_iter);
		this.folders.unset (id);
	}
	
	public void remove_channel (int id)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		this.store.remove (channel_iter);
		this.channels.unset (id);
	}

    public void update_channel (int id, string name, int folder)
	{
        this.remove_channel (id);
        this.add_channel (id, name, folder);
	}

    public void update_folder (int id, string name)
	{
        Gtk.TreeIter iter = folders.get (id);
		ChannelStore store;
		this.model.get (iter, 0, out store);
		store.channel = name;
		this.store.set_value (iter, 0, store);
	}

    public void mark_channel (int id)
	{
		Gtk.TreeIter iter = channels.get (id);
		ChannelStore channel;
		this.model.get (iter, 0, out channel);
		channel.unread = 0;
		this.store.set_value (iter, 0, channel);
	}

	public void mark_folder (int id)
	{
		Gtk.TreeIter iter_f = folders.get (id);
        Gtk.TreeIter iter_c;
		ChannelStore channel;
        if (model.iter_children (out iter_c, iter_f))
        {
            do
            {
                this.model.get (iter_c, 0, out channel);
        		channel.unread = 0;
        		this.store.set_value (iter_c, 0, channel);
            }
            while (model.iter_next (ref iter_c));
        }
	}
	
	public void add_unread (int id, int unread)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread += unread;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void dec_unread (int id, int num = -1)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread += num;
		if (channel.unread < 0)
			channel.unread = 0;
		this.store.set_value (channel_iter, 0, channel);
	}

    public void set_mode (int id, int mode)
    {
        Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.mode = mode;
		this.store.set_value (channel_iter, 0, channel);
    }
	
	public void select_channel (int id)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		this.get_selection ().select_iter (channel_iter);
	}
	
	public void select_path (Gtk.TreePath path)
	{
		this.get_selection ().select_path (path);
	}
	
	private void render_scell (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter)
	{
		ChannelStore channel;
		var renderer = cell as Feedler.SidebarCell;
		model.get (iter, 0, out channel);
		
		renderer.id = channel.id;
		renderer.channel = channel.channel;
		renderer.unread = channel.unread;
		renderer.type = (Feedler.SidebarCell.Type)channel.mode;
	}
}
