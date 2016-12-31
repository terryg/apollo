/* 	Javascript Audio MP3 Player (cross browser)
	Created By Jeff Baker on December 19, 2014
	Copyright (C) 2014 Jeff Baker
	www.seabreezecomputers.com/audio/
	Version 1.1 - November 30, 2015	
*/
var audio_folder = ""; // Folder where audio files are located. Example: "audio/" or same folder: ""
var tag_between_audio_files = "br"; // Change to "span" for side by side listing of audio files
var test_mode = 0; // 1 = testing mode on; 0 = testing mode off

/* DO NOT EDIT THE VARIABLES BELOW THIS LINE */

var audio_type = ""; // will be 'html5', 'wmp' or 'qt'
var audio_files = new Array(); // will hold the playlist of audio files
var test = document.getElementById('test');
var audio_player_template; // will point to 'audio_player' element
var audio_play; // will point to 'audio_play' button element
var audio_pause; // will point to 'audio_pause' button element
var audio_filename; // will point to 'audio_filename' element if exists
var audio_description; // will point to 'audio_description' element if exists
var audio_time; // will point to 'audio_time' element if exists
var audio_duration; // will point to 'audio_duration' element if exists
var audio_bar; // will point to 'audio_bar' slider control element if exists
var audio_buffer; // will point to 'audio_buffer' element if exists
var audio_files_listing; // Will point to 'audio_files_listing' element
var current_slider = false; // Variable to hold the slider currently being moved by the user

function toHTML (myString)
{
    htmlString = myString.split("&lt;").join("<");
    htmlString = htmlString.split("&gt;").join(">");
    htmlString = htmlString.split("&quot;").join("\"");
    htmlString = htmlString.split("&apos;").join("\'");
    return htmlString;
} // end function toHTML(myString)

	
function load_audio_list()
{
//	if (!document.getElementById('audio_list')) {setTimeout("load_audio_list();", 50); return;}
//	else if (!document.getElementById('audio_player')) {setTimeout("load_audio_list();", 50); return;}
	
	if (document.getElementById('audio_player'))
	{
		audio_player_template = document.getElementById('audio_player');
		audio_play = document.getElementById('audio_play');
		audio_pause = document.getElementById('audio_pause');
		audio_pause.style.display = "none"; // Make pause button invisible so only play button shows
		audio_play.onclick = function() { play_pause(); };
		audio_pause.onclick = function() { play_pause(); };
		audio_filename = document.getElementById('audio_filename') || undefined;
		audio_description = document.getElementById('audio_description') || undefined;
		audio_time = document.getElementById('audio_time') || undefined;
		audio_duration = document.getElementById('audio_duration') || undefined;	
		// Slider controls
		audio_bar = document.getElementById('audio_bar') || undefined;
		audio_buffer = document.getElementById('audio_buffer') || undefined;
	}
	else
		document.write("<p>div with id='audio_player' does not exist");
	// Loop through textareas with class="audio_list"
	var audio_file_position = 0;
	var elems = document.getElementsByTagName('textarea');
	for (var audio_ti=0; audio_ti < elems.length; audio_ti++)
	if (elems[audio_ti].className.match(/\baudio_list\b/i))
	{
		var audio_list = elems[audio_ti].innerHTML;	
		// Remove all CRs (13) from IE's textarea
		audio_list = audio_list.replace(/\r/gi, "");
		// Remove whitespace including carriage returns from beginning and end of textarea
		audio_list = audio_list.replace(/^\s+|\s+$/g,'');
		// Split songs in textarea by line feed (LF)
		var audio_array = audio_list.split('\n');
		// Create div to hold listing of audio files
		audio_files_listing = document.createElement('div');
		var audio_textarea = elems[audio_ti];
		// Display after textarea tag
		audio_textarea.parentNode.insertBefore(audio_files_listing, audio_textarea.nextSibling); 
		// Loop through array and build description and player controls
		for (var i = 0; i < audio_array.length; i++)
		{
			var temp = audio_array[i].split('##');
			if (typeof temp[1] != 'undefined') var desc = toHTML(temp[1]); else var desc = "";
			audio_files[audio_file_position] = { file: temp[0],
								description: desc,
								audio: undefined};
			load_audio_skin(audio_file_position);
			audio_file_position++;
		}
	}
	if (audio_file_position == 0)
		document.write("<p>textarea with class='audio_list' does not exist");
}  // end function load_audio_list()


