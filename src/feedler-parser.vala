/**
 * feedler-parser.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.Parser : GLib.Object
{
	public enum ChannelType
	{
		RSS,
		ATOM
	}
	
	internal GLib.List<Feedler.Item?> items;
	
	public unowned GLib.List<Feedler.Item?> parse_channel_type (ChannelType type, Xml.Doc* doc)
	{		
		items = new GLib.List<Feedler.Item?> ();
		switch (type)
		{
			case ChannelType.RSS:  parse_rss (doc->get_root_element ());  break;
			case ChannelType.ATOM: parse_atom (doc->get_root_element ()); break;
			default: parse (doc); break;
		}
		return items;
	}
	
	public unowned GLib.List<Feedler.Item?> parse_type (string type, Xml.Doc* doc)
	{		
		items = new GLib.List<Feedler.Item?> ();
		switch (type)
		{
			case "rss":  parse_rss (doc->get_root_element ());  break;
			case "atom": parse_atom (doc->get_root_element ()); break;
			default: parse (doc); break;
		}
		return items;
	}
	
	public unowned GLib.List<Feedler.Item?> parse (Xml.Doc* doc)
	{
		items = new GLib.List<Feedler.Item?> ();
		Xml.Node* root = doc->get_root_element ();
		switch (root->name)
		{
			case "rss":  parse_rss (root);  break;
			case "feed": parse_atom (root); break;
			default: stderr.printf ("Undefined type of feeds."); break;
		}
		return items;
	}
	
	private void parse_rss (Xml.Node* channel)
	{
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "item")
				parse_rss_item (iter);
            else
				parse_rss (iter);
        }
	}
    
    private void parse_rss_item (Xml.Node* iitem)
    {
		Feedler.Item item = new Feedler.Item ();
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "title")
				item.title = iter->get_content ();
			else if (iter->name == "link")
				item.source = iter->get_content ();
			else if (iter->name == "author" || iter->name == "creator")
				item.author = iter->get_content ();
			else if (iter->name == "description" || iter->name == "encoded")
				item.description = iter->get_content ();
			else if (iter->name == "pubDate")
				item.time = (int)string_to_time_t (iter->get_content ());
        }
        item.state = State.UNREADED;
        if (item.author == null)
			item.author = "Anonymous";
		if (item.time == 0)
			item.time = (int)time_t ();
        items.append (item);
	}
	
	private void parse_atom (Xml.Node* channel)
	{
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "entry")
				parse_atom_item (iter);
            else
				parse_atom (iter);
        }
	}
	
	private void parse_atom_item (Xml.Node* iitem)
    {
		Feedler.Item item = new Feedler.Item ();
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "title")
				item.title = iter->get_content ();
			else if (iter->name == "link" && iter->get_prop ("rel") == "alternate")
				item.source = iter->get_prop ("href");
			else if (iter->name == "author")
				item.author = parse_atom_author (iter);
			else if (iter->name == "summary")
				item.description = iter->get_content ();
			else if (iter->name == "updated" || iter->name == "published")
				item.time = (int)string_to_time_t (iter->get_content ());
        }
        item.state = State.UNREADED;
		if (item.time == 0)
			item.time = (int)time_t ();
        items.append (item);
	}
	
	private string parse_atom_author (Xml.Node* iitem)
    {
		string name = "Anonymous";
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "name")
            {
				name = iter->get_content ();
				break;
			}
        }
        return name;
	}
	
	private time_t string_to_time_t (string date)
	{
		Soup.Date time = new Soup.Date.from_string (date);
		return (time_t)time.to_time_t ();
	}
}
