#!/usr/bin/env zsh -f
# Purpose: enable 'sudo' via Touch ID
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2020-01-28

NAME="$0:t:r"

	# make sure your $PATH is set
if [[ -e "$HOME/.path" ]]
then
	source "$HOME/.path"
fi

	# this is what we are going to add
NEWTEXT='auth       sufficient     pam_tid.so'

	# this is the file we are going to add it to
FILE='/etc/pam.d/sudo'

IGNORE_WHITESPACE=true
ITERM_CHECK=true

	# this checks to see if the text is already in the file we want to modify
if $IGNORE_WHITESPACE; then
	grep -q 'auth \+sufficient \+pam_tid.so' "$FILE"
else
	fgrep -q "$NEWTEXT" "$FILE"
fi

	# here we save the exit code of the 'fgrep' command
EXIT="$?"

if [[ "$EXIT" == "0" ]]
then
		# if that code was zero, the file does not need to be modified
	echo "$NAME: '$FILE' already has correct entry."
else

		# if that code was not zero, we'll try to modify that file

		# this lets us use zsh's strftime
	zmodload zsh/datetime

		# get current timestamp
	TIME=$(strftime "%Y-%m-%d--%H.%M.%S" "$EPOCHSECONDS")

		# tell user what we are doing
	echo "$NAME: Need to add entry to '$FILE'"

		# get random tempfile name
	TEMPFILE="${TMPDIR-/tmp}/${NAME}.${TIME}.$$.$RANDOM.txt"

		# get comment line (this is usually the first line of the file)
	#* Only extract the first line, and only write it if it's a comment
	#// egrep '^#' "$FILE" >| "$TEMPFILE"
	read -r firstline<$FILE
	if [[ ${firstline:0:1} == '#' ]]; then 
		echo "$firstline" >| "$TEMPFILE"
		# add our custom line
		echo "$NEWTEXT" >> "$TEMPFILE"
	else
		echo "$NEWTEXT" >| "$TEMPFILE"
		echo "$firstline" >> "$TEMPFILE"
	fi

	#* Write all but the first line of the original sudo file to the temp file
	tail +2 $FILE >> "$TEMPFILE"

		# get the other lines
	#// egrep -v '^#' "$FILE" >> "$TEMPFILE"

		# tell the user what the filename is
		# useful for debugging, if needed
	# echo "$TEMPFILE"

		# set the proper permissions
		# and ownership
		# and move the file into place
	sudo chmod 444 "$TEMPFILE" \
	&& sudo chown root:wheel "$TEMPFILE" \
	&& sudo mv -vf "$TEMPFILE" "$FILE"

		# check the exit code of the above 3 commands
	EXIT="$?"

		# if the commands exited = 0
		# then we're good
	if [[ "$EXIT" == "0" ]]
	then
		echo "$NAME [SUCCESS]: 'sudo' was successfully added to '$FILE'."
	else
			# if we did not get a 'zero' result, tell the user
			# and give up
		echo "$NAME: 'sudo' failed (\$EXIT = $EXIT)"
		exit 1
	fi
fi

if $ITERM_CHECK; then
	# If iTerm is installed, tell the user what they need to change to enable this setting
	if [ -d '/Applications/iTerm.app' ]; then
		# Read iTerm preference key
		iTermPref=$( launchctl asuser "$currentUserID" sudo -u "$currentUser" defaults read com.googlecode.iterm2 BootstrapDaemon 2>/dev/null )
		
		# If preference needs to be set, show Jamf Helper window with instructions
		if [[ "$iTermPref" == "0" ]]; then
			echo "iTerm preference is already set properly. Doing nothing..."
		else
			echo "Notifying user which iTerm setting needs to be changed..."
			# Set notification description
			description="We have detected that you have iTerm installed. There is an additional step needed to enable this functionality.
	To enable TouchID for iTerm: Navigate to Preferences » Advanced » Session, then ensure \"Allow sessions to survive logging out and back in\" is set to \"No\""
			
			# Display notification
			"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
			-windowType utility \
			-title "Tech Services Notification" \
			-heading "Additional Step Required for iTerm" \
			-description "$description" \
			-alignDescription left \
			-icon "/Applications/iTerm.app/Contents/Resources/AppIcon.icns" \
			-button1 "OK" \
			-defaultButton 1
		fi
	fi
fi

exit 0
#EOF
