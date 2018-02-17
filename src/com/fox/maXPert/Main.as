import com.fox.maXPert.maXPert;

class com.fox.maXPert.Main
{
	private static var Max:maXPert;
	
	public static function main(swfRoot:MovieClip):Void
	{
		Max = new maXPert(swfRoot);
		swfRoot.onLoad = OnLoad;
		swfRoot.OnUnload = OnUnload;
	}

	public function Main() { }

	public static function OnLoad()
	{
		Max.Load();
	}

	public static function OnUnload():Void
	{
		Max.Unload();
	}
}