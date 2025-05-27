<div align="center"><img width=150 src="https://github.com/ChifiSource/image_dump/blob/main/olive/0.1/extensions/olivedbrowse.png">
</div>

`OliveDocBrowser` is a Markdown documentation browser built directly into your `Olive` session! 
- Say hello to *one* tab of docs **and** *one* tab of code inside the same notebook!
<img src="https://github.com/ChifiSource/image_dump/blob/main/olive/0.1/hlsc/Screenshot%20from%202025-05-27%2010-18-02.png"></img>
## installing
To 'quick install' this extension, use the `+` button in your `olive` home directory (hopefully you are root,) and enter `OliveDocBrowser`. (`OliveDocBrowser` in place of `OliveDefaults` below)

<img src="https://github.com/ChifiSource/image_dump/raw/main/olive/doc92sc/ext.png">

Alternatively, there are manual methods of installation, you can read more about these on `ChifiDocs` [here](https://chifidocs.com/olive/Olive/extending-olive) and in the `Olive` README [here](https://github.com/ChifiSource/Olive.jl#installing-extensions). If you are using `Olive` `.1.3` *+* then you can load `OliveDocBrowser` before calling `start` with `using OliveDocBrowser`.
## usage
After installing the extension, resourcing your `olive` module (via the resource button or by restarting,) and refreshing the page there should be a new additional button on the topbar. Clicking this button will yield a new menu. At the top, we select modules to browse documentation for. For any *nested* modules that we want docs for, we simply `export` them to load them into this viewer.
