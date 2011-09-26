/**
 * feedler-database.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.Database : GLib.Object
{
	private SQLHeavy.Database db;
	private SQLHeavy.Transaction transaction;
	private SQLHeavy.Query query;
	private string location;
	internal bool created;
	internal GLib.List<Feedler.Channel?> channels;
	internal GLib.List<Feedler.Folder?> folders;
	
	construct
	{
		this.location = GLib.Environment.get_user_data_dir () + "/feedler/feedler.db";
		this.channels = new GLib.List<Feedler.Channel?> ();
		this.folders = new GLib.List<Feedler.Folder?> ();

		try
		{
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE);
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database: I cannot find database.\n");
			this.created = false;
		}
	}
	
	public unowned GLib.List<Feedler.Folder?> get_folders ()
	{
		return folders;
	}
	
	public unowned GLib.List<Feedler.Channel?> get_channels ()
	{
		return channels;
	}
	
	public void create ()
	{
        try
        {
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler", 0755);
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler/fav", 0755);
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
			db.execute ("CREATE TABLE folders (`id` INTEGER PRIMARY KEY,`name` TEXT,`parent` TEXT);");
			db.execute ("CREATE TABLE channels (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`homepage` TEXT,`folder` TEXT,`type` TEXT);");
			db.execute ("CREATE TABLE items (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`author` TEXT,`description` TEXT,`publish_time` INT,`state` INT,`channel` REFERENCES `channels`(`id`));");
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.create (): I cannot create new database.\n");
			stderr.printf (location);
		}
	}
/*	
	private void _insert_folder (string name, string parent)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
			query.set_string (":name", name);
			query.set_string (":parent", parent);
			query.execute ();
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_folder (%s, %s): I cannot insert folder.", name, parent);
		}
	}
	
	public void insert_folder (Feedler.Folder folder)
	{
		this._insert_folder (folder.get_name (), folder.get_parent ());  
	}
	
	private void _insert_channel (string title, string source, string homepage, string folder, string type)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `homepage`, `folder`, `type`) VALUES (:title, :source, :homepage, :folder, :type);");
			stderr.printf ("prepare channel\n");
			query.set_string (":title", title);
			query.set_string (":source", source);
			query.set_string (":homepage", homepage);
			query.set_string (":folder", folder);
			query.set_string (":type", type);
			query.execute ();
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_channel (%s, %s, %s, %i, %s, %i): I cannot insert channel.", title, source, homepage, image, folder, unreaded);
		}
	}
	
	public void insert_channel (Feedler.Channel channel)
	{
		this._insert_channel (channel.get_title (), channel.get_source (), channel.get_homepage (), channel.get_folder (), channel.get_type ());  
	}
	
	private void _insert_item (string title, string source, string description, string author, int publish_time, int channel)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `publish_time`, `unreaded`, `channel`) VALUES (:title, :source, :description, :author, :publish_time, :unreaded, :channel);");
			stderr.printf ("prepare item\n");
			query.set_string (":title", title);
			query.set_string (":source", source);
			query.set_string (":description", description);
			query.set_string (":author", author);
			query.set_int (":publish_time", publish_time);
			query.set_int (":unreaded", 1);
			query.set_int (":channel", channel);
			query.execute ();
			stderr.printf ("execute item\n");
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_item (%s, %s, %s, %i, %i): I cannot insert item.", title, source, description, publish_time, channel);
		}
	}

	public void insert_item (Feedler.Item item, int channel_id)
	{
		this._insert_item (item.get_title (), item.get_source (), item.get_description (), item.get_publish_time (), channel_id);  
	}
*/	
	public void insert_opml (GLib.List<Feedler.Folder> folders, GLib.List<Feedler.Channel> channels)
	{
		try
        {
			transaction = db.begin_transaction ();
			foreach (Feedler.Folder folder in folders)
			{
				//stderr.printf ("%s\n", folder.name);
				query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
				query.set_string (":name", folder.name);
				query.set_string (":parent", folder.parent);
				query.execute ();
				this.folders.append (folder);
			}

			foreach (Feedler.Channel channel in channels)
			{
				//stderr.printf ("%s\n", channel.title);
				query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `homepage`, `folder`, `type`) VALUES (:title, :source, :homepage, :folder, :type);");
				query.set_string (":title", channel.title);
				query.set_string (":source", channel.source);
				query.set_string (":homepage", channel.homepage);
				query.set_string (":folder", channel.folder);
				query.set_string (":type", channel.type);
				channel.id = (int) query.execute_insert ();
				this.channels.append (channel);
			}
			transaction.commit();
			
			//this.folders.concat (folders.first ());
			//this.channels.concat (channels);
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_opml (): I cannot insert data from opml file.");
		}
	}

	public void insert_items (GLib.List<Feedler.Item?> items, int channel_id)
	{
        try
        {
			transaction = db.begin_transaction ();
			foreach (Feedler.Item item in items)
			{			
				query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `publish_time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :publish_time, :state, :channel);");
				query.set_string (":title", item.title);
				query.set_string (":source", item.source);
				query.set_string (":author", item.author);
				query.set_string (":description", item.description);
				query.set_int (":publish_time", item.publish_time);
				//query.set_int (":state", (int)item.state);
				query.set_int (":state", (int)State.READED);
				query.set_int (":channel", channel_id);
				query.execute ();
			}
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_items (): I cannot insert list of items.\n");
		}
	}
	
	internal void insert_subscription (ref Feedler.Channel channel)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `homepage`, `folder`, `type`) VALUES (:title, :source, :homepage, :folder, :type);");
			query.set_string (":title", channel.title);
			query.set_string (":source", channel.source);
			query.set_string (":homepage", channel.homepage);
			query.set_string (":folder", channel.folder);
			query.set_string (":type", channel.type);
			channel.id = (int) query.execute_insert ();
			this.channels.append (channel);
			foreach (Feedler.Item item in channel.items)
			{			
				query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `publish_time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :publish_time, :state, :channel);");
				query.set_string (":title", item.title);
				query.set_string (":source", item.source);
				query.set_string (":author", item.author);
				query.set_string (":description", item.description);
				query.set_int (":publish_time", item.publish_time);
				//query.set_int (":state", (int)item.state);
				query.set_int (":state", (int)State.READED);
				query.set_int (":channel", channel.id);
				query.execute ();
			}
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_subscription (): I cannot insert new subscription.\n");
		}
	}
	
	public unowned GLib.List<Feedler.Folder?> select_folders ()
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT * FROM `folders`;");
			for (SQLHeavy.QueryResult results = query.execute(); !results.finished; results.next())
			{
				Feedler.Folder fo = new Feedler.Folder ();
				fo.name = results.fetch_string (1);
				fo.parent = results.fetch_string (2);
				this.folders.append (fo);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.select_folders (): I cannot select all folders.\n");
		}
		return folders;
	}
	
	public unowned GLib.List<Feedler.Channel?> select_channels ()
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT * FROM `channels`;");
			for (var results = query.execute(); !results.finished; results.next())
			{				
				Feedler.Channel ch = new Feedler.Channel ();
				ch.id = results.fetch_int (0);
				ch.title = results.fetch_string (1);
				ch.source = results.fetch_string (2);
				ch.homepage = results.fetch_string (3);
				ch.folder = results.fetch_string (4);
				ch.type = results.fetch_string (5);
				
				var q = new SQLHeavy.Query (db, "SELECT * FROM `items` WHERE `channel`="+results.fetch_int (0).to_string ()+";");
				for (var r = q.execute(); !r.finished; r.next())
				{
					Feedler.Item it = new Feedler.Item ();
					it.title = r.fetch_string (1);
					it.source = r.fetch_string (2);
					it.author = r.fetch_string (3);
					it.description = r.fetch_string (4);
					it.publish_time = r.fetch_int (5);
					it.state = (State)r.fetch_int (6);
					ch.add_item (it);				
				}
				this.channels.append (ch);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.select_channels (): I cannot select all channels.\n");
		}
		return channels;
	}
}