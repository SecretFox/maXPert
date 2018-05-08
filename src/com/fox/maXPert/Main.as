import com.fox.maXPert.maXPert;

class com.fox.maXPert.Main {

	public static function main(swfRoot:MovieClip):Void {
		var Max = new maXPert(swfRoot);
		swfRoot.onLoad =  function() { Max.Load();};;
		swfRoot.OnUnload =  function() { Max.Unload(); };;
	}
	public function Main() { }
}