function load_audio_skin(audio_file_position)
{	
	var audio_player = audio_player_template.cloneNode(true);
	audio_player.id += "_"+audio_file_position; // Add _i to id
	audio_player.style.display = "inline-block";
	var children = audio_player.getElementsByTagName('*');
	for (var i=0; i<children.length; i++)
	if (children[i].id)
	{
		if (children[i].id.match(/audio_play$|audio_pause$/i))
			children[i].onclick = function() { play_pause(audio_file_position); };
		children[i].id += "_"+audio_file_position;// Add _i to id of all children
	}
	audio_files_listing.appendChild(audio_player);
	var audio_pause = document.getElementById("audio_pause_"+audio_file_position);
	var audio_play = document.getElementById("audio_play_"+audio_file_position);
	if (audio_bar)
		slider_setup(document.getElementById('audio_bar_'+audio_file_position), slider_callback);
	var between_tag = document.createElement(tag_between_audio_files);
	audio_player.parentNode.insertBefore(between_tag, audio_player.nextSibling); // Display between tag after listing
	if (audio_filename) 
		document.getElementById("audio_filename_"+audio_file_position).innerHTML = audio_files[audio_file_position].file;	
	if (audio_description) 
		document.getElementById("audio_description_"+audio_file_position).innerHTML = audio_files[audio_file_position].description;
	if (audio_type == "html5")
	{
		var audio = document.createElement('audio');
		audio.id = "audio_"+audio_file_position;
		audio.preload = "metadata"; // IE ignores "none"
		if (test_mode)
		{
			audio.controls = "controls";
			audio.style.position = "absolute";
			audio.style.left = "450px";
			audio.style.top = 100*audio_file_position+"px";
			document.body.insertBefore(audio, document.body.firstChild);
		}
		audio.src = audio_folder+audio_files[audio_file_position].file;
		//audio.load(); // Only way to get iOS to display duration. But causes all songs to load. Too many songs and them some don't load at all
		audio_files[audio_file_position].audio = audio;	
		audio_files[audio_file_position].loaded = 1; // loaded var is created to overcome Chrome's limitation of downloading only 6 to 8 files at a time
		audio.onended = function() { 
									audio_pause.style.display = "none";	
									audio_play.style.display = "inline-block";
									};
		// When song starts downloading update buffer
		audio.onloadstart = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("loadstart", function() {write_event(event); update_buffer_progress(audio_file_position); update_audio_time(audio_file_position); }, false);
		audio.ondurationchange = function(event) { write_event(event); update_audio_time(audio_file_position); update_audio_duration(audio_file_position); update_buffer_progress(audio_file_position); };
		audio.addEventListener("durationchange", function() {write_event(event); update_audio_time(audio_file_position); update_audio_duration(audio_file_position); update_buffer_progress(audio_file_position);}, false);
		audio.onloadedmetadata = function(event) { write_event(event); update_buffer_progress(audio_file_position); };	
		audio.addEventListener("loadedmetadata", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		audio.onloadeddata = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("loadeddata", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		audio.oncanplay = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("canplay", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		audio.oncanplaythrough = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("canplaythrough", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		audio.onprogress = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("progress", function() {write_event(event); update_buffer_progress(audio_file_position);}, false); // buffer in iOS
		audio.onsuspend = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("suspend", function() {write_event(event); update_buffer_progress(audio_file_position); }, false);
		audio.onemptied = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("emptied", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		audio.onwaiting = function(event) { write_event(event); update_buffer_progress(audio_file_position); };
		audio.addEventListener("waiting", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		
		//audio.addEventListener("loadstart", function() {write_event(event); update_buffer_progress(audio_file_position);}, false);
		//setInterval(function(){ update_buffer_progress(audio_file_position); }, 500);
		// When song changes time update current time display
		audio.ontimeupdate = function() { update_audio_time(audio_file_position); };
		audio.addEventListener("timeupdate", function() {write_event(event); update_audio_time(audio_file_position);}, false); // Version 1.1 iOS fix
		//update_audio_time(audio_file_position);
	}
	else
	{
		// First create offscreen div to hold offscreen player
		var audio_div = document.createElement('div');
		audio_div.id = "audio_div_"+audio_file_position;
		audio_div.style.position = "absolute";
		if (test_mode)
		{
			audio_div.style.left = "450px";
			audio_div.style.top = 100*audio_file_position+"px";
		}
		else
		{	
			audio_div.style.left = "-1000px";
			audio_div.style.top = "-1000px";
		}
		document.body.insertBefore(audio_div, document.body.firstChild);
		if (audio_type == "wmp") // windows media player
		{
			audio_div.innerHTML = '<object type="audio/wav" id="audio_'+audio_file_position+'"'
								+ 'classid="clsid:6BF52A52-394A-11d3-B153-00C04F79FAA6"'
								+ 'height="100px;" width="200px;">'
				  				//+ '<param name="autostart" value="false">'
				  				//+ '<param name="hidden" value="true">'
				  				//+ '<param name="url" value="'+audio_folder+audio_files[audio_file_position].file+'">'
							+ '</object>';
			var audio = document.getElementById('audio_'+audio_file_position);
			audio.settings.autoStart = true;
			audio.URL = audio_files[audio_file_position].file;
			audio_files[audio_file_position].audio = audio;
			
			audio.attachEvent("PlayStateChange",function(newState) {
				write_event("id: " + audio_file_position + " playState: " + newState);
				if (newState == 8) // MediaEnded	Media item has completed playback.
    			{
    				audio_pause.style.display = "none";	
					audio_play.style.display = "inline-block";	
    			}
			});
			audio.attachEvent("OpenStateChange",function(newState) {
				write_event("id: " + audio_file_position + " openState: " + newState); 
    			if (newState == 13) // Ready	duration is now available
    			{
    				update_audio_duration(audio_file_position);	
    				update_audio_time(audio_file_position);
    				// Pause audio playback immediately because we just wanted to get duration of audio track
    				audio.controls.pause();
    			}
			});
			audio.attachEvent("StatusChange",function() {
    			var status = audio.status;
				write_event("id: " + audio_file_position + " status: " + status); 
			});
    		// When song starts downloading update buffer
			audio.attachEvent("Buffering",function(Start) {
    			write_event("id: " + audio_file_position + " Buffer: " + Start); 
				if (Start) update_buffer_progress(audio_file_position); });
    		
		
		}
		else // quicktime
		{
			audio_div.innerHTML = '<embed id="audio_'+audio_file_position+'"' 
			                                  + 'name="sound" src="'+audio_files[audio_file_position].file+'" volume="100"'
		    					+ 'autostart="false" enablejavascript="true" type="audio/wav"'
								+ 'height="16" width="200" postdomevents="true">'
								+ '</embed>';
			var audio = document.getElementById('audio_'+audio_file_position);
			audio_files[audio_file_position].audio = audio;
			audio.addEventListener("qt_progress", function(event) { write_event(event); update_buffer_progress(audio_file_position); }, false);
			audio.addEventListener("qt_begin", function(event) { write_event(event); update_buffer_progress(audio_file_position); update_audio_time(audio_file_position); update_audio_duration(audio_file_position); }, false);
			audio.addEventListener("qt_loadedmetadata", function(event) { write_event(event);  }, false);
			audio.addEventListener("qt_durationchange", function(event) { write_event(event);  }, false);
			audio.addEventListener("qt_loadedfirstframe", function(event) { write_event(event);  }, false);
			audio.addEventListener("qt_canplay", function(event) { write_event(event); }, false);
			audio.addEventListener("qt_canplaythrough", function(event) { write_event(event);  }, false);
			
			//update_audio_duration(audio_file_position);
			audio.addEventListener("qt_timechanged", function(event) { write_event(event); update_audio_time(audio_file_position); }, false);
			audio.addEventListener("qt_ended", function(event) { 
									write_event(event);
									audio_pause.style.display = "none";	
									audio_play.style.display = "inline-block";
									}, false);
		}
	}
}	// end function load_audio_skin()


function detect_audio_type()
{
	/* 	First we need to create audio element to see if the browser
		supports the audio tag
	*/	
	var audio = document.createElement('audio'); 
	if (!!audio.canPlayType && audio.canPlayType('audio/mpeg') != "") // blank means no mp3 support
	{
		audio_type = "html5"; // IE 9+, Firefox 31+, Chrome, Safari 3.1+, Opera 14+, iOS, Android
	}	
	else 
	{
		/* Unfortunately if the browser does not support html audio tag or mp3 in the audio tag (ff < 15)
			then we have to detect the browser for using Quicktime (FF/Safari/Chrome) or 
			Windows Media Player (IE/Netscape)
		*/	
		if (detect_browser() == "MSIE" || detect_browser() == "Netscape")
		{
			audio_type = "wmp"; // IE WMP Player:	
		}
		else // if firefox/safari/chrome
		{
			audio_type = "qt"; // QuickTime
		}
	}
	write_event("audio_type = "+audio_type);
	load_audio_list();
	
} // end detect_audio_type()

function write_event(event)
{
	if (test_mode)
	{
		var info = event.type || event;
		if (document.getElementById('test'))
			document.getElementById('test').innerHTML += info + "; ";
		if (typeof console == "object")
			console.log(info);
	}
} // end function write_event(event)


function pause_all_songs()
{
	for (var i = 0; i < audio_files.length; i++)
	{
		var audio = audio_files[i].audio;	
		var audio_pause = document.getElementById("audio_pause_"+i);
		var audio_play = document.getElementById("audio_play_"+i);
		audio_pause.style.display = "none";	
		audio_play.style.display = "inline-block";
		if (audio_type == "html5")
		{
			audio.pause();	
		}
		else if (audio_type == "wmp")
		{
			audio.controls.pause();
			clearInterval(audio_files[i].interval);
		}
		else // qt
		{
			try { audio.Stop();} catch(err) { /* file not playing yet */ };
			clearInterval(audio_files[i].interval);
		}
	}	

} // end function pause_all_songs()


function play_pause(audio_file_position)
{
	var audio = audio_files[audio_file_position].audio;
	var audio_pause = document.getElementById("audio_pause_"+audio_file_position);
	var audio_play = document.getElementById("audio_play_"+audio_file_position);
	if (audio_pause.style.display.match(/none/i)) // if currently pausing audio
	{
		pause_all_songs(); // Make sure all other songs are paused first!
		audio_pause.style.display = "inline-block";	
		audio_play.style.display = "none";
		if (audio_type == "html5")
		{
			if (audio_files[audio_file_position].loaded == 2) // if we have never pressed play then load the song first
			{
				audio.src = audio_files[audio_file_position].file;
				audio.load();
				audio_files[audio_file_position].loaded = 3;
			}
			//audio.onprogress = function() { update_buffer_progress(audio_file_position); };
			audio.play();	
		}
		else if (audio_type == "wmp")
		{
			audio.controls.play();
			audio_files[audio_file_position].interval = setInterval(function(){ update_audio_time(audio_file_position); }, 1000);
		}
		else // qt
		{
			if (audio.GetPluginStatus())
			if (audio.GetPluginStatus() != "Playable" && audio.GetPluginStatus() != "Complete")
			{
				setTimeout( function() { play_pause(audio_file_position); }, 50);
				return;
			}
			audio.Play();
			audio_files[audio_file_position].interval = setInterval(function(){ update_audio_time(audio_file_position); }, 1000);	
		}
	}
	else // if currently playing audio
	{
		audio_pause.style.display = "none";	
		audio_play.style.display = "inline-block";
		if (audio_type == "html5")
		{
			//audio.onprogress = null;
			audio.pause();	
		}
		else if (audio_type == "wmp")
		{
			audio.controls.pause();
			clearInterval(audio_files[audio_file_position].interval);
		}	
		else // qt
		{
			audio.Stop();
			clearInterval(audio_files[audio_file_position].interval);
		}
	}
} // end function play_pause(audio_file_position)


function update_buffer_progress(audio_file_position) 
{
	if (typeof audio_file_position == "undefined") return;
	var audio = audio_files[audio_file_position].audio;
	var audio_bar = document.getElementById("audio_bar_"+audio_file_position);
	var audio_duration = document.getElementById("audio_duration_"+audio_file_position);
	if (audio_type == "html5")
	{
		var buffered = (audio.buffered.length > 0 ? audio.buffered.end(0) : 0);
		var duration = audio.duration;
		var percent = (buffered / duration) * 100;
	}
	else if (audio_type == "wmp")
	{
		var percent = audio.network.bufferingProgress;
		write_event("bufferingProgress: " + percent);
		if (percent != 100)
			setTimeout( function() { update_buffer_progress(audio_file_position); }, 10);
	}
	else // qt
	{
		var percent = parseInt((audio.GetMaxTimeLoaded() / audio.GetDuration()) * 100); 
		write_event("GetMaxTimeLoaded(): " + percent);
	}

        if (audio_buffer)
	{
		change_slider(audio_bar, "buffer", percent); 
		//audio_buffer.style.width = percent+"%";
	}
	
} // end update_buffer_progress(audio_file_position) 


function update_audio_duration(audio_file_position)
{
	var audio = audio_files[audio_file_position].audio;
	var audio_duration = document.getElementById("audio_duration_"+audio_file_position);
	if (audio_duration)
	{
		if (audio_type == "html5")
		{	
			var duration = audio.duration;
			// Overcome Chrome's limitation of downloading only 6 to 8 files at a time
			// by putting src to "" after getting duration
			if (audio_files[audio_file_position].loaded == 1 && isNaN(audio.duration)) // Version 1.1 - Added isNan(audio.duration)
			{
				audio_files[audio_file_position].loaded = 2;
				audio.src = "";	
			}
		}
		else if (audio_type == "wmp")
		{
			var duration = audio.currentMedia.duration;
		}
		else // qt
		{
			var duration = audio.GetDuration();
			duration = Math.floor(duration*(1/audio.GetTimeScale()));  // converts to seconds
		}
		var time = Math.round(duration);
		var mins = Math.floor(time / 60);
		var secs = time - (mins * 60);	
		if (secs < 10) secs = "0" + secs;
		var display_time = mins + ':' + secs;
		audio_duration.innerHTML = display_time;	
	}
} // end function update_audio_duration(audio_file_position)


function update_audio_time(audio_file_position)
{
	var audio = audio_files[audio_file_position].audio;
	var audio_bar = document.getElementById("audio_bar_"+audio_file_position);
	var audio_time = document.getElementById("audio_time_"+audio_file_position);
	var audio_remaining = document.getElementById("audio_remaining_"+audio_file_position);
	if (audio_type == "html5")
	{
		var current_time = audio.currentTime;
		var duration = audio.duration;
	}
	else if (audio_type == "wmp")
	{
		var current_time = audio.controls.currentPosition;
		var duration = audio.currentMedia.duration;
	}
	else // qt
	{
		var current_time = audio.GetTime();
		current_time = Math.floor(current_time*(1/audio.GetTimeScale()));  // convert to seconds
		var duration = audio.GetDuration();
		duration = Math.floor(duration*(1/audio.GetTimeScale()));  // converts to seconds
	}
	if (audio_time)
	{
		var time = Math.round(current_time);
		var mins = Math.floor(time / 60);
		var secs = time - (mins * 60);	
		if (secs < 10) secs = "0" + secs;
		var display_time = mins + ':' + secs;
		audio_time.innerHTML = display_time;
	}
	if (audio_remaining)
	{
		var time = Math.round(duration - current_time);
		var mins = Math.floor(time / 60);
		var secs = time - (mins * 60);	
		if (secs < 10) secs = "0" + secs;
		var display_remaining = mins + ':' + secs;
		audio_remaining.innerHTML = display_remaining;
	}	
	if (audio_bar)
	{
		var percent = (current_time / duration) * 100;
		change_slider(audio_bar, "slider", percent);
	}
        if ((current_time/duration)*100 == 100)
        {
	    window.location.reload(true);
        }
	
}


function detect_browser()
{
	var browser_name = navigator.userAgent;
	// We have to check for Opera first because
	// at the beginning of the userAgent variable
	// Opera claims it is MSIE. 
	
	if (browser_name.indexOf("Opera")!= -1)
		browser_name = "Opera";
	else if (browser_name.match(/(iPad|iPhone|iPod|Android|Silk)/gi))
		browser_name = "Mobile";
	else if (browser_name.indexOf("Chrome")!= -1)
		browser_name = "Chrome";
	else if (browser_name.indexOf("Firefox")!= -1)
		browser_name = "Firefox";
	else if (browser_name.indexOf("MSIE")!= -1)
		browser_name = "MSIE";
	else if (browser_name.indexOf("Netscape")!= -1)
		browser_name = "Netscape";
	else if (browser_name.indexOf("Safari")!= -1)
		browser_name = "Safari";
	
	return browser_name;
	

} // end function detect_browser()

function slider_callback(slider_bar, percentage)
{
	//var audio_file_position = slider_bar.id.split("_")[2];
	var audio_file_position = slider_bar.id.replace(/\D/g, "");
	var audio = audio_files[audio_file_position].audio;
	if (audio_type == "html5")
		var duration = audio.duration;
	else if (audio_type == "wmp")
		var duration = audio.currentMedia.duration;
	else // qt
		var duration = Math.floor(audio.GetDuration()*(1/audio.GetTimeScale()));
	
	var time = (percentage * .01) * duration; // time = (50 *. 01) = .50 * 60 = 30;
	
	if (audio_type == "html5")
		audio.currentTime = time; 
	else if (audio_type == "wmp")
		audio.controls.currentPosition = time;
	else // qt
		audio.SetTime(audio.GetTimeScale() * time); 
}

// DO NOT EDIT THE VARIABLES BELOW


function slider_setup(slider_bar, callback)
{
	// This function sets up the mouse and touch controls for each slider on the page
	/*slider_bar.onmousedown = function(event) { slider(event, slider_bar); };
	document.onmouseup = function(event) { slider(event, slider_bar); };
	document.onmousemove = function(event) { slider(event, slider_bar); };*/
	if(typeof callback === "undefined")
		callback = null;
	if (document.addEventListener) // Chrome, Safari, FF, IE 9+
	{
		slider_bar.addEventListener('mousedown',function(event) { slider(event, slider_bar, callback); },false);
		document.addEventListener('mouseup',function(event) { slider(event, slider_bar, callback); },false);
		document.addEventListener('mousemove',function(event) { slider(event, slider_bar, callback); },false);
		slider_bar.addEventListener('touchstart',function(event) { slider(event, slider_bar, callback); },false);
		document.addEventListener('touchend',function(event) { slider(event, slider_bar, callback); },false);
		document.addEventListener('touchmove',function(event) { slider(event, slider_bar, callback); },false);
	}
	else // IE < 9
	{
		slider_bar.attachEvent('onmousedown',function(event) { slider(event, slider_bar, callback); });
		document.attachEvent('onmouseup',function(event) { slider(event, slider_bar, callback); });
		document.attachEvent('onmousemove',function(event) { slider(event, slider_bar, callback); });
	}
}


function slider(event, bar, callback)
{
	if (!event) event = window.event; // for older IE <= 9
	//var bar = event.target || event.srcElement; // The element being clicked on (FF || IE)
	if (event.type == "mousedown" || event.type == "touchstart") current_slider = bar;
	else if (event.type == "mouseup" || event.type == "touchend") current_slider = false; 
	if ((event.type == "mousemove"  || event.type == "mouseup") && !current_slider) return; 
	if ((event.type == "touchmove"  || event.type == "touchend") && !current_slider) return; 
	// get current screen scrollTop and ScrollLeft  
	var scrollLeft = document.body.scrollLeft || document.documentElement.scrollLeft;
	var scrollTop = document.body.scrollTop || document.documentElement.scrollTop;
	var	x = Math.round(event.clientX + scrollLeft - current_slider.offsetLeft);
	var	y = Math.round(event.clientY + scrollTop - current_slider.offsetTop);
	if (event.type.match(/touch/i))
	{
		x = event.touches[0].pageX - current_slider.offsetLeft;
		y = event.touches[0].pageY - current_slider.offsetTop;
	}
	event.preventDefault(); // Prevents browsers from highlighting and touch devices from scrolling
	
	// Change vertical slider position
	if (current_slider.className.match(/vert/i) || current_slider.id.match(/vert/i))
	{
		var perc = Math.round((y / current_slider.offsetHeight) * 100);
		perc = 100 - perc; // Make vertical bar go up instead of down
	}
	else // Change horizontal slider position
		var perc = Math.round((x / current_slider.offsetWidth) * 100);
	
	if (perc < 0) perc = 0; if (perc > 100) perc = 100;
		
	change_slider(current_slider, "slider", perc);
	
	if (typeof callback === "function")
		callback(current_slider, perc);

}


function change_slider(bar, part, perc)
{
	if (perc < 0) perc = 0; if (perc > 100) perc = 100;
	if (bar.className.match(/vert/i) || bar.id.match(/vert/i))
		vert_perc = 100 - perc; // Make vertical bar control go up instead of down
		
	var children = bar.getElementsByTagName('*');
	for (var i=0; i<children.length; i++)
	if (children[i].className || children[i].id)
	{
		if (part.match(/buffer/i))
		{
			if (children[i].className.match(/buffer/i))
				if (bar.className.match(/vert/i) || bar.id.match(/vert/i))
					children[i].style.height = perc + "%";
				else
					children[i].style.width = perc + "%";	
		}
		else if (part.match(/slider/i))
		{
			if (children[i].className.match(/control/i))
			{
				if (bar.className.match(/vert/i) || bar.id.match(/vert/i))
					children[i].style.height = perc + "%";
				else
					children[i].style.width = perc + "%";
			}
			else if (children[i].className.match(/knob/i))
			{
				if (bar.className.match(/vert/i) || bar.id.match(/vert/i))
				{
					var y = Math.round((vert_perc / 100) * bar.offsetHeight-(children[i].offsetHeight/2));
					if (y < 0) y = 0; if (y > bar.offsetHeight - children[i].offsetHeight)
						y = bar.offsetHeight - children[i].offsetHeight;	
					children[i].style.top = y - 1 + "px";	
				}
				else
				{
					var x = Math.round((perc / 100) * bar.offsetWidth-(children[i].offsetWidth/2));
					if (x < 0) x = 0; if (x > bar.offsetWidth - children[i].offsetWidth)
						x = bar.offsetWidth - children[i].offsetWidth;
					children[i].style.left = x - 1 + "px";	
				}	
			}
		}	
	}
}

detect_audio_type();
