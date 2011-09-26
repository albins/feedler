/**
 * feedler-app.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

[DBus (name = "org.elementary.Feedler")]
public class Feedler.App : Granite.Application
{
	private Feedler.Window window = null;

	construct
	{
		build_data_dir = Build.DATADIR;
		build_pkg_data_dir = Build.PKGDATADIR;
		build_release_name = Build.RELEASE_NAME;
		build_version = Build.VERSION;
		build_version_info = Build.VERSION_INFO;
		program_name = "Feedler";
		exec_name = "feedler";
		app_copyright = "2011";
		application_id = "net.launchpad.Feedler";
		app_icon = "news-feed";
        app_launcher = "feedler.desktop";
		main_url = "https://launchpad.net/feedler";
		bug_url = "https://bugs.launchpad.net/feedler";
		help_url = "https://answers.launchpad.net/feedler";
		translate_url = "https://translations.launchpad.net/feedler";
		about_authors = {"Daniel Kur <daniel.m.kur@gmail.com>"};
	}

	protected override void activate ()
	{
		if (window != null)
		{
			window.present ();
			return;
		}
		
		window = new Feedler.Window ();
		window.set_application (this);
		window.show_all ();
	}
	
	public static int main (string[] args)
	{
		var app = new Feedler.App ();
		return app.run (args);
	}
}