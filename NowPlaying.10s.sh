#!/usr/local/bin/zsh
#exec 2> /dev/null

# <bitbar.title>Now playing</bitbar.title>
# <bitbar.version>v1.1</bitbar.version>
# <bitbar.author>Adam Kenyon</bitbar.author>
# <bitbar.author.github>adampk90</bitbar.author.github>
# <bitbar.desc>Shows and controls the music that is now playing. Currently supports Spotify, Music, and Vox.</bitbar.desc>
# <bitbar.image>https://pbs.twimg.com/media/CbKmTS7VAAA84VS.png:small</bitbar.image>
# <bitbar.dependencies></bitbar.dependencies>
# <bitbar.abouturl></bitbar.abouturl>

apps=(Spotify Music)
script=$0

BitBarDarkMode=$(osascript -e "tell application \"System Events\" to tell appearance preferences
                get properties
        	            set currentValue to dark mode
        	        return currentValue
                end tell")

if [ $BitBarDarkMode ]; then
  COLOR0="#666666"
  COLOR1="#ffffff"
  COLOR2="#666666"
  COLOR3="#333333"
else
  COLOR0="#333333"
  COLOR1="#000000"
  COLOR2="#666666"
  COLOR3="#999999"
fi

function geek_visible {
	#/usr/bin/osascript -e "try
	#	tell application \"GeekTool Helper\"
	#	set image url of image geeklet named \"NowPlaying\" to \"file://$2\"
	#	set visible of image geeklet named \"NowPlaying\" to \"$1\"
	#	end tell
	#on error
	#	set message to \"Define a image Geeklet called 'NowPlaying' for BitBar to display an image on the desktop\"
	#	display dialog message
	#end try
	#"
}

function check_which_running {
	for i in "${apps[@]}"; do
		# is the app running?
		app_state=$(osascript -e "application \"$i\" is running")
		if [[ "$app_state" = "true" ]]; then
			#app_playing=$(osascript -e "tell application \"$i\" to player state as string")
			echo $i
			return
		fi
	done
	geek_visible "false" "fakefile"
	echo " | color=$COLOR0 size=14"
	exit
}

function control_player {
# open a specified app
if [ "$1" = "open" ]; then
	osascript -e "tell application \"$2\" to activate"
	exit
fi
# play/pause
if [ "$1" = "play" ] || [ "$1" = "pause" ]; then
	osascript -e "tell application \"$2\" to $1"
	exit
fi
# next/previous
if [ "$1" = "next" ] || [ "$1" = "previous" ]; then
	osascript -e "tell application \"$2\" to $1 track"
	# tell spotify to hit "Previous" twice so it actually plays the previous track
	# instead of just starting from the beginning of the current one
	if [ "$playing" = "Spotify" ] && [ "$1" = "previous" ]; then
		osascript -e "tell application \"$2\" to $1 track"
	fi
	osascript -e "tell application \"$2\" to play"
	exit
fi
}

function write_image {
	if [ -f "$imgFile" ]; then
	    base64img=$(base64 < "$imgFile")
	else
		if [ $app = "Music" ]; then
			/usr/bin/osascript <<-EOF
			set tmpName to POSIX file "$1"
			try
				tell application "Music"
					tell artwork 1 of current track
					set srcBytes to raw data
					end tell
			    end tell

				tell application "System Events"
					        try
							set outFile to open for access tmpName with write permission
					        set eof outFile to 0
					        write srcBytes to outFile
					        close access outFile
							end try

				end tell
			on error errText
				""
			end try
			EOF
		fi

		if [ $app = "Spotify" ]; then
			curlAddress=$(/usr/bin/osascript <<-EOF
			tell application "Spotify"
			return artwork url of current track
			end tell
			EOF
			);
			curl -s -o $imgFile $curlAddress
		fi
		/usr/local/bin/convert $imgFile -set units PixelsPerInch -density 72 -resize 300x300^\> $imgFile
		base64img=$(base64 < "$imgFile")

	fi

}

function get_track_info {
	# determine the track and artist
	track_query="name of current track"
	artist_query="artist of current track"
	album_query="album of current track"
	# Vox uses a different syntax for track and artist names
	if [ "$app" = "Vox" ]; then
		track_query="track"
		artist_query="artist"
		album_query="album"
	fi

    track=$(osascript -e "tell application \"$app\" to $track_query")
	artist=$(osascript -e "tell application \"$app\" to $artist_query")
	album=$(osascript -e "tell application \"$app\" to $album_query")

	if [ "$app" = "Music" ]; then
	imgFormat=$(osascript <<-EOF
		try
		tell application "Music"
			tell artwork 1 of current track
				if format is JPEG picture then
				    return ".jpg"
				else
				    return ".png"
				end if
			end tell
	    end tell
		on error
			return ""
		end try
		EOF
		)
	fi

	imgFile=$(osascript -e "POSIX path of (path to temporary items from user domain)")
	imgFile+=$(echo $artist $album $imgFormat | sed "s/[^a-zA-Z0-9\.]//g")

}

function output_menu_info {
	echo "---"
	echo "◼︎  Stop| color=$COLOR0 size=14 bash='$script' param1=pause param2=$app refresh=true terminal=false"
	echo ">> Next | color=$COLOR0 size=14 bash='$script' param1=next param2=$app refresh=true terminal=false"
	echo "<< Previous | color=$COLOR0 size=14 bash='$script' param1=previous param2=$app refresh=true terminal=false"

	#output the track and artist
	echo "---"

	if [ "$track" != "no track selected" ] && [ "$base64img" != "" ]; then
	    echo "| image=$base64img bash='$0' param1=open terminal=false"
	fi

	echo "$track | color=$COLOR1"
	echo "$artist | color=$COLOR2"
	echo "$album | size=14 color=$COLOR3 length=30"
}

##########################################################################################

app=$(check_which_running)


if [[ "$app" == "Music" ]] || [[ "$app" == "Spotify" ]]; then
    playerState=$(osascript -e "tell application \"$app\" to player state as string")
fi

if (( ${1} )) && (( ${2} )); then
control_player $1 $2
fi


if [[ "$playerState" == "playing" ]] || [[ "$playerState" == "paused" ]]; then
	get_track_info

    artist=${artist:gs/Various\ Artists/}
    menubarArtist=${artist:gs/Various/}
    if [ "$menubarArtist" != "" ] && [ "$menubarArtist" != "\n" ]; then
    fi

	if [ $playerState = "playing" ]; then
		echo "$menubarArtist - $track | color=$COLOR3 size=14 length=50"
	else
		echo " | color=$COLOR0 size=14"
	fi
	write_image $imgFile
	output_menu_info
	geek_visible "true" $imgFile

else

	echo " | color=$COLOR0 size=14"
	echo "---"
	echo "> Play | color=$COLOR0 size=14 bash='$0' param1=play param2=$app refresh=true terminal=false"
	geek_visible "false"

fi
