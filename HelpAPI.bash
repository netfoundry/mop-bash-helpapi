#!/usr/bin/env bash
###################################################################################################################
# HelpAPI - Help the user interact with the NetFoundry API system.
# Written by Nic Fragale @ NetFoundry.
MyWarranty='This program comes without any warranty, implied or otherwise.'
MyLicense='Use of this program falls under the Apache V2 license.'
MyGitHubURL='https://github.com/netfoundry/mop-bash-helpapi'
MyGitHubRAWURL='https://raw.githubusercontent.com/netfoundry/mop-bash-helpapi/master/HelpAPI.bash'
###################################################################################################################

#######################################################################################
# Main Variables - Global Editable
#######################################################################################
CheckGITVersion="TRUE" # A flag to check the GIT version available and alert the user if the runtime is a different version than it. (TRUE=CHECK , FALSE=BYPASS)
BulkCreateLogRegKey="FALSE" # Tell the system how to store returned REGKEYs from creation. (TRUE=LOG , FALSE=NOLOG)
MaxIdle="600" # Seconds max without a touch will trigger an exit.
CURLMaxTime="20" # Seconds max without a response until CURL quits.
SAFEDir="${HOME}/NetFoundrySAFE" # A variable that holds the location of the SAFE directory.

#######################################################################################
# DO NOT EDIT BELOW THIS LINE!
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# Main Variables - Global Static
#######################################################################################
SECONDS="0" # Seconds counting since launched.
ParentPID="$$" # The PID of this script (AKA the parent that spawns subprocesses).
MyPkgMgr="UNKNOWN" # The OS of the running system.
MyName=( "${0##*/}" "${0}" ) # Name (0/Base 1/Full) of the program.
TmpDir="/tmp" # The temporary directory this program will use.
APIMOP="production"
TeachMode="FALSE" # A special flag that allows emit of certain messages.
DebugInfo="FALSE" # A special flag that shows extra data from the API system.
InputProcessing="FALSE" # A special flag that is used internally by the program to handle standard-in.
export Normal="0" Bold="1" Dimmed="2" Invert="7" # Trigger codes for BASH.
export FBlack="30" FRed="31" FGreen="32" FYellow="33" FBlue="34" FMagenta="35" FCyan="36" FLiteGray="37" # Foreground color codes for BASH.
export FDarkGray="90" FLiteRed="91" FLiteGreen="92" FLiteYellow="93" FLiteBlue="94" FLiteMagenta="95" FLiteCyan="96" FWhite="37" # Foreground color codes for BASH.
export BBlack="40" BRed="41" BGreen="42" BYellow="43" BBlue="44" BMagenta="45" BCyan="46" BLiteGray="47" # Background color codes for BASH.
export BDarkGray="100" BLiteRed="101" BLiteGreen="102" BLiteYellow="103" BLiteBlue="104" BLiteMagenta="105" BLiteCyan="106" BWhite="107" # Background color codes for BASH.
export ValidIP="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" # REGEX to match IPv4 addresses.
export ValidPrefix="(3[01]|[12][0-9]|[1-9])" # A REGEX string to match a valid CIDR number.
export ValidNumber="^[0-9]+$"
export AlphaArray=( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ) # All letters in the English alphabet (A-Z).
LastText="" # A storage variable for the last context string sent into the printer function.
CurrentPath="/" # A storage variable for the path in the program - a breadcrumb trail.
LimitFancy="FALSE" # A flag that hold whether the program can output certain screen effects.
BulkImportFile="NOTSET" # A variable that holds the location of the Bulk Import File.
SAFEFile="UNSET" # A variable that holds the name/org of the SAFE file.
ThisMode="INTERACTIVE" # A variable that holds the work mode of the program.
QuietPrint="FALSE" # A variable that holds the print flag for quiet output.
NFN_BEARER=( "UNSET" "DESTROY" ) # A variable that contains the Console Bearer Token and a flag to destroy or not.
NewLine='
'

#######################################################################################
# Helper Functions - Basics
#######################################################################################
#################################################################################
# Exit trapping and input handling.
trap 'GoToExit 2' SIGINT SIGTERM
trap 'GoToExit 5' SIGHUP
trap 'GoToExit 6 "Your session timed out after ($((MaxIdle/60))m) of inactivity. (PARENTPID=${ParentPID:-ORPHAN})"' USR1
stty -echo -icanon time 0 min 0

function GoToExit() {
	# 1/[0=NOERROR 1=NEGATIVE 2=USEREXITCTRLC 3=CRITICALEXIT 4=NOERRORNONINTERATIVE 5=FASTQUIT 6=TIMEOUT 7=AUTOMATIONDONE 8=QUITLEAVEBEARER 9(+)=OTHER] 2/MESSAGE
	local ControlOptions
	trap '' SIGINT SIGTERM # Ignore further CTRL+C events.
	tput cnorm # Ensure cursor is visible.
	stty sane 2>/dev/null # Return sanity to the input processing.
	InputProcessing="TRUE" # Tell input functions not to modify the standard-in.

	# The user pressed CTRL+C to get here.
	if [[ "${1}" -eq 2 ]]; then

		tput cub 2 # Move the cursor back two chars.
		tput ech 2 # Erase two chars (^C).
		tput smcup # Save screen contents.

		if [[ ${NFN_BEARER[0]:-UNSET} == "UNSET" ]]; then
			ControlOptions=( \
				"Modify Global Search Filter"
				"Change Networks"
				"Organization Search"
				"Network Search"
				"Toggle Fancy Printing"
				"Toggle Debug Messaging"
				"Toggle Teaching Mode"
			)
		else
			ControlOptions=( \
				"QUIT Leaving Console Bearer Token Active"
				"Modify Global Search Filter"
				"Change Networks"
				"Organization Search"
				"Network Search"
				"Toggle Fancy Printing"
				"Toggle Debug Messaging"
				"Toggle Teaching Mode"
			)
		fi

		# Loop until done.
		while true; do
			AttentionMessage "GREENINFO" "\"${MyName[0]}\" - Control Options."
			! GetSelection "What do you want to do?" "${ControlOptions[*]}" \
				&& break
			case ${UserResponse} in
				"QUIT Leaving Console Bearer Token Active")
					AttentionMessage "REDINFO" "This option allows you to quit the program without destroying the Console Bearer Token."
					GetYorN "Are you sure?" "No" \
						&& GoToExit "8"
				;;
				"Modify Global Search Filter")
					if GetFilterString; then
						AttentionMessage "GREENINFO" "Global Search Filter was updated to \"${PrimaryFilterString}\"."
					else
						AttentionMessage "GREENINFO" "Global Search Filter remains \"${PrimaryFilterString:-UNSET}\"."
					fi
					sleep 2
				;;
				"Change Networks")
					if SelectNetwork; then
						AttentionMessage "GREENINFO" "Network was updated to \"${Target_NETWORK[1]}\"."
					else
						AttentionMessage "GREENINFO" "Network remains \"${Target_NETWORK[1]:-UNSET}\"."
					fi
					sleep 2
				;;
				"Organization Search")
					RunMacro "ORGANIZATIONSEARCH"
					GetYorN "SPECIAL-PAUSE"
				;;
				"Network Search")
					[[ -z ${Target_NETWORK[1]} ]] \
						&& SelectNetwork
					RunMacro "NETWORKSEARCH"
					GetYorN "SPECIAL-PAUSE"
				;;
				"Toggle Fancy Printing")
					AttentionMessage "GREENINFO" "Fancy Printing makes the CLI appear like a 90s era computer."
					AttentionMessage "GREENINFO" "Limit fancy printing is currently set to \"$(SetLimitFancy "GETSTATE" && echo "TRUE" || echo "FALSE")\"."
					GetYorN "Toggle the state?" "Yes" \
						&& SetLimitFancy "TOGGLE" \
						&& AttentionMessage "GREENINFO" "Limit fancy printing state was toggled." \
						|| AttentionMessage "GREENINFO" "No changes were made."
					sleep 2
				;;
				"Toggle Debug Messaging")
					AttentionMessage "GREENINFO" "Debug Messaging will help you ascertain API interaction errors by showing return headers."
					AttentionMessage "GREENINFO" "Debug Messaging is currently set to \"${DebugInfo}\"."
					if GetYorN "Toggle the Messaging?" "Yes"; then
						if [[ ${DebugInfo} == "TRUE" ]]; then
							DebugInfo="FALSE"
							AttentionMessage "GREENINFO" "Debug Messaging was disabled."
						elif [[ ${DebugInfo} == "FALSE" ]]; then
							DebugInfo="TRUE"
							AttentionMessage "GREENINFO" "Debug Messaging was enabled."
						fi
					else
						AttentionMessage "GREENINFO" "Debug Messaging was not changed."
					fi
					sleep 2
				;;
				"Toggle Teaching Mode")
					AttentionMessage "GREENINFO" "Teaching Mode shows you how to call the NetFoundry API for a given interaction."
					AttentionMessage "GREENINFO" "Teaching Mode is currently set to \"${TeachMode}\"."
					if GetYorN "Toggle the Mode?" "Yes"; then
						if [[ ${TeachMode} == "TRUE" ]]; then
							TeachMode="FALSE"
							AttentionMessage "GREENINFO" "Teaching Mode was disabled."
						elif [[ ${TeachMode} == "FALSE" ]]; then
							TeachMode="TRUE"
							AttentionMessage "GREENINFO" "Teaching Mode was enabled."
						fi
					else
						AttentionMessage "GREENINFO" "Teaching Mode was not changed."
					fi
					sleep 2
				;;
			esac
			ClearLines "ALL"
		done

		AttentionMessage "GREENINFO" "Now returning to normal operation."
		sleep 2
		tput rmcup # Return screen contents.
		trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.
		InputProcessing="FALSE" # Enable input function to manipulate again.
		return 0

	elif [[ "${1}" -eq 4 ]]; then

		reset
		FancyPrint "PLAINLOGO"
		[[ -n "${2}" ]] \
			&& AttentionMessage "ERROR" "${2}"
		DestroyBearerToken \
			|| AttentionMessage "ERROR" "Your Console Bearer Token could not be destroyed."
		AttentionMessage "GENERALINFO" "REMINDER, never leave your credentials saved on the device or held in buffer in an open window."
		AttentionMessage "GREENINFO" "Exiting. [RunTime=$((SECONDS/60))m $((SECONDS%60))s]"
		TrackLastTouch "DIE"
		stty sane 2>/dev/null
		[[ -n "${2}" ]] \
			&& exit "${1}" \
			|| exit 0

	elif [[ "${1}" -eq 5 ]]; then

		DestroyBearerToken \
			|| AttentionMessage "ERROR" "Your Console Bearer Token could not be destroyed."
		TrackLastTouch "DIE"
		stty sane 2>/dev/null
		exit 0

	elif [[ "${1}" -eq 7 ]]; then

		FancyPrint "PLAINLOGO"
		[[ -n "${2}" ]] \
			&& AttentionMessage "ERROR" "${2}"
		DestroyBearerToken \
			|| AttentionMessage "ERROR" "Your Console Bearer Token could not be destroyed."
		AttentionMessage "GENERALINFO" "REMINDER, never leave your credentials saved on the device or held in buffer in an open window."
		AttentionMessage "GREENINFO" "Exiting. [RunTime=$((SECONDS/60))m $((SECONDS%60))s]"
		TrackLastTouch "DIE"
		stty sane 2>/dev/null
		[[ -n "${2}" ]] \
			&& exit "${1}" \
			|| exit 0

	elif [[ "${1}" -eq 8 ]]; then

		FancyPrint "PLAINLOGO"
		AttentionMessage "REDINFO" "Please be aware that your Console Bearer Token persists as shown below."
		echo "${NFN_BEARER[0]:-UNSET}"
		AttentionMessage "GENERALINFO" "REMINDER, never leave your credentials saved on the device or held in buffer in an open window."
		AttentionMessage "GREENINFO" "Exiting. [RunTime=$((SECONDS/60))m $((SECONDS%60))s]"
		TrackLastTouch "DIE"
		stty sane 2>/dev/null
		exit 0

	else

		reset
		FancyPrint "EXITLOGO"
		[[ -n "${2}" ]] \
			&& AttentionMessage "ERROR" "${2}"
		DestroyBearerToken \
			|| AttentionMessage "ERROR" "Your Console Bearer Token could not be destroyed."
		AttentionMessage "GENERALINFO" "REMINDER, never leave your credentials saved on the device or held in buffer in an open window."
		AttentionMessage "GREENINFO" "Exiting. [RunTime=$((SECONDS/60))m $((SECONDS%60))s]"
		TrackLastTouch "DIE"
		stty sane 2>/dev/null
		exit "${1:-0}"

	fi
}

#################################################################################
# Screen manipulation to clear lines of text.
function ClearLines() {
	function GetLines() {
		local CurPos
		IFS='[;' read -p $'\e[6n' -d R -a CurPos -rs ${CurPos[*]}
		echo "${CurPos[1]}"
	}

	# 1/[NUMBEROFLINES|ALL]
	local i
	local ClearLines="${1}"
	local NumberRE='^[0-9]+$'

	if [[ ${ClearLines} == "ALL" ]] && [[ ${LimitFancy} == "TRUE" ]]; then

			tput clear

	elif [[ ${ClearLines} == "ALL" ]] && [[ ${LimitFancy} == "FALSE" ]]; then

		ClearLines=$(GetLines)
		tput el1 # Delete to the beginning of the current line.
		# For each line going up to clear, do this.
		for ((i=1;i<=ClearLines;i++)); do
			tput cuu1 # Go up one line.
			tput el # Delete the contents of this line.
			sleep 0.01 # Wait.
		done

	elif [[ ${ClearLines} == "ALL" ]]; then

		# Use the builtin.
		clear

	elif [[ ${TeachMode} == "FALSE" ]] && [[ ${ClearLines} =~ ${NumberRE} ]]; then

		# For each line going up to clear, do this.
		for ((i=1;i<=ClearLines;i++)); do
			tput cuu1 # Go up one line.
			tput el # Delete the contents of this line.
		done

	else

		# Cannot do this, so just echo.
		echo

	fi

}

#################################################################################
# Last touch to keep track of idle time.
function TrackLastTouch() {
	# 1/TOSTATE
	local LastTouchSECONDS="0"
	local ToState="${1:-UPDATE}"

	if [[ ${ToState} == "UPDATE" ]]; then

		echo "${SECONDS}" >${TmpDir}/FIFO-${ParentPID:-ORPHAN}.pipe

	elif [[ ${ToState} == "DIE" ]]; then

		echo "-${MaxIdle}" >${TmpDir}/FIFO-${ParentPID:-ORPHAN}.pipe

	elif [[ ${ToState} == "INITIATE" ]]; then

		# This function is pushed to the background and executes on a cadence.
		{
			# Until the trigger to end appears, read from the FIFO pipe and set the local variable.
			while true; do
				sleep 5
				read -t 1 <>${TmpDir}/FIFO-${ParentPID:-ORPHAN}.pipe LastTouchSECONDS 2>/dev/null \
					|| AttentionMessage "CRITICAL" "Could not ascertain \"LastTouchSECONDS\" from \"${TmpDir}/FIFO-${ParentPID:-ORPHAN}.pipe\"."
				if [[ $((MaxIdle-(SECONDS-LastTouchSECONDS))) -le 0 ]]; then
					# Tell the parent to shutdown and break out of the local loop which will shutdown this thread too.
					kill -USR1 ${ParentPID} &>/dev/null
					rm -f ${TmpDir}/FIFO-${ParentPID:-ORPHAN}.pipe
					break
				elif [[ $((MaxIdle-(SECONDS-LastTouchSECONDS))) -le 60 ]] && [[ $((MaxIdle-(SECONDS-LastTouchSECONDS))) -gt 0 ]]; then
					tput sc
					tput cup 0 $(($(tput cols)-28))
					printf "\e[${Invert};${FRed};${BBlack}m%-21s %3s\e[1;${Normal}m" "IDLE TIMEOUT WARNING:" "$((MaxIdle-(SECONDS-LastTouchSECONDS)))s"
					tput rc
					sleep 1
				fi
			done
		}

	fi
}

#################################################################################
# Set the printing/output as required for the env.
function SetLimitFancy() {
	# 1/FANCYSETTING
	if [[ ${1} == "GETSTATE" ]]; then

		if [[ ${LimitFancy} == "FALSE" ]]; then
			return 0
		elif [[ ${LimitFancy} == "TRUE" ]]; then
			return 1
		fi

	elif [[ ${1} == "FALSE" ]]; then

		# A specific OS check.
		CheckObject "ENV-v" "Microsoft" "NOPRINT" \
			&& SetLimitFancy "WSL" \
			&& return 0

		IconStash=( 'ℹ' 'ℹ' '✓' '!' '?' '+' 'X' 'Δ ⦵' 'Δ ⧗' 'Δ ➤' 'Δ ☉' 'Δ ⚑' '⬆⬇' '⬤' '⬆' '⬇' )
		LimitFancy="FALSE"

	elif [[ ${1} == "TRUE" ]]; then

		# A specific OS check.
		CheckObject "ENV-v" "Microsoft" "NOPRINT" \
			&& SetLimitFancy "WSL" \
			&& return 0

		IconStash=( 'ℹ' 'ℹ' '✓' '!' '?' '+' 'X' 'Δ ⦵' 'Δ ⧗' 'Δ ➤' 'Δ ☉' 'Δ ⚑' '⬆⬇' '⬤' '⬆' '⬇' )
		LimitFancy="TRUE"

	elif [[ ${1} == "WSL" ]]; then

		IconStash=( 'i' 'i' '+' '!' '?' '+' 'X' 'Δ +' 'Δ +' 'Δ +' 'Δ +' 'Δ ^' '+-' '*' '+' '-' )
		LimitFancy="TRUE"

	elif [[ ${1} == "TOGGLE" ]]; then

		[[ ${LimitFancy} == "TRUE" ]] \
			&& SetLimitFancy "FALSE" \
			|| SetLimitFancy "TRUE"

	fi
}

#################################################################################
# Return the byte length of a string.
function StrU8DiffLen() {
	# 1/INPUTSTRING
	local bytlen oLang=$LANG oLcAll=$LC_ALL
	LANG=C LC_ALL=C
	bytlen=${#1}
	LANG=$oLang LC_ALL=$oLcAll
	return $(( bytlen - ${#1} ))
}

#################################################################################
# Get the attention of the user with a colored message.
function AttentionMessage() {
	# 1/InputHead=TEXT
	# Gather details.
	local InputHead[0]="${1}"
	local CommentText="${2}"
	local OutputColor SubCommentText SpecialSyntaxAdder

	# Update the idle tracker.
	[[ ${InputHead[0]} != "TIMEWARNING" ]] \
		&& TrackLastTouch "UPDATE"

	case ${InputHead[0]} in
		# Something of interest.
		"GENERALINFO"|"GREENINFO")
			# If in QUIET mode, just return.
			[[ ${InputHead:-ERROR} == "GENERALINFO" ]] && [[ ${QuietPrint:-FALSE} == "TRUE" ]] \
				&& return
			InputHead[1]="${IconStash[0]}"
			InputHead[0]="INFO"
			OutputColor="${Invert};${FLiteGreen};${BBlack}"
		;;
		# Something of interest.
		"YELLOWINFO")
			InputHead[1]="${IconStash[1]}"
			InputHead[0]="INFO"
			OutputColor="${Invert};${FLiteYellow};${BBlack}"
		;;
		# Something of interest.
		"REDINFO")
			InputHead[1]="${IconStash[1]}"
			InputHead[0]="INFO"
			OutputColor="${Invert};${FLiteRed};${BBlack}"
		;;
		# A validation occurred.
		"VALIDATED")
			InputHead[1]="${IconStash[2]}"
			OutputColor="${Invert};${FLiteGreen};${BBlack}"
		;;
		# Something to review, but not an error.
		"WARNING"|"TIMEWARNING")
			InputHead[1]="${IconStash[3]}"
			InputHead[0]="WARNING"
			OutputColor="${Invert};${FLiteYellow};${BBlack}"
		;;
		# Something to review, but not an error.
		"SELECTION"|"YES OR NO"|"RESPONSE")
			InputHead[1]="${IconStash[4]}"
			OutputColor="${Invert};${FLiteBlue};${BBlack}"
		;;
		# TeachMode flag.
		"TEACHMODE")
			[[ ${TeachMode:-FALSE} == "FALSE" ]] \
				&& return 0
			InputHead[1]="${IconStash[5]}"
			OutputColor="${Invert};${FLiteMagenta};${BBlack}"
		;;
		# Debug flag.
		"DEBUG")
			[[ ${DebugInfo:-FALSE} == "FALSE" ]] \
				&& return 0
			InputHead[1]="${IconStash[5]}"
			OutputColor="${Invert};${FLiteMagenta};${BBlack}"
		;;
		# You screwed up turkey.
		"ERROR"|"CRITICAL"|*)
			InputHead[1]="${IconStash[6]}"
			InputHead[0]="ERROR"
			OutputColor="${Invert};${FRed};${BBlack}"
		;;
	esac

	# The remainder of the pass-in is sub-comment.
	shift 2
	SubCommentText="$*"

	StrU8DiffLen "${InputHead[1]}"
	SpecialSyntaxAdder="$?"

	# This output mode means that the text was repeated. Do not apply decoration if so.
	if [[ "${CommentText}" == "${LastText}" ]]; then
		printf "\e[${OutputColor}m| %-$((1+SpecialSyntaxAdder))b %-10s |\e[1;${Normal}m " "${InputHead[1]}" "${InputHead[0]}"
		FancyPrint "${CommentText}" "0" "0"
	# This output mode means that output should abide by original intent to apply decoration.
	else
		printf "\e[${OutputColor}m| %-$((1+SpecialSyntaxAdder))b %-10s |\e[1;${Normal}m " "${InputHead[1]}" "${InputHead[0]}"
		FancyPrint "${CommentText}" "5" "1"
	fi

	# Print sub-comments plainly if they exist.
	[[ ${SubCommentText} ]] \
		&& echo "${SubCommentText}"

	# Save for review.
	LastText="${CommentText}"
}

#################################################################################
# Output helper for printing.
function PrintHelper() {
	function ColorConvert() {
		# 1/PRECONVERTED
		local PreConverted="${1}"
		shopt -s extglob # For pattern matching inside this sub-shell.
		case "${PreConverted}" in
			"NORMAL"|"000")
				echo "${Normal}"
			;;
			"100")
				echo "PUSH${FLiteYellow}"
			;;
			"OFFLINE"|"200")
				echo "PUSH${FRed}"
			;;
			"ONLINE"|"300")
				echo "PUSH${FGreen}"
			;;
			"ERR")
				echo "PUSH${Bold};${FRed}"
			;;
			"PROVISIONING"|"NRG"|"UNREGISTERED")
				echo "PUSH${FDarkGray}"
			;;
			"STATUS")
				echo "PUSH${FLiteGray}"
			;;
			"UNKNOWN"|"ERROR"|"ALERT")
				echo "${Invert};${FRed};${BBlack}"
			;;
			"INFO")
				echo "${Invert};${FGreen};${BBlack}"
			;;
			"WARNING")
				echo "${Invert};${FYellow};${BBlack}"
			;;
			"BEGIN")
				echo "${Invert};${FDarkGray};${BBlack}"
			;;
			(*[a-Z]*)
				echo "${Invert};${FMagenta};${BBlack}" # Bad scenario or code.
			;;
			*)
				echo "${PreConverted}" # Any other number.
			;;
		esac
	}

	######################################################
	# Notes on printing.
	# All printing is width 139 (+1 for newline) spaces.
	# Padding of 2 spaces are at each end of non-lines.
	# A total of 135 spaces are free for printing.
	# Each line consists of the following:
	#  BOXTOPIC = Line Counter. (7) (NoColor)
	# [SPACE] (1)
	#  BOXSUBTOPIC = Variable Name. (26) (Color)
	# [SPACE] (1)
	#   BOXTOPIC/BOXSUBTOPIC may merge together.
	#  BOXDETAIL = Variable Desc. (63) (PUSHColor)
	#  BOXTRAIL = Extra Desc. (36) (Dimmed)
	#   BOXDETAIL/BOXTRAIL may merge together.
	######################################################

	# 1/TYPE 2/BOXTOPIC 3/BOXSUBTOPIC[COLOR:::TEXT] 4/BOXDETAIL[DETAIL[=>TRAIL]]
	local i BoxTopic BoxSubTopic BoxSubTopicColor BoxDetail BoxDetailColor BoxTrail
	local PrintSyntax SpecialSyntaxAdder
	local PrintType="${1}"
	local IFS=$' \t\n'
	local PadBlankField="                              " # 30 blanks for padding purposes.
	#local PadDotField=".............................." # 30 dots for padding purposes.
	#local PadDashField="------------------------------" # 30 dashes for padding purposes.


	# The BoxTopic.
	BoxTopic="${2:0:7}" # TEXT (only first 7 characters)

	# BoxTopic MERGE flag will merge the BoxTopic and BoxSubTopic fields into BoxTopic.
	if [[ ${BoxTopic} == "MERGE" ]]; then

		BoxTopic="${3#*:::}" # COLOR:::[TEXT]
		BoxTopicColor="$(ColorConvert ${3%:::*})" # [COLOR]:::TEXT
		BoxTopic="${BoxTopic:0:34}" # TEXT (only 34 characters, 7+26+1)
		BoxSubTopic=""
		StrU8DiffLen "${BoxTopic}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="\e[${BoxTopicColor}m%-$((34+SpecialSyntaxAdder))s\e[${Normal}m%0s" # 34=34 Spaces Used.

	else

		BoxSubTopic="${3#*:::}" # COLOR:::[TEXT]
		BoxSubTopicColor="$(ColorConvert ${3%:::*})" # [COLOR]:::TEXT
		# Push the color code from BoxSubTopic to BoxDetail in this special case.
		[[ ${BoxSubTopicColor} =~ "PUSH" ]] \
			&& BoxDetailColor="${BoxSubTopicColor/PUSH/}" \
			&& BoxSubTopicColor="${Normal}" \
			|| BoxDetailColor="${Normal}"
		BoxSubTopic="${BoxSubTopic:0:26}" # TEXT (only 26 characters)
		# Pad with blanks when BoxSubTopic is zero characters, or middle align if non-zero.
		[[ ${#BoxSubTopic} -eq 0 ]] \
			&& BoxSubTopic="${PadBlankField:0:26}" \
			|| BoxSubTopic="${BoxSubTopic}${PadBlankField:0:$((26-((26+${#BoxSubTopic})/2)))}"
		StrU8DiffLen "${BoxTopic}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="%-$((7+SpecialSyntaxAdder))s"
		StrU8DiffLen "${BoxSubTopic}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="${PrintSyntax} \e[${BoxSubTopicColor}m%$((26+SpecialSyntaxAdder))s\e[${Normal}m" # 7+1Pad+26=34 Spaces Used.

	fi

	# There are (4Pad+34=36-139) 101 spaces free at this point.

	# Analyze the BoxDetail and BoxTrail.
	BoxDetail="${4%=>*}" # [TEXT]=>TEXT
	BoxTrail="${4#*=>}" # TEXT=>[TEXT]
	[[ "${BoxDetail}" == "${BoxTrail}" ]] \
		&& unset BoxTrail

	# BOXHEADLINEB and BOXITEMB are unique cases with multiple special characters in the BoxDetail variable, as well as no BoxTrail.
	if [[ ${PrintType} == "BOXHEADLINEB" ]] || [[ ${PrintType} == "BOXITEMB" ]]; then

		IFS=',' read -ra BoxDetail <<< "${BoxDetail}" # BoxDetail is a comma delimited array.
		# If the variable Items in BoxDetail are uneven, padding using MOD will be applied. (101-1Pad) 100 MOD Items = Leftover Spaces.
		PrintSyntax="${PrintSyntax} ${PadBlankField:0:$((100%(${#BoxDetail[*]})+1))}" # EX: 1Pad + (100%6=4) Left Pad Spaces, 95 Spaces for Items

		for ((i=0;i<${#BoxDetail[*]};i++)); do
			BoxDetailColor="$(ColorConvert ${BoxDetail[${i}]%:::*})" # [COLOR]:::TEXT
			BoxDetail[${i}]="${BoxDetail[${i}]#*:::}" # COLOR:::[TEXT]
			# 1 Pad between Items Only. EX: 6 Items have 5x1 Pads [I]P[I]P[I]P[I]P[I]P[I] = 95 Spaces - 5Pads = 90 Spaces / 6 = 15 per Item
			BoxDetail[${i}]="${BoxDetail[${i}]:0:$((((100-(100%(${#BoxDetail[*]}-1)))-(${#BoxDetail[*]})-1)/${#BoxDetail[*]}))}" # TEXT (AVAILABLE-(Items-1))/Items
			StrU8DiffLen "${BoxDetail[${i}]}"
			SpecialSyntaxAdder="$?"
			PrintSyntax="${PrintSyntax}\e[${BoxDetailColor}m%$(((((100-(100%(${#BoxDetail[*]}-1)))-(${#BoxDetail[*]}-1))/${#BoxDetail[*]})+SpecialSyntaxAdder))s\e[${Normal}m"
			[[ ${i} -lt $((${#BoxDetail[*]}-1)) ]] \
				&& PrintSyntax="${PrintSyntax} " # Add the 1Pad on the inner Items.
		done

	# If BoxTrail is empty or if the delimiter (=>) was not present and caused BoxDetail and BoxTrail to be mirrored, then only BoxDetail exists.
	elif [[ ${BoxTrail:-UNSET} == "UNSET" ]]; then

		# There are a total of 100 Spaces available.
		BoxDetail=( "${BoxDetail:0:100}" ) # TEXT (only the first 100 characters)
		StrU8DiffLen "${BoxDetail[0]}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="${PrintSyntax} \e[${BoxDetailColor}m%-$((100+SpecialSyntaxAdder))s\e[${Normal}m"
		BoxTrail="" # Ensure BoxTrail is empty.
		PrintSyntax="${PrintSyntax}%0s" # Ensure PrintSyntax[4] will not print.

	# If BoxTrail is not empty, then BoxDetail and BoxTrail must share space.
	else

		# There is a total of (100-1) 99 Spaces available.
		BoxDetail=( "${BoxDetail:0:63}" ) # TEXT (only the first 63 characters)
		StrU8DiffLen "${BoxDetail[0]}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="${PrintSyntax} \e[${BoxDetailColor}m%-$((63+SpecialSyntaxAdder))s\e[${Normal}m"
		# There is a total of 36 Spaces available.
		BoxTrail="${BoxTrail:0:36}" # TEXT (only the first 36 characters)
		StrU8DiffLen "${BoxTrail}"
		SpecialSyntaxAdder="$?"
		PrintSyntax="${PrintSyntax} \e[${Dimmed}m%$((36+SpecialSyntaxAdder))s\e[${Normal}m"

	fi

	# All lines are 139 characters in length with 1 character dedicated to newline (\n).
	case "${PrintType}" in

		"BOXHEADLINEA")
			printf "  ${PrintSyntax}  \n" "${BoxTopic}" "${BoxSubTopic}" "${BoxDetail[*]}" "${BoxTrail}"
			printf "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
		;;

		"BOXHEADLINEB")
			printf "  ${PrintSyntax}  \n" "${BoxTopic}" "${BoxSubTopic}" "${BoxDetail[@]}"
			printf "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
		;;

		"BOXITEMA")
			printf "┃ ${PrintSyntax} ┃\n" "${BoxTopic}" "${BoxSubTopic}" "${BoxDetail[*]}" "${BoxTrail}"
		;;

		"BOXITEMB")
			printf "┃ ${PrintSyntax} ┃\n" "${BoxTopic}" "${BoxSubTopic}" "${BoxDetail[@]}"
		;;

		"BOXITEMASUB")
			printf " ┃${PrintSyntax}┃ \n" "${BoxTopic}" "${BoxSubTopic}" "${BoxDetail[*]}" "${BoxTrail}"
		;;

		"BOXITEMASUBLINEA")
			printf "┗┓\e[${Dimmed}m━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━\e[${Normal}m┏┛\n"
		;;

		"BOXITEMASUBLINEB")
			printf "┏┛\e[${Dimmed}m━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━\e[${Normal}m┗┓\n"
		;;

		"BOXITEMASUBLINEC")
			printf "┣ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ━ ┫\n"
		;;

		"BOXMIDLINEA")
			printf "┏┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻┓\n"
		;;

		"BOXMIDLINEB")
			printf "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\n"
		;;

		"BOXFOOTLINEA")
			printf "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
		;;

		"BOXFOOTLINEB")
			printf " ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
		;;

	esac
}

#################################################################################
# Check variable objects for validity.
function CheckObject() {

 function GoToPrint() {
	AttentionMessage "ERROR" "Could not find TYPE:\"${MyInputType:-ERROR}\" NAME:\"${MyInputName:-ERROR}\"."
	AttentionMessage "REDINFO" "Try auto-installing packages with command line option \"-X\"."
	sleep 3
 }

	# 1/INPUTTYPE [PROG/FILE/ENV/VARI] 2/INPUTNAME [TEXT/VARIABLE/COMMAND] 3/CONTEXT
	local MyInputType="${1}"
	local MyInputName="${2}"
	local MyInputHandle="${3:-PRINT}"
	local MyEnv

	# Must have all three inputs to continue.
	if [[ -n ${MyInputType} ]] && [[ -n ${MyInputName} ]]; then

		# A program.
		if [[ ${MyInputType} == "PROG" ]]; then

			# The program should be path executable.
			if which "${MyInputName}" &>/dev/null; then
				return 0
			else
				[[ ${MyInputHandle} == "PRINT" ]] \
					&& GoToPrint
				return 1
			fi

		# A file.
		elif [[ ${MyInputType} == "FILE" ]]; then

			# The file should be in the relative directory.
			if find "${MyInputName}" &>/dev/null; then
				return 0
			else
				[[ ${MyInputHandle} == "PRINT" ]] \
					&& GoToPrint
				return 1
			fi

		# A user.
		elif [[ ${MyInputType} == "USER" ]]; then

			# Screen columns.
			if [[ $(whoami) != "${MyInputName}" ]]; then
				return 0
			else
				return 1
			fi

		# An environment.
		elif [[ ${MyInputType} =~ "ENV" ]]; then

			# Unspecified option defaults to "a" / ALL uname variables.
			[[ ${MyInputType} == "ENV" ]] \
				&& MyInputType="ENV-a"

			# Uname output.
			MyEnv=$(uname ${MyInputType##*ENV} 2>/dev/null)
			if [[ "${MyEnv:-NONE}" =~ ${MyInputName} ]]; then
				return 0
			else
				[[ ${MyInputHandle} == "PRINT" ]] \
					&& GoToPrint
				return 1
			fi

		# A screen width.
		elif [[ ${MyInputType} =~ "SCWD" ]]; then

			# Screen columns.
			if [[ ${MyInputName:-0} -lt 0 ]]; then
				return 0
			else
				return 1
			fi

		# Unknown or no type specified.
		else

			AttentionMessage "CRITICAL" "Code error while analyzing \"${MyInputType:-ERROR}\" \"${MyInputName:-ERROR}\". Unknown option \"${MyInputType:-ERROR}\"), please report."
			return 1

		fi

	else

		AttentionMessage "CRITICAL" "Code error while analyzing \"${MyInputType:-ERROR}\" \"${MyInputName:-ERROR}\". Missing options from pass-in, please report."
		return 1

	fi
}

#################################################################################
# Print fancy lines of text.
function FancyPrint() {
	# Print like someone is typing.
	function TypeIt() {
		# 1/TEXTLINE 2/SPEEDFACTOR 3/COLORSELECT
		local i
		for ((i=0;i<${#1};i++)); do
			[[ ${2} -ne 0 ]] \
				&& sleep 0.00"${2}"
			[[ ${3:-NONE} != "NONE" ]] \
				&& printf "\e[1;${3}m%s\e[${Normal}m" "${1:${i}:1}" \
				|| echo -en "${1:${i}:1}"
		done && echo
	}

	# Truffle shuffle.
	function ShuffleLogoArray {
		local i ThisTemp ThisArraySize ThisArrayMax ThisRand
		ThisArraySize=${#ThisLogoA[*]}
		ThisArrayMax=$((32768/ThisArraySize*ThisArraySize))
		for ((i=ThisArraySize-1;i>0;i--)); do
			while (((ThisRand=RANDOM)>=ThisArrayMax)); do :; done
			ThisRand="$((ThisRand%(i+1)))"
			ThisTemp="${ThisLogoA[${i}]}"
			ThisLogoA[${i}]="${ThisLogoA[${ThisRand}]}"
			ThisLogoA[${ThisRand}]="${ThisTemp}"
		done
	}

	# 1/[TEXTLINE|LOGO] 2/SPEEDFACTOR 3/COLORSELECT
	local i ThisLogoA ThisLogoB ThisLineText="${1:-NO TEXT INPUT}" ThisSpeedFactor="${2:-0}" ThisColor="${3:-0}"

	# Default action is to print the logo.
	if [[ ${ThisLineText} =~ "LOGO" ]]; then

		[[ ${QuietPrint:-FALSE} == "TRUE" ]] \
			&& return # Nothing to do.

		ThisLogoA[0]='0:::                                                                                                                 '
		ThisLogoA[1]='1::: ███    ██ ███████ ████████ ███████  ██████  ██    ██ ███    ██ ██████  ██████  ██    ██      █████  ██████  ██  '
		ThisLogoA[2]='2::: ████   ██ ██         ██    ██      ██    ██ ██    ██ ████   ██ ██   ██ ██   ██  ██  ██      ██   ██ ██   ██ ██  '
		ThisLogoA[3]='3::: ██ ██  ██ █████      ██    █████   ██    ██ ██    ██ ██ ██  ██ ██   ██ ██████    ████       ███████ ██████  ██  '
		ThisLogoA[4]='4::: ██  ██ ██ ██         ██    ██      ██    ██ ██    ██ ██  ██ ██ ██   ██ ██   ██    ██        ██   ██ ██      ██  '
		ThisLogoA[5]='5::: ██   ████ ███████    ██    ██       ██████   ██████  ██   ████ ██████  ██   ██    ██        ██   ██ ██      ██  '
		ThisLogoA[6]='6:::                                                                                                                 '
		ThisLogoA[7]='7:::                                                                                                                 '
		ThisLogoB[0]='0:::                                                                                                                 '
		ThisLogoB[1]='1::: ███╗   ██╗███████╗████████╗███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ ██████╗ ██╗   ██╗     █████╗ ██████╗ ██╗ '
		ThisLogoB[2]='2::: ████╗  ██║██╔════╝╚══██╔══╝██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔══██╗██╔══██╗██║ '
		ThisLogoB[3]='3::: ██╔██╗ ██║█████╗     ██║   █████╗  ██║   ██║██║   ██║██╔██╗ ██║██║  ██║██████╔╝ ╚████╔╝     ███████║██████╔╝██║ '
		ThisLogoB[4]='4::: ██║╚██╗██║██╔══╝     ██║   ██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══██╗  ╚██╔╝      ██╔══██║██╔═══╝ ██║ '
		ThisLogoB[5]='5::: ██║ ╚████║███████╗   ██║   ██║     ╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║       ██║  ██║██║     ██║ '
		ThisLogoB[6]='6::: ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚═╝     ╚═╝ '
		ThisLogoB[7]='7:::                                                                                                                 '

		# Only if the cursor manipulation program is available.
		if [[ ${ThisLineText} != "PLAINLOGO" ]] && [[ ${LimitFancy} == "FALSE" ]]; then

			# Where in the program is this occurring?
			if [[ ${ThisLineText} == "ENTERLOGO" ]] || [[ ${ThisLineText} == "EXITLOGO" ]]; then
				ClearLines "ALL"
				reset
			fi

			ShuffleLogoArray # Shuffle the logo array around.

			tput civis # Invisible cursor during draw.
			ThisColor="4$((RANDOM%6))" # One (random) color for the whole logo.
			for ((i=0;i<${#ThisLogoA[*]};i++)); do
				ThisLineText="${ThisLogoA[${i}]##*:::}"
				ThisLinePosition="${ThisLogoA[${i}]%%:::*}"
				ThisColumns="$(tput cols)"
				tput cup "${ThisLinePosition}" $(((ThisColumns/2)-(${#ThisLineText}/2)))
				printf '%s' "$(TypeIt "${ThisLineText}" "${ThisSpeedFactor}" "${ThisColor}")"
				sleep 0.15
			done && tput cup 0 0 # Move cursor to line 8 column 0.

			for ((i=0;i<${#ThisLogoB[*]};i++)); do
				ThisLineText="${ThisLogoB[${i}]##*:::}"
				ThisLinePosition="${ThisLogoB[${i}]%%:::*}"
				ThisColumns="$(tput cols)"
				tput cup "${ThisLinePosition}" $(((ThisColumns/2)-(${#ThisLineText}/2)))
				printf '%s' "$(TypeIt "${ThisLineText}" "${ThisSpeedFactor}" "${ThisColor}")"
				sleep 0.05
			done && tput cnorm # Cursor is visible after the draw.

		else

			for ((i=0;i<${#ThisLogoA[*]};i++)); do
				printf '%s\n' "$(TypeIt "${ThisLogoB[${i}]##*:::}" "${ThisSpeedFactor}" "${ThisColor}")"
			done

		fi
		printf '\n'

	# Otherwise, print the input line at the output speed factor and color.
	else

		[[ ${LimitFancy} == "FALSE" ]] \
			&& TypeIt "${ThisLineText}" "${ThisSpeedFactor}" "${ThisColor}" \
			|| printf "\e[1;${ThisColor}m%s\e[${Normal}m\n" "${ThisLineText}"

	fi
}

#######################################################################################
# Helper Functions - Qualifiers
#######################################################################################
#################################################################################
# Elicit a variable response from the user.
function GetResponse() {
	local InputQuestion="${1}" DefaultAnswer="${2}" ClearInput="ALL"
	local REPLY ClearInput
	unset REPLY UserResponse
	[[ ${InputProcessing} == "FALSE" ]] \
		&& stty sane 2>/dev/null

	# Update the idle tracker.
	TrackLastTouch "UPDATE"

	# A special mode clearing the screen of sensitive content if required.
	if [[ ${DefaultAnswer} =~ ^"CLEARINPUT:" ]] && [[ ${DefaultAnswer} =~ ^"CLEARINPUT:"[0-9]+$ ]]; then
		ClearInput="${DefaultAnswer/CLEARINPUT:/}"
		DefaultAnswer="NONE"
	fi

	# Do not allow blank or passed in NONE to be an answer.
	while true; do

		# A request for RESPONSE is a statement for an arbitrary answer.
		AttentionMessage "RESPONSE" "${InputQuestion} [BACK=BACK] [QUIT=QUIT]"

		# Get the answer.
		read -rp "[${CurrentPath:-\/}] Response? [DEFAULT=\"${DefaultAnswer}\"] > "
		if [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
			UserResponse="${DefaultAnswer}"
		elif [[ ${REPLY:-NONE} == "NONE" ]] && [[ ${DefaultAnswer:-NONE} == "NONE" ]]; then
			AttentionMessage "ERROR" "Invalid response \"${REPLY:-NO INPUT}\", try again."
			sleep 1
			ClearLines "3"
			continue
		elif [[ ${REPLY:-NONE} == "BACK" ]]; then
			return 1
		elif [[ ${REPLY:-NONE} == "QUIT" ]]; then
			GoToExit "0"
		else
			UserResponse="${REPLY}"
		fi

		if [[ ${ClearInput} == "ALL" ]]; then
			ClearLines "ALL"
		elif [[ ${ClearInput} -eq 0 ]]; then
			:
		else
			ClearLines "${ClearInput}"
		fi

		[[ ${InputProcessing} == "FALSE" ]] \
			&& stty -echo -icanon time 0 min 0
		return 0

	done 2>&1
}

#################################################################################
# Elicit a YES or NO from the user.
function GetYorN() {
	local InputQuestion="${1}" DefaultAnswer="${2}" TimerVal="${3}"
	unset REPLY UserResponse
	[[ ${InputProcessing} == "FALSE" ]] \
		&& stty sane 2>/dev/null

	# Update the idle tracker.
	TrackLastTouch "UPDATE"

	# Loop until a decision is made.
	while true; do

		# Get the answer.
		if [[ ${TimerVal} ]]; then
			trap '' SIGINT SIGTERM # Ignore CTRL+C events.
			# A request for YES OR NO is a question only.
			AttentionMessage "YES OR NO" "${InputQuestion}"
			! read -rt "${TimerVal}" -p "[${CurrentPath:-\/}] Yes or No? [DEFAULT=\"${DefaultAnswer}\"] [TIMEOUT=${TimerVal[0]}s] > " \
				&& printf '%s\n' "[TIMED OUT, DEFAULT \"${DefaultAnswer}\" SELECTED]" \
				&& sleep 1
			ClearLines "2"
			trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.
		elif [[ ${InputQuestion} == "SPECIAL-PAUSE" ]]; then
			read -rp "Press ENTER to Continue > "
			unset REPLY
			[[ ${InputProcessing} == "FALSE" ]] \
				&& stty -echo -icanon time 0 min 0
			return 0
		else
			# A request for YES OR NO is a question only.
			AttentionMessage "YES OR NO" "${InputQuestion}"
			read -rp "[${CurrentPath:-\/}] Yes or No? [DEFAULT=\"${DefaultAnswer}\"] > "
		fi

		# If there was no reply, take the default.
		[[ ${REPLY:-NONE} == "NONE" ]] \
			&& REPLY="${DefaultAnswer}"

		# Find out which reply was given.
		case ${REPLY} in
			Y|YE|YES|YEs|Yes|yes|ye|y)
				unset REPLY
				[[ ${InputProcessing} == "FALSE" ]] \
					&& stty -echo -icanon time 0 min 0
				return 0
			;;
			N|NO|No|no|n)
				unset REPLY
				[[ ${InputProcessing} == "FALSE" ]] \
					&& stty -echo -icanon time 0 min 0
				return 1
			;;
			QUIT)
				GoToExit "0"
			;;
			*)
				AttentionMessage "ERROR" "Invalid response \"${REPLY:-NO INPUT}\", try again."
				unset REPLY
				sleep 1
				ClearLines "1"
				continue
			;;
		esac

	done 2>&1
}

#################################################################################
# Elicit a selection response from the user.
function GetSelection() {
	local i REPLY SelectionList SelectionItem TMP_DefaultAnswer COLUMNS
	local InputQuestion InputAllowed InputAllowed DefaultAnswer MaxLength
	InputQuestion="${1}"
	InputAllowed=( "BACK" "QUIT" ${2} )
	DefaultAnswer="${3}"
	MaxLength="0"
	unset SELECTION UserResponse PS3
	set -o posix
	[[ ${InputProcessing} == "FALSE" ]] \
		&& stty sane 2>/dev/null

	# Update the idle tracker.
	TrackLastTouch "UPDATE"

	# Prompt text.
	PS3="[${CurrentPath:-\/}] #? > "

	# Make the selections easy to read if they have the => delimiter.
	for ((i=0;i<${#InputAllowed[*]};i++)); do
		SelectionItem=( ${InputAllowed[${i}]/=>/${NewLine}=>} )
		if [[ ${#SelectionItem[0]} -gt 65 ]]; then
			MaxLength="65"
		elif [[ ${#SelectionItem[0]} -gt ${MaxLength} ]]; then
			MaxLength="${#SelectionItem[0]}"
		fi
	done

	# Build the list in a readable format.
	for ((i=0;i<${#InputAllowed[*]};i++)); do
		SelectionItem=( ${InputAllowed[${i}]/=>/${NewLine}=>} )
		SelectionList[${i}]="$(printf "%-${MaxLength}s %-s\n" "${SelectionItem[0]}" "${SelectionItem[1]}")"
	done

	# Loop until a decision is made.
	while true; do

		# If there is a default, a prompt will appear to accept it or move to the selection.
		if [[ ${DefaultAnswer:-NONE} != "NONE" ]]; then
			# This is a statement for a request of a selection.
			AttentionMessage "SELECTION" "${InputQuestion}"
			TMP_DefaultAnswer=${DefaultAnswer}
			GetYorN "Keep selection of \"${DefaultAnswer}\"?" "Yes" \
				&& UserResponse=${TMP_DefaultAnswer} \
				&& break
		fi

		# Otherwise, get the selection.
		AttentionMessage "SELECTION" "${InputQuestion}"
		COLUMNS="1" # Force select statement into a single column.
		select SELECTION in ${SelectionList[*]}; do

			if { [[ "${REPLY}" == "QUIT" ]] || [[ "${REPLY}" == "BACK" ]]; } || { [[ 1 -le "${REPLY}" ]] && [[ "${REPLY}" -le ${#SelectionList[*]} ]]; }; then

				case ${REPLY} in

					1|"BACK")
						ClearLines "ALL"
						set +o posix
						[[ ${InputProcessing} == "FALSE" ]] \
							&& stty -echo -icanon time 0 min 0
						return 1
					;;

					2|"QUIT")
						set +o posix
						GoToExit "0"
					;;

					*)
						UserResponse="${InputAllowed[$((REPLY-1))]}"
						ClearLines "ALL"
						set +o posix
						[[ ${InputProcessing} == "FALSE" ]] \
							&& stty -echo -icanon time 0 min 0
						return 0
					;;

				esac

			else

				AttentionMessage "ERROR" "Invalid response \"${REPLY}/${SELECTION:-NO MATCH}\", try again."
				sleep 1

			fi

			AttentionMessage "SELECTION" "${InputQuestion}"

		done 2>&1

	done 2>&1
}

#################################################################################
# Elicit a name for an object from the user.
function GetObjectName() {
	# 1/TEXTNAME
	unset UserResponse
	ContextQuestion[1]="${1}"

	# If the last question asked is not the currently asked question, erase the default answer.
	[[ ${ContextQuestion[1]} != "${ContextQuestion[0]:-NONE}" ]] \
		&& unset GetObjectNameLast
	ContextQuestion[0]="${ContextQuestion[1]}"

	until [[ ${#UserResponse} -ge 5 ]] \
		&& [[ ${#UserResponse} -le 64 ]] \
		&& [[ ${UserResponse} =~ ^[[:alnum:]].*[[:alnum:]]$ ]]; do
		AttentionMessage "WARNING" "Ensure proper Console syntax with the following rules."
		AttentionMessage "GENERALINFO" "The name must be at least 5 characters long and can be up to 64 characters long."
		AttentionMessage "GENERALINFO" "It must begin with an alphanumeric character, and it must end with an alphanumeric."
		AttentionMessage "GENERALINFO" "The name may contain alphanumeric characters, \" \", \".\", or \"-\"."
		! GetResponse "Please provide a name ${ContextQuestion[0]}." "${GetObjectNameLast:-NONE}" \
			&& return 1
		UserResponse=${UserResponse//[\_\?\"\'\;\:\+\=\,\!\@\#\$\%\^\&\*\(\)\|\/\\\<\>\[\]\{\}]/-}
	done
	GetObjectNameLast="${UserResponse}"
	return 0
}

#######################################################################################
# MAIN Functions
#######################################################################################
#################################################################################
# Help the user with filter syntax.
function FilterHelp() {
	AttentionMessage "GENERALINFO" "Filter Function Help."
	FancyPrint "$(printf "%s\n" 'The filter function utilizes Linux program "grep" with option "-i" for case in-sensitivity and option "-E" for extended regular expressions.')" "1" "0"
	FancyPrint "$(printf "%s\n" 'Any REGEX pattern you can use in "grep" normally, you can use here against the object listing you have chosen.')" "1" "0"
	FancyPrint "$(printf "%s\n\n" 'The filter function only applies to the initial list of returned objects from the API and not the followed associations.')" "1" "0"

	FancyPrint "$(printf "%s\n" 'Regular Examples...')" "1" "1"
	FancyPrint "$(printf "%-30s %s\n" 'Singapore' 'Return objects that have "Singapore" contained within their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" 'Singapore.*DC.*Backup' 'Return objects that have "Singa[anychars]DC[anychars]Backup" contained within their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" 'Unit1.*5' 'Return objects that have "Unit1[anychars]5" contained within their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" 'Kapil|Dipesh|Unit.*Singapore' 'Return objects that have either "Kapil" or "Dipesh" or "Unit[anychars]Singapore" contained within their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n\n" '*:::Kapil Singapore=>*' 'Return EXACTLY the object that has "Kapil Singapore" as their name.')" "0" "0"

	FancyPrint "$(printf "%s\n" 'Special Endpoint Only Examples...')" "1" "1"
	FancyPrint "$(printf "%-30s %s\n" 'NRG:::' 'Return all Endpoint objects in the UNREGISTERED state.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" '100:::' 'Return all Endpoint objects in the REGISTERING state.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" '200:::' 'Return all Endpoint objects in the OFFLINE state.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" '300:::' 'Return all Endpoint objects in the ONLINE state.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" 'ERR:::' 'Return all Endpoint objects in the ERROR/OTHER state.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::CL:::' 'Return all Endpoint objects that are CLIENTS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::ZTCL:::' 'Return all Endpoint objects that are ZITI CLIENTS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::GW:::' 'Return all Endpoint objects that are INTERNET GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::AWSCPEGW:::' 'Return all Endpoint objects that are AWS GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::AZCPEGW:::' 'Return all Endpoint objects that are AZURE GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::AZSGW:::' 'Return all Endpoint objects that are AZURE STACK GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::GCPCPEGW:::' 'Return all Endpoint objects that are GCP/GOOGLE GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::ZTGW:::' 'Return all Endpoint objects that are HOSTED ZITI BRIDGE GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" ':::ZTNHGW:::' 'Return all Endpoint objects that are PRIVATE ZITI BRIDGE GATEWAYS.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n\n" ':::VCPEGW:::' 'Return all Endpoint objects that are GENERIC VM GATEWAYS.')" "0" "0"

	FancyPrint "$(printf "%s\n" 'Combination Special Endpoint Only Examples...')" "1" "1"
	FancyPrint "$(printf "%-30s %s\n" '200:::CL:::Dipesh' 'Return all Endpoint objects that are OFFLINE, are a CLIENT, and begin with "Dipesh" in their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" '300:::.*:::.*Kapil' 'Return all Endpoint objects that are ONLINE, are ANY TYPE, and begin with "[anychars]Kapil" in their name.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n\n" '(ERR|200):::CL' 'Return all Endpoint objects that are OFFLINE or in ERROR and are a CLIENT.')" "0" "0"

	FancyPrint "$(printf "%s\n" 'Special Services Only Examples...')" "1" "1"
	FancyPrint "$(printf "%-30s %s\n" ':::GW:::' 'Return all Service objects that are the type "GATEWAY".')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n\n" ':::CS:::' 'Return all Service objects that are the type "CLIENTSERVER".')" "0" "0"

	FancyPrint "$(printf "%s\n" 'Navigation...')" "1" "1"
	FancyPrint "$(printf "%-30s %s\n" 'BACK' 'Go back to the previous prompt.')" "0" "0"
	FancyPrint "$(printf "%-30s %s\n" 'QUIT' 'Completely exit the program.')" "0" "0"
}

#################################################################################
# Save a filter string from the user for Endpoints.
function GetFilterString() {
	# 1/PROMPT
	local FilterPrompt
	FilterPrompt="${1}"

	# Trigger the next sovereign call to collect all contextual information.
	unset FilterString

	# Loop until an answer is given.
	while true; do

		[[ ${FilterPrompt} != "" ]] \
			&& AttentionMessage "GENERALINFO" "${FilterPrompt}"

		! GetResponse "Enter a REGEX/GREP phrase to filter results against. [HINT: NoFilter=\".\"] [HELP=\"HELPME\"]" "${PrimaryFilterString:-.}" \
			&& ClearLines "2" \
			&& return 1

		case $(tr '[:lower:]' '[:upper:]' <<<"${UserResponse}") in
			"HELPME")
				FilterHelp
			;;
			*)
				break
			;;
		esac

	done

	# This global variable can be read by the API call function.
	PrimaryFilterString="${UserResponse}"

	return 0
}

#################################################################################
# Process and return responses from the API system.
function ProcessResponse() {
	# 1/CURLSYNTAX 2/URL 3/EXPECTEDRESPONSE 4/QUIET[OPTIONAL]
	trap '' SIGINT SIGTERM # Ignore CTRL+C events.

	# Get the JSON with CURL HTTP headers.
	OutputResponse="$(eval "${1} ${2}" | tr -d '\r')"

	trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.

	# Get the CURL HTTP headers isolated.
	OutputHeaders="$(sed '/^$/,/^$/d' <<< "${OutputResponse}")"

	# Remove the headers from the OutputResponse to get the JSON only.
	OutputJSON="$(sed '1,/^\s*$/d' <<< "${OutputResponse}")"

	# Illuminate what the API call actually looked like if TeachMode is active.
	AttentionMessage "TEACHMODE" "This API call was formed as follows..." "${1:-ERROR} ${2:-ERROR}"

	# Check the headers for the target response.
	case "${OutputHeaders:-NONE}" in
		"HTTP/2 ${3}"*)
			AttentionMessage "DEBUG" "HTTP response was..." "$(echo "${OutputHeaders:-NO RESPONSE}" | cat -v)"
			return 0
		;;
		*)
			[[ ${4} == "VERBOSE" ]] \
				&& AttentionMessage "ERROR" "HTTP response was not equal to expected response \"${3}\"."
			AttentionMessage "DEBUG" "HTTP response was..." "${OutputHeaders:-NO RESPONSE}"
			return 1
		;;
	esac
}

#################################################################################
# Gets objects using the API.
function GetObjects_V7C() {
	function DeriveDetail() {
		# 1/INPUTLIST 2/INPUTTYPE
		local InputList InputType InputSelection InputSelectionBank OutputLinks OutputJSONBank
		InputList=( ${1} ) # An array of objects.
		InputType="${2}" # A specific type.
		InputSelectionBank="${3}" # From looped calls into this function - the parent selection.

		[[ ${#InputList[*]} -eq 0 ]] || ! GetSelection "Derive more detail (TYPE [${InputType}]) on which of the following?" "${InputList[*]}" \
			&& return 1 # No links to follow.
		InputSelection="${UserResponse}"

		# Only the first call will set this for future looped calls.
		[[ -z ${InputSelectionBank} ]] \
			&& InputSelectionBank="${InputSelection}"

		# Get the raw JSON output.
		if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/${InputType}/${InputSelection##*=>}${METAOptions}" "200"; then

			OutputJSONBank="${OutputJSON}" # Save the raw JSON output into the localized variable.

			# Gather next level data from the JSON.
			read -d '' -ra OutputLinks < <( \
				jq -r '
					select(.data != null)
					| .data._links[]
					| .href
				' <<< "${OutputJSONBank}" \
				| grep -Ev "${InputSelection##*=>}$"
			)

			# Iterate up and down in links until the user is done.
			while true; do

				if [[ ${#OutputLinks[*]} -eq 0 ]]; then
					ClearLines "ALL"
					{
						AttentionMessage "GREENINFO" "The following is derived detail (TYPE [${InputType}]) for \"${InputSelectionBank##*:::}\"."
						AttentionMessage "GREENINFO" "The sub-link for the derived detail is \"${InputSelection##*:::}\"."
						AttentionMessage "GREENINFO" "Navigate up and down with arrow keys or press \"q\" to return to the menu."
						jq -Cr <<< "${OutputJSONBank}"
					} | less -r
				else
					ClearLines "ALL"
					AttentionMessage "GREENINFO" "The following is derived detail (TYPE [${InputType}]) for \"${InputSelection##*:::}\"."
					jq -r <<< "${OutputJSONBank}"
				fi

				DeriveDetail "${OutputLinks[*]//.\/${InputType}\//}" "${InputType}" "${InputSelectionBank}" \
					&& continue \
					|| break

			done

			return 0

		else

			AttentionMessage "REDINFO" "No data was returned."
			return 1

		fi
	}
	function StoreDetail() {
		# 1/INPUTURL
		local InputURL
		InputURL="${1}"
		# Global variable OutputJSON stores the output.
		ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/${InputURL}" "200"
	}

	# 1/TYPE 2/[LISTMODE & URLTRAIL] 3/EXPLICITID
	local ListType ListMode URLTrail AlertStyle
	local i j METAOptions="?limit=5000"
	local OutputResponse OutputHeaders OutputJSON
	ListType="${1}"
	ListMode="${2}" # Options: BLANK=DEFAULTURL, URL=SPECIFICURL, FOLLOW-XYZ=LOOPWITHXYZTYPE, DERIVEDETAIL=OUTPUTSPECIFICJSON
	URLTrail="${2/FOLLOW*/}" # In FOLLOW-XYZ mode, there is no input URLTrail, so set it to blank (default URLTrail will be used).

	case ${ListType} in

		"NETWORKMETADATA_V7C")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[1]}/network-support/${Target_NETWORK[0]}" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "IP_ADDRESS=>SESSION_TOKEN" >&2

				read -d '' -ra NetworkAccess_V7C < <( \
					jq -r '
						select(.id != null)
						.ipAddress, .zitiApiUsername, .zitiApiPassword
					' <<< "${OutputJSON}"
				)

				# Expect that THREE items were returned for the V7 Controller (1=IP, 2=USERNAME, 3=PASSWORD)
				if [[ ${#NetworkAccess_V7C[*]} -ne 3 ]]; then

					PrintHelper "BOXITEMA" "META01" "ERROR:::ERROR" "No V7 Controller Metadata Found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				else

					APIRESTURL[2]="https://${NetworkAccess_V7C[0]}/edge/v1" # Initilized from CheckBearerToken function, this updates it for Direct V7 Controller access.
					INITPOSTSyntax_V7C="curl -sSkim ${CURLMaxTime} -X POST -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -d '{\"username\": \"${NetworkAccess_V7C[1]}\", \"password\": \"${NetworkAccess_V7C[2]}\"}'"
					INITGETSyntax_V7C="curl -sSkim ${CURLMaxTime} -X GET -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -d '{\"username\": \"${NetworkAccess_V7C[1]}\", \"password\": \"${NetworkAccess_V7C[2]}\"}'"
					if ProcessResponse "${INITPOSTSyntax_V7C}" "${APIRESTURL[2]}/authenticate?method=password" "200"; then

						read -d '' -r NetworkSession_V7C < <( \
							jq -r '
								select(.data.token != null)
								| .data.token
							' <<< "${OutputJSON}"
						)

						if [[ -z ${NetworkSession_V7C} ]]; then

							PrintHelper "BOXITEMA" "META01" "ERROR:::ERROR" "No V7 Metadata Found (Phase 2)." >&2
							PrintHelper "BOXFOOTLINEA" >&2
							return 1

						else


							NetworkMetadata_V7C[0]="${NetworkAccess_V7C[0]}=>${NetworkSession_V7C}" # ControllerIP => ZT-Session-Token
							if ProcessResponse "${INITGETSyntax_V7C}" "https://${NetworkAccess_V7C[0]}" "200"; then
								read -d '' -r NetworkMetadata_V7C[1] < <( \
									jq -r '
										select(.data != null)
										| .data.version
									' <<< "${OutputJSON}"
								)
							else
								NetworkMetadata_V7C[1]="VERSION RECEIPT FAILURE."
							fi
							if ProcessResponse "${INITGETSyntax_V7C}" "https://${NetworkAccess_V7C[0]}/.well-known/est/cacerts" "200"; then
								NetworkMetadata_V7C[2]="$(openssl base64 -d <<<"${OutputJSON}" | openssl pkcs7 -inform DER -outform PEM -print_certs)" # The CA Certificate in PEM format.
							else
								NetworkMetadata_V7C[2]="CERTIFICATE RECEIPT FAILURE."
							fi

							# New V7 calls.
							GETSyntax_V7C="curl -sSLkim ${CURLMaxTime} -X GET -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Cookie: zt-session=${NetworkSession_V7C}\""
							PUTSyntax_V7C="curl -sSLkim ${CURLMaxTime} -X PUT -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Cookie: zt-session=${NetworkSession_V7C}\""
							POSTSyntax_V7C="curl -sSLkim ${CURLMaxTime} -X POST -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Cookie: zt-session=${NetworkSession_V7C}\""
							DELETESyntax_V7C="curl -sSLkim ${CURLMaxTime} -X DELETE -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Cookie: zt-session=${NetworkSession_V7C}\""

							# Release uncessary sensitive variables.
							NetworkSession_V7C="${RANDOM}${RANDOM}" # Scramble the session token.
							INITPOSTSyntax_V7C="${RANDOM}${RANDOM}" # Scramble the initial POST.
							INITGETSyntax_V7C="${RANDOM}${RANDOM}" # Scramble the initial GET.
							unset NetworkSession_V7C INITPOSTSyntax_V7C INITGETSyntax_V7C # Remove the variables.

							PrintHelper "BOXITEMA" "META01" "NORMAL:::META DATA" "${NetworkAccess_V7C[0]}=>${NetworkSession_V7C}" >&2
							PrintHelper "BOXFOOTLINEA" >&2
							return 0

						fi

					fi

				fi

			fi

			return 1
		;;

		"ENDPOINTS"|"DERIVE-ENDPOINT")
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/identities${METAOptions}" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>ID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				#  STATUS = ACTIVE or INACTIVE
				#  STATE  = ONLINE or OFFLINE
				read -d '' -ra AllEndpoints < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| sort_by(.name)
							| .[]
						)
						| select(.type.name == "Device")
						| if (.hasApiSession) then
								.hasApiSession = "ONLINE"
							else
								.hasApiSession = "OFFLINE"
							end
						| if (.hasEdgeRouterConnection) then
								.hasEdgeRouterConnection = "ACTIVE"
							else
								.hasEdgeRouterConnection = "INACTIVE"
							end
						| if (.enrollment.ott != null) then
								"UNREGISTERED:::" + (
									(
										(.enrollment.ott.expiresAt | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) - (now)
									) | tostring | split(".")[0]
								) + ":::" + .name + "=>" + (._links.self.href | split("/"))[-1]
							else
								.hasApiSession + ":::" + .hasEdgeRouterConnection + ":::" + .name + "=>" + (._links.self.href | split("/"))[-1]
							end
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllEndpoints[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "EPT...." "WARNING:::WARNING" "No Endpoints found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent ListObject calls.
					for ((i=0;i<${#AllEndpoints[*]};i++)); do

						# REGSTATE|APISESSION:::REGEXPIREDATE|ROUTERCONNECTION:::NAME=>POLICYID
						unset Target_ENDPOINT[{0..3}]
						Target_ENDPOINT[0]="${AllEndpoints[${i}]}"
						Target_ENDPOINT[0]="${Target_ENDPOINT[0]/=>${Target_ENDPOINT[3]:=${Target_ENDPOINT[0]##*=>}}/}" # POLICYID
						Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[2]:=${Target_ENDPOINT[0]##*:::}}/}" # NAME
						Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[1]:=${Target_ENDPOINT[0]##*:::}}/}" # REGEXPIREDATE|ROUTERCONNECTION
						Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[0]:=${Target_ENDPOINT[0]##*:::}}/}" # REGSTATE|APISESSION

						if [[ ${Target_ENDPOINT[0]} == "UNREGISTERED" ]]; then
							[[ ${Target_ENDPOINT[1]} -lt 0 ]] \
								&& Target_ENDPOINT[1]="EXPIRED" \
								|| Target_ENDPOINT[1]="UNREGISTERED"
						fi

						PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "${Target_ENDPOINT[0]}:::${Target_ENDPOINT[1]}_ENDPOINT" "${Target_ENDPOINT[2]}=>${Target_ENDPOINT[3]}"

						case ${ListMode} in
							"FOLLOW-APPWANS")
								:
							;;

							"FOLLOW-PSERVICES")
								# Give the user the ability to halt further analysis.
								if [[ $((i%25)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
									! GetYorN "Shown ${i}/${#AllEndpoints[*]} - Show more?" "Yes" "5" \
										&& ClearLines "1" \
										&& break
								fi

								PrintHelper "BOXITEMASUBLINEA"

								if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/identities/${Target_ENDPOINT[3]}/service-policies" "200"; then

									read -d '' -ra AllServices < <( \
										jq -r '
											[(
												select(.data != null)
												| .data[]
												| select(.type == "Bind")
											)]
											| sort_by(.name)[]
											| (
												.name
												| sub("_BindPolicy";"")
											) + "=>" + .id
										' <<< "${OutputJSON}"
									)

									if [[ ${#AllServices[*]} -eq 0 ]]; then
										if [[ $((i+1)) -ne ${#AllEndpoints[*]} ]]; then
											ClearLines "1"
											PrintHelper "BOXMIDLINEB"
										else
											ClearLines "1"
											PrintHelper "BOXFOOTLINEA"
											return 0
										fi
										continue
									else
										for ((j=0;j<${#AllServices[*]};j++)); do
											if [[ $((j+1)) -ne ${#AllServices[*]} ]]; then
												PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((j+1))")" "NORMAL:::SERVICE" "┣━${AllServices[${j}]}"
											else
												PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((j+1))")" "NORMAL:::SERVICE" "┗━${AllServices[${j}]}"
											fi
										done
									fi

								fi
							;;

							"FOLLOW-ASERVICES")
								# Give the user the ability to halt further analysis.
								if [[ $((i%10)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
									! GetYorN "Shown ${i}/${#AllEndpoints[*]} - Show more?" "Yes" "5" \
										&& ClearLines "1" \
										&& break
								fi

								PrintHelper "BOXITEMASUBLINEA"

								if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/identities/${Target_ENDPOINT[3]}/service-policies${METAOptions}" "200"; then

									read -d '' -ra AllServicePolicies < <( \
										jq -r '
											[(
												select(.data != null)
												| .data[]
												| select(.type == "Dial")
											)]
											| sort_by(.name)[]
											| (
												.name
											) + "=>" + .id
										' <<< "${OutputJSON}"
									)

									if [[ ${#AllServicePolicies[*]} -eq 0 ]]; then

										if [[ $((i+1)) -ne ${#AllEndpoints[*]} ]]; then
											ClearLines "1"
											PrintHelper "BOXMIDLINEB"
										else
											ClearLines "1"
											PrintHelper "BOXFOOTLINEA"
											return 0
										fi
										continue

									else

										for ((j=0;j<${#AllServicePolicies[*]};j++)); do

											Target_SERVICEPOLICY[0]=${AllServicePolicies[${j}]%%=>*} # NAME
											Target_SERVICEPOLICY[1]=${AllServicePolicies[${j}]##*=>} # POLICY ID

											if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/service-policies/${Target_SERVICEPOLICY[1]}/services${METAOptions}" "200"; then

												read -d '' -ra AllServices < <( \
													jq -r '
														[(
															select(.data != null)
															| .data[]
														)]
														| sort_by(.name)[]
														| (
															.name
														) + "=>" + .id
													' <<< "${OutputJSON}"
												)

												# No Services in the Service Policy?
												if [[ ${#AllServices[*]} -eq 0 ]]; then
													PrintHelper "BOXITEMASUB" "SPL$(printf "%04d" "$((j+1))")" "WARNING:::EMPTY_SERVICEPOLICY" "${AllServicePolicies[${j}]}"
													continue
												else
													PrintHelper "BOXITEMASUB" "SPL$(printf "%04d" "$((j+1))")" "NORMAL:::SERVICEPOLICY" "┏${AllServicePolicies[${j}]}"
												fi

												for ((k=0;k<${#AllServices[*]};k++)); do

													Target_SERVICE[0]=${AllServices[${j}]%%=>*} # NAME
													Target_SERVICE[1]=${AllServices[${j}]##*=>} # POLICY ID

													if [[ $((k+1)) -ne ${#AllServices[*]} ]]; then
														PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((k+1))")" "NORMAL:::SERVICE" "┣━${AllServices[${k}]}"
													else
														PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((k+1))")" "NORMAL:::SERVICE" "┗━${AllServices[${k}]}"
													fi

												done

											fi

										done

									fi

								fi
							;;

						esac

						[[ $((i+1)) -lt ${#AllEndpoints[*]} ]] \
							&& PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					if [[ ${ListType} == "DERIVE-ENDPOINT" ]]; then

						DeriveDetail "${AllEndpoints[*]}" "identities"

					else

						for ((i=0;i<${#AllEndpoints[*]};i++)); do

							# REGSTATE|APISESSION:::REGEXPIREDATE|ROUTERCONNECTION:::NAME=>POLICYID
							unset Target_ENDPOINT[{0..3}]
							Target_ENDPOINT[0]="${AllEndpoints[${i}]}"
							Target_ENDPOINT[0]="${Target_ENDPOINT[0]/=>${Target_ENDPOINT[3]:=${Target_ENDPOINT[0]##*=>}}/}" # POLICYID
							Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[2]:=${Target_ENDPOINT[0]##*:::}}/}" # NAME
							Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[1]:=${Target_ENDPOINT[0]##*:::}}/}" # REGEXPIREDATE|ROUTERCONNECTION
							Target_ENDPOINT[0]="${Target_ENDPOINT[0]/:::${Target_ENDPOINT[0]:=${Target_ENDPOINT[0]##*:::}}/}" # REGSTATE|APISESSION

							if [[ ${Target_ENDPOINT[0]} == "UNREGISTERED" ]]; then
								[[ ${Target_ENDPOINT[1]} -lt 0 ]] \
									&& Target_ENDPOINT[1]="EXPIRED" \
									|| Target_ENDPOINT[1]="UNREGISTERED"
							fi

							# URLTrail specification indicates this is a secondary GetObjects_V7C call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllEndpoints[*]} ]]; then
									PrintHelper "BOXITEMASUB" "EPT$(printf "%04d" "$((i+1))")" "${Target_ENDPOINT[0]}:::${Target_ENDPOINT[1]}_ENDPOINT" "┣━${Target_ENDPOINT[2]}=>${Target_ENDPOINT[3]}"
								else
									PrintHelper "BOXITEMASUB" "EPT$(printf "%04d" "$((i+1))")" "${Target_ENDPOINT[0]}:::${Target_ENDPOINT[1]}_ENDPOINT" "┗━${Target_ENDPOINT[2]}=>${Target_ENDPOINT[3]}"
								fi
							else
								PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "${Target_ENDPOINT[0]}:::${Target_ENDPOINT[1]}_ENDPOINT" "${Target_ENDPOINT[2]}=>${Target_ENDPOINT[3]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"EDGEROUTERS"|"DERIVE-EDGEROUTERS")
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/edge-routers${METAOptions}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>ID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllEdgeRouters < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| sort_by(.name)
							| .[]
						)
						| if (.isOnline) then
								.isOnline = "ONLINE"
							else
								.isOnline = "OFFLINE" | .hostname = "0:0"
							end
						| if (.isVerified) then
								.isVerified = "VERFIED"
							else
								.isVerified = "UNVERFIED"
							end
						| .isOnline + ":::" + .isVerified + ":::" + .name + ":::" + .hostname + "=>" +.id
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllEdgeRouters[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "EPT...." "WARNING:::WARNING" "No EdgeRouters found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					:

				else

					if [[ ${ListType} == "DERIVE-EDGEROUTERS" ]]; then

						DeriveDetail "${AllEdgeRouters[*]}" "edge-routers"

					else

						for ((i=0;i<${#AllEdgeRouters[*]};i++)); do

							# ONLINESTATUS:::VERIFIEDSTATUS:::NAME:::HOSTNAME:PORT=>POLICYID
							unset Target_EDGEROUTER[{0..4}]
							Target_EDGEROUTER[0]="${AllEdgeRouters[${i}]}"
							Target_EDGEROUTER[0]="${Target_EDGEROUTER[0]/=>${Target_EDGEROUTER[4]:=${Target_EDGEROUTER[0]##*=>}}/}" # POLICYID
							Target_EDGEROUTER[0]="${Target_EDGEROUTER[0]/:::${Target_EDGEROUTER[3]:=${Target_EDGEROUTER[0]##*:::}}/}" # HOSTNAME:PORT
							Target_EDGEROUTER[0]="${Target_EDGEROUTER[0]/:::${Target_EDGEROUTER[2]:=${Target_EDGEROUTER[0]##*:::}}/}" # NAME
							Target_EDGEROUTER[0]="${Target_EDGEROUTER[0]/:::${Target_EDGEROUTER[1]:=${Target_EDGEROUTER[0]##*:::}}/}" # VERIFIEDSTATUS
							Target_EDGEROUTER[0]="${Target_EDGEROUTER[0]/:::${Target_EDGEROUTER[0]:=${Target_EDGEROUTER[0]##*:::}}/}" # ONLINESTATUS

							# URLTrail specification indicates this is a secondary GetObjects_V7C call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllEdgeRouters[*]} ]]; then
									PrintHelper "BOXITEMASUB" "ERT$(printf "%04d" "$((i+1))")" "${Target_EDGEROUTER[0]}:::${Target_EDGEROUTER[1]}_EDGEROUTER" "┣━$(printf "%-42.42s %15.15s:%-4.4s" "${Target_EDGEROUTER[2]}" "${Target_EDGEROUTER[3]%%:*}" "${Target_EDGEROUTER[3]##*:}")=>${Target_EDGEROUTER[4]}"
								else
									PrintHelper "BOXITEMASUB" "ERT$(printf "%04d" "$((i+1))")" "${Target_EDGEROUTER[0]}:::${Target_EDGEROUTER[1]}_EDGEROUTER" "┗━$(printf "%-42.42s %15.15s:%-4.4s" "${Target_EDGEROUTER[2]}" "${Target_EDGEROUTER[3]%%:*}" "${Target_EDGEROUTER[3]##*:}")=>${Target_EDGEROUTER[4]}"
								fi
							else
								PrintHelper "BOXITEMA" "ERT$(printf "%04d" "$((i+1))")" "${Target_EDGEROUTER[0]}:::${Target_EDGEROUTER[1]}_EDGEROUTER" "$(printf "%-42.42s %15.15s:%-4.4s" "${Target_EDGEROUTER[2]}" "${Target_EDGEROUTER[3]%%:*}" "${Target_EDGEROUTER[3]##*:}")=>${Target_EDGEROUTER[4]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"SERVICES"|"DERIVE-SERVICE")
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/services${METAOptions}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>ID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllServices < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| sort_by(.name)
							| .[]
						)
						| .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllServices[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "SRV...." "WARNING:::WARNING" "No Services found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					:

				else

					if [[ ${ListType} == "DERIVE-SERVICE" ]]; then

						DeriveDetail "${AllServices[*]}" "services"

					else

						for ((i=0;i<${#AllServices[*]};i++)); do

							# NAME=>POLICYID
							unset Target_SERVICE[{0..1}]
							Target_SERVICE[0]="${AllServices[${i}]}"
							Target_SERVICE[0]="${Target_SERVICE[0]/=>${Target_SERVICE[1]:=${Target_SERVICE[0]##*=>}}/}" # POLICYID
							Target_SERVICE[0]="${Target_SERVICE[0]/:::${Target_SERVICE[0]:=${Target_SERVICE[0]##*:::}}/}" # NAME

							# URLTrail specification indicates this is a secondary GetObjects_MOP call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllServices[*]} ]]; then
									PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::SERVICE" "┣━${Target_SERVICE[0]}=>${Target_SERVICE[1]}"
								else
									PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::SERVICE" "┗━${Target_SERVICE[0]}=>${Target_SERVICE[1]}"
								fi
							else
								PrintHelper "BOXITEMA" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::SERVICE" "${Target_SERVICE[0]}=>${Target_SERVICE[1]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"ENROLLMENTS"|"DERIVE-ENROLLMENTS")
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/enrollments${METAOptions}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TIME LEFT" "DESCRIPTION=>ID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllEnrollments < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| group_by(.method)[]
							| sort_by(.expiresAt)
							| .[]
						)|.edgeRouter.name? as $THISERTNAME
						|.identity.name? as $THISEPTNAME
						|(((.expiresAt | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) - (now))| tostring | split(".")[0]) as $THISEXPDATE
						|((._links.self.href | split("/"))[-1]) as $THISPOLICYID
						| if ($THISEPTNAME != null) then
							"[EPT] " + $THISEPTNAME + ":::" + $THISEXPDATE + "=>" + $THISPOLICYID
						elif ($THISERTNAME != null) then
							"[ERT] " + $THISERTNAME + ":::" + $THISEXPDATE + "=>" + $THISPOLICYID
						else
							empty
						end
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllEnrollments[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "ENR...." "NORMAL:::INFO" "No outstanding Enrollments found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					:

				else

					if [[ ${ListType} == "DERIVE-ENROLLMENTS" ]]; then

						DeriveDetail "${AllEnrollments[*]}" "enrollments"

					else

						for ((i=0;i<${#AllEnrollments[*]};i++)); do

							unset AlertStyle

							# NAME:::EXPIREDATE=>POLICYID
							unset Target_ENROLLMENT[{0..7}]
							Target_ENROLLMENT[0]="${AllEnrollments[${i}]}"
							Target_ENROLLMENT[0]="${Target_ENROLLMENT[0]/=>${Target_ENROLLMENT[2]:=${Target_ENROLLMENT[0]##*=>}}/}" # POLICYID
							Target_ENROLLMENT[0]="${Target_ENROLLMENT[0]/:::${Target_ENROLLMENT[1]:=${Target_ENROLLMENT[0]##*:::}}/}" # EXPIREDATE
							Target_ENROLLMENT[0]="${Target_ENROLLMENT[0]/:::${Target_ENROLLMENT[0]:=${Target_ENROLLMENT[0]##*:::}}/}" # NAME
							Target_ENROLLMENT[3]="$((Target_ENROLLMENT[1]/86400))" # DAYS LEFT
							Target_ENROLLMENT[4]="$((Target_ENROLLMENT[1]%24))" # HOURS LEFT
							Target_ENROLLMENT[5]="$((Target_ENROLLMENT[1]%3600/60))" # MINUTES LEFT
							Target_ENROLLMENT[6]="$((Target_ENROLLMENT[1]%60))" # SECONDS LEFT
							Target_ENROLLMENT[7]="$(printf '%4sd %4sh %4sm %4ss' "${Target_ENROLLMENT[3]}" "${Target_ENROLLMENT[4]}" "${Target_ENROLLMENT[5]}" "${Target_ENROLLMENT[6]}")"

							# For the color of the line, evaluate the time until expiration and set the AlertStyle.
							if [[ ${Target_ENROLLMENT[1]} -gt 43200 ]]; then
								AlertStyle="NORMAL"
							elif [[ ${Target_ENROLLMENT[1]} -le 43200 ]] && [[ ${Target_ENROLLMENT[1]} -gt 0 ]]; then
								AlertStyle="WARNING"
							else
								AlertStyle="ALERT"
							fi

							# URLTrail specification indicates this is a secondary GetObjects_V7C call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllEnrollments[*]} ]]; then
									PrintHelper "BOXITEMASUB" "ENR$(printf "%04d" "$((i+1))")" "${AlertStyle}:::${Target_ENROLLMENT[7]}" "┣━${Target_ENROLLMENT[0]}=>${Target_ENROLLMENT[2]}"
								else
									PrintHelper "BOXITEMASUB" "ENR$(printf "%04d" "$((i+1))")" "${AlertStyle}:::${Target_ENROLLMENT[7]}" "┗━${Target_ENROLLMENT[0]}=>${Target_ENROLLMENT[2]}"
								fi
							else
								PrintHelper "BOXITEMA" "ENR$(printf "%04d" "$((i+1))")" "${AlertStyle}:::${Target_ENROLLMENT[7]}" "${Target_ENROLLMENT[0]}=>${Target_ENROLLMENT[2]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"VERSIONS")
			AttentionMessage "GENERALINFO" "Gathering version information on all Endpoints."
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/identities${METAOptions}" "200"; then
				ClearLines "1"
				read -d '' -ra AllEndpointVersions < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| sort_by(.name)
							| .[]
						)
						| select(.type.name == "Device")
						| "[EPT] " + .name + ":::" + .sdkInfo.version + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)
			else
				AttentionMessage "YELLOWINFO" "There were no Endpoints present."
				sleep 3
				ClearLines "1"
			fi

			AttentionMessage "GENERALINFO" "Gathering version information on all EdgeRouters."
			if ProcessResponse "${GETSyntax_V7C}" "${APIRESTURL[2]}/edge-routers${METAOptions}" "200"; then
				ClearLines "1"
				read -d '' -ra AllEdgeRouterVersions < <( \
					jq -r '
						(
							select(.data != null)
							| .data
							| sort_by(.name)
							| .[]
						)
						| select(.versionInfo.version != "")
						| "[ERT] " + .name + ":::" + .versionInfo.version + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
				)
			else
				AttentionMessage "YELLOWINFO" "There were no EdgeRouters present."
				sleep 3
				ClearLines "1"
			fi

			PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::VERSION" "DESCRIPTION=>UUID | ID"

			# Combine all versions available.
			AllVersions=( ${AllEdgeRouterVersions[*]} ${AllEndpointVersions[*]} )

			# No reason to continue if there are no objects to analyze.
			if [[ ${#AllVersions[*]} -eq 0 ]]; then

				PrintHelper "BOXITEMA" "VER...." "ERROR:::INFO" "No Endpoints or EdgeRouters found."
				PrintHelper "BOXFOOTLINEA"
				return 1

			else

				# First item will always be the network metadata.
				PrintHelper "BOXITEMA" "VER0000" "NORMAL:::${NetworkMetadata_V7C[1]}" "[NET] ${Target_NETWORK[1]}=>${Target_NETWORK[0]}"
				
				# VER_MAJOR.VER_MINOR.VER_PATCH-EXTRA
				unset Target_NETDETAIL[{0..2}]
				Target_NETDETAIL[0]="${NetworkMetadata_V7C[1]}"
				Target_NETDETAIL[0]="${Target_NETDETAIL[0]/\.${Target_NETDETAIL[2]:=${Target_NETDETAIL[0]##*\.}}/}" # VER_PATCH-EXTRA
				Target_NETDETAIL[0]="${Target_NETDETAIL[0]/\.${Target_NETDETAIL[1]:=${Target_NETDETAIL[0]##*\.}}/}" # VER_MINOR
				Target_NETDETAIL[0]="${Target_NETDETAIL[0]/\.${Target_NETDETAIL[0]:=${Target_NETDETAIL[0]##*\.}}/}" # VER_MAJOR

				for ((i=0;i<${#AllVersions[*]};i++)); do

					unset AlertStyle

					# NAME:::VERSION=>POLICYID
					unset Target_VERSION[{0..2}] 
					Target_VERSION[0]="${AllVersions[${i}]}"
					Target_VERSION[0]="${Target_VERSION[0]/=>${Target_VERSION[2]:=${Target_VERSION[0]##*=>}}/}" # POLICYID
					Target_VERSION[0]="${Target_VERSION[0]/:::${Target_VERSION[1]:=${Target_VERSION[0]##*:::}}/}" # VERSION
					Target_VERSION[0]="${Target_VERSION[0]/:::${Target_VERSION[0]:=${Target_VERSION[0]##*:::}}/}" # NAME

					# VER_MAJOR.VER_MINOR.VER_PATCH-EXTRA
					unset Target_VERSIONDETAIL[{0..2}]
					Target_VERSIONDETAIL[0]="${Target_VERSION[1]}"
					Target_VERSIONDETAIL[0]="${Target_VERSIONDETAIL[0]/\.${Target_VERSIONDETAIL[2]:=${Target_VERSIONDETAIL[0]##*\.}}/}" # VER_PATCH-EXTRA
					Target_VERSIONDETAIL[0]="${Target_VERSIONDETAIL[0]/\.${Target_VERSIONDETAIL[1]:=${Target_VERSIONDETAIL[0]##*\.}}/}" # VER_MINOR
					Target_VERSIONDETAIL[0]="${Target_VERSIONDETAIL[0]/\.${Target_VERSIONDETAIL[0]:=${Target_VERSIONDETAIL[0]##*\.}}/}" # VER_MAJOR

					# For the color of the line, evaluate against the MINOR version of the network. 
					# ONLY if the version is available.
					if [[ -n ${Target_VERSIONDETAIL[0]} ]]; then
						# Greater than 2 versions older or newer than 1 version against the network version.
						if [[ $((Target_VERSIONDETAIL[1]-Target_NETDETAIL[1])) -gt 2 ]] || [[ $((Target_NETDETAIL[1]-Target_VERSIONDETAIL[1])) -gt 2 ]]; then
							AlertStyle="ALERT"
						# Greater than 1 versions older or newer than 1 version against the network version.
						elif [[ $((Target_VERSIONDETAIL[1]-Target_NETDETAIL[1])) -ge 1 ]] || [[ $((Target_NETDETAIL[1]-Target_VERSIONDETAIL[1])) -ge 1 ]]; then
							AlertStyle="WARNING"
						# Same version.
						else
							AlertStyle="NORMAL"
						fi
						# Override if the MAJOR version is different.
						if [[ ${Target_VERSIONDETAIL[0]/v/} =~ ^[0-9]+$ ]] && ([[ $((${Target_VERSIONDETAIL[0]/v/}-${Target_NETDETAIL[0]/v/})) -ge 1 ]] || [[ $((${Target_NETDETAIL[0]/v/}-${Target_VERSIONDETAIL[0]/v/})) -ge 1 ]]); then
							AlertStyle="ALERT"
						fi
					else 
						AlertStyle="UNREGISTERED"
					fi

					PrintHelper "BOXITEMA" "VER$(printf "%04d" "$((i+1))")" "${AlertStyle:-NORMAL}:::${Target_VERSION[1]}" "${Target_VERSION[0]}=>${Target_VERSION[2]}"

				done

				PrintHelper "BOXFOOTLINEA" >&2

			fi

			return 1
		;;

	esac
}

#################################################################################
# Sets objects using the API.
function SetObjects_V7C() {
	# 1/TYPE 2-10/[DATAFIELDS]
	local SetType="${1}"
	local DATASyntax # The syntax to send to API.
	unset SetObjectReturn # Ensure this is not already set.

	# Set what type of object?
	case ${SetType} in

		"LOGOUT")
			# Destroy any V7 metadata information should it exist.
			if [[ ${NetworkMetadata_V7C[0]:-UNSET} == "UNSET" ]] || [[ ${NetworkMetadata_V7C[0]} == "null" ]]; then
				return 0
			else
				if ProcessResponse "${DELETESyntax_V7C}" "${APIRESTURL[2]}/current-api-session" "200"; then
					[[ -n ${NetworkMetadata_V7C[0]} ]] \
						&& NetworkMetadata_V7C=( "${RANDOM}${RANDOM}" "${RANDOM}${RANDOM}" ) \
						&& unset NetworkMetadata_V7C[{0..10}]
					[[ -n ${NetworkAccess_V7C[0]} ]] \
						&& NetworkAccess_V7C=( "${RANDOM}${RANDOM}" "${RANDOM}${RANDOM}" "${RANDOM}${RANDOM}" "${RANDOM}${RANDOM}" ) \
						&& unset NetworkAccess_V7C[{0..10}]
					AttentionMessage "GENERALINFO" "In-Memory V7 Network metadata was destroyed successfully."
					return 0
				else
					AttentionMessage "REDINFO" "In-Memory V7 Network metadata could not be destroyed and potentially continues to exist."
					return 1
				fi
			fi
		;;

	esac

	return 0
}

#################################################################################
# Gets objects using the API.
function GetObjects_MOP() {
	function DeriveDetail() {
		# 1/INPUTLIST 2/INPUTTYPE
		local InputList InputType
		InputList=( ${1} ) # An array of objects.
		InputType="${2}" # Type of objects in the array.
		! GetSelection "Derive more detail on which of the following?" "${InputList[*]}" \
			&& return 0
		if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${InputType}/${UserResponse##*=>}" "200"; then
			AttentionMessage "GENERALINFO" "The following is derived detail for \"${UserResponse%%=>*}\"."
			[[ ${#OutputJSON} -le 1000 ]] \
				&& jq -Cr <<< "${OutputJSONBank}" \
				&& GetYorN "SPECIAL-PAUSE" \
				|| jq -Cr <<< "${OutputJSONBank}" | less -r
		else
			AttentionMessage "REDINFO" "There was no data returned."
		fi
	}

	# 1/TYPE 2/[LISTMODE & URLTRAIL] 3/EXPLICITUUID
	local ListType ListMode URLTrail ExplicitUUID ExplicitUUID AskDelete
	local i j BGPID Target_ENDPOINT Target_ENDPOINTGROUP Target_SERVICE
	local OutputResponse OutputHeaders OutputJSON
	ListType="${1}"
	ListMode="${2}" # Options: BLANK=DEFAULTURL, URL=SPECIFICURL, FOLLOW-XYZ=LOOPWITHXYZTYPE, FOLLOW-ASERVICES=SPECIFICUUID, DERIVEDETAIL=OUTPUTSPECIFICJSON
	URLTrail="${2/FOLLOW*/}" # In FOLLOW-XYZ mode, there is no input URLTrail, so set it to blank (default URLTrail will be used).
	ExplicitUUID="${3}" # In FOLLOW-ASERVICES ListMode (AppWAN Only), use this UUID.
	AskDelete="0" # In certain situations the program will ask the user to delete objects that are orphans.

	case ${ListType} in

		"ORGANIZATIONS")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/organizations" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "ORGANIZATION NAME=>UUID" >&2

				read -d '' -ra AllOrganizations < <( \
					jq -r '
						select(._embedded.organizations != null)
						| ._embedded.organizations
						| .[]
						| .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}"
				)

				if [[ ${#AllOrganizations[*]} -eq 0 ]]; then
					PrintHelper "BOXITEMA" "ORG...." "ERROR:::ERROR" "No Organizations Found." >&2
				else
					for ((i=0;i<${#AllOrganizations[*]};i++)); do
						PrintHelper "BOXITEMA" "ORG$(printf "%04d" "$((i+1))")" "NORMAL:::ORGANIZATION" "${AllOrganizations[${i}]}" >&2
					done
				fi

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"IDTENANTS")
			if ProcessResponse "${GETSyntax_MOP}" "${APIIDENTITYURL}/tenants" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "UUID" >&2

				read -d '' -ra AllIDTenants < <( \
					jq -r '
						select(.[] != null)
						| .[].id
					' <<< "${OutputJSON}"
				)

				if [[ ${#AllIDTenants[*]} -eq 0 ]]; then
					PrintHelper "BOXITEMA" "IDT...." "WARNING:::WARNING" "No Identity Tenants Found." >&2
				else
					for ((i=0;i<${#AllIDTenants[*]};i++)); do
						PrintHelper "BOXITEMA" "IDT$(printf "%04d" "$((i+1))")" "NORMAL:::IDTENANTS" "${AllIDTenants[${i}]}" >&2
					done
				fi

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"NETWORKS_V6")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "NETWORK NAME=>UUID" >&2

				read -d '' -ra AllV6Networks < <( \
					jq -r '
						select(._embedded.networks != null)
						| ._embedded.networks
						| .[]
						| "(V6) " + .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}"
				)

				if [[ ${#AllV6Networks[*]} -eq 0 ]]; then
					PrintHelper "BOXITEMA" "NET...." "WARNING:::WARNING" "No V6 Networks Found." >&2
				else
					for ((i=0;i<${#AllV6Networks[*]};i++)); do
						PrintHelper "BOXITEMA" "NET$(printf "%04d" "$((i+1))")" "NORMAL:::NETWORK" "${AllV6Networks[${i}]}" >&2
					done
				fi

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"NETWORKS_V7")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[1]}/networks" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "NETWORK NAME=>UUID" >&2

				read -d '' -ra AllNetworks_V7 < <( \
					jq -r '
						select(._embedded.networkList != null)
						| ._embedded.networkList
						| .[]
						| "(V7) " + .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}"
				)

				if [[ ${#AllNetworks_V7[*]} -eq 0 ]]; then
					PrintHelper "BOXITEMA" "NET...." "WARNING:::WARNING" "No V7 Network were found." >&2
				else
					for ((i=0;i<${#AllNetworks_V7[*]};i++)); do
						PrintHelper "BOXITEMA" "NET$(printf "%04d" "$((i+1))")" "NORMAL:::NETWORK" "${AllNetworks_V7[${i}]}" >&2
					done
				fi

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"GEOREGIONS"|"SPECIFICGEOREGION")
			local BoxType
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/${URLTrail:-geoRegions}" "200"; then
				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "DESCRIPTION=>UUID" >&2

				if [[ ${ListType} == "SPECIFICGEOREGION" ]]; then
					BoxType="BOXITEMASUB"
					read -d '' -ra AllGeoRegions < <( \
						jq -r '
							select(.name != null)
							| .name + "=>" + (._links.self.href | split("/"))[-1]
						' <<< "${OutputJSON}"
					)
				else
					BoxType="BOXITEMA"
					read -d '' -ra AllGeoRegions < <( \
						jq -r '
							select(._embedded.geoRegions != null)
							| ._embedded.geoRegions
							| sort_by(.name)
							| .[]
							| .name + "=>" + (._links.self.href | split("/"))[-1]
						' <<< "${OutputJSON}" \
						| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
					)
				fi

				if [[ ${#AllGeoRegions[*]} -eq 0 ]]; then
					PrintHelper "${BoxType}" "GEO...." "WARNING:::WARNING" "No GeoRegions Found." >&2
				else
					for ((i=0;i<${#AllGeoRegions[*]};i++)); do
						PrintHelper "${BoxType}" "GEO$(printf "%04d" "$((i+1))")" "NORMAL:::GEOREGION" "${AllGeoRegions[${i}]}"
					done
				fi

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"COUNTRIES")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/countries" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/INDICATOR" "DESCRIPTION=>UUID" >&2

					read -d '' -ra AllCountries < <( \
						jq -r '
							select(._embedded.countries != null)
							| ._embedded.countries
							| sort_by(.worldRegion)
							| .[]
							| .worldRegion + "/" + .name + "=>" + (._links.self.href | split("/"))[-1] + "=>" + (._links.geoRegion.href | split("/"))[-1]
						' <<< "${OutputJSON}" \
						| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}"
					)

				if [[ ${#AllCountries[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "CTY...." "WARNING:::WARNING" "No Countries Found." >&2

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent calls.
					for ((i=0;i<${#AllCountries[*]};i++)); do

						if [[ $((i%10)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
							! GetYorN "Shown ${i}/${#AllCountries[*]} - Show more?" "Yes" "5" \
								&& ClearLines "1" \
								&& break
						fi

						Target_COUNTRY[0]=${AllCountries[${i}]%%=>*} # NAME.
						Target_COUNTRY[1]=${AllCountries[${i}]%=>*} # NAME=>COUNTRYUUID.
						Target_COUNTRY[2]=${AllCountries[${i}]#*=>} # COUNTRYUUID=>GEOUUID.
						Target_COUNTRY[3]=${Target_COUNTRY[2]%=>*} # COUNTRYUUID.
						Target_COUNTRY[4]=${Target_COUNTRY[2]#*=>} # GEOUUID.

						PrintHelper "BOXITEMA" "CTY$(printf "%04d" "$((i+1))")" "NORMAL:::REGION/COUNTRY" "${Target_COUNTRY[1]}" >&2

						case ${ListMode} in
							"FOLLOW-GEOREGION")
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "SPECIFICGEOREGION" "geoRegions/${Target_COUNTRY[4]}" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "CTY...." "WARNING:::WARNING" "No GeoRegion association was found."
							;;
						esac

						[[ $((i+1)) -eq ${#AllCountries[*]} ]] \
							|| PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					for ((i=0;i<${#AllCountries[*]};i++)); do
						PrintHelper "BOXITEMA" "CTY$(printf "%04d" "$((i+1))")" "NORMAL:::REGION/COUNTRY" "${AllCountries[${i}]%=>*}"
					done

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"GATEWAYS")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpoints" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>UUID"

				read -d '' -ra AllGateways < <( \
					jq -r '
						select(._embedded.endpoints != null)
						| ._embedded.endpoints[]
						| select(.endpointType
							| contains("GW"))
						| if ((.status == 100) or (.status == 200) or (.status == 300) or (.status == 600) or (.status == 700)) then
								.currentState = "NRG"
							elif ((.status == 500) or (.status == 800) or (.status == 900)) then
								.currentState = "ERR"
							elif ((.status == 400) and ((.currentState == 100) or (.currentState == 200) or (.currentState == 300))) then
								.currentState = (.currentState | tostring)
							else
								.currentState = "UNKNOWN"
							end
						| .currentState + ":::" + .endpointType + ":::" + .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}"
				)

				if [[ ${#AllGateways[*]} -eq 0 ]]; then
					PrintHelper "BOXITEMA" "EPT...." "WARNING:::WARNING" "No Gateway Endpoints Found." >&2
				else
					for ((i=0;i<${#AllGateways[*]};i++)); do
						PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "NORMAL:::GW_ENDPOINT" "${AllGeoRegions[${i}]}" >&2
					done
				fi

				[[ ${#AllGateways[*]} -eq 0 ]] \
					&& AttentionMessage "WARNING" "No Gateway Endpoints found." >&2
				for ((i=0;i<${#AllGateways[*]};i++)); do
					PrintHelper "BOXITEMA" "ORG$(printf "%04d" "$((i+1))")" "${AllGateways[${i}]%:::*}" "${AllGateways[${i}]##*:::}"
				done

				PrintHelper "BOXFOOTLINEA" >&2
				return 0

			fi

			return 1
		;;

		"ENDPOINT-REGSTATE")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpoints" "200"; then

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				# [1/2/3/X]00:::[REG_ATTEMPTS_LEFT]:::[REGISTRATIONKEY]=>[UUID]
				#  STATUS = 100:NEW, 200:PROVISIONING, 300:PROVISIONED, 400:REGISTERED, 500:ERROR, 600:UPDATING, 700:REPLACING, 800:DELETING, 900:DELETED
				read -d '' -ra AllEndpoints < <( \
					jq -r '
						select(._embedded.endpoints != null)
						| ._embedded.endpoints
						| .[]
						| select(.name == "'${FilterString:-${PrimaryFilterString:-.}}'")
						| (.status | tostring) + ":::" + (.registrationAttemptsLeft | tostring) + ":::" + .registrationKey + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}"
				)

				# If the FilterString (AKA finite name) returned a single status and UUID.
				[[ ${#AllEndpoints[*]} -eq 1 ]] \
					&& return 0 \
					|| return 1

			fi

			return 1
		;;

		"ENDPOINTS"|"DERIVE-ENDPOINT")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail:-endpoints}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>UUID" >&2

				# Special scenario for ENDPOINTS following SERVICE associations.
				[[ ${ListMode} == "FOLLOW-PSERVICES" ]] \
					&& SecondaryFilter=':::CL:::' \
					|| SecondaryFilter='##NOSECONDARYFILTER##'

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				# [1/2/3/X]00:::[TYPE]:::[NAME]:::[UUID]
				#  STATUS = 100:NEW, 200:PROVISIONING, 300:PROVISIONED, 400:REGISTERED, 500:ERROR, 600:UPDATING, 700:REPLACING, 800:DELETING, 900:DELETED
				#  STATE  = 100:REGISTERING, 200:OFFLINE, 300:ONLINE
				read -d '' -ra AllEndpoints < <( \
					jq -r '
						(
							select(._embedded.endpoints != null)
							| ._embedded.endpoints
							| group_by(.endpointType)[]
							| sort_by(.name)
							| .[]
						), select(.name != null)
						| if ((.status == 100) or (.status == 200) or (.status == 300) or (.status == 600) or (.status == 700)) then
								.currentState = "NRG"
							elif ((.status == 500) or (.status == 800) or (.status == 900)) then
								.currentState = "ERR"
							elif ((.status == 400) and ((.currentState == 100) or (.currentState == 200) or (.currentState == 300))) then
								.currentState = (.currentState | tostring)
							else
								.currentState = "UNKNOWN"
							end
						| .currentState + ":::" + .endpointType + ":::" + .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}" \
					| grep -Ev "${SecondaryFilter}"
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllEndpoints[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "EPT...." "WARNING:::WARNING" "No Endpoints found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent ListObject calls.
					for ((i=0;i<${#AllEndpoints[*]};i++)); do

						if [[ $((i%10)) -eq 0 ]] || [[ ${ListMode} =~ "FOLLOW-ASERVICES" ]] && [[ ${i} -ne 0 ]]; then
							! GetYorN "Shown ${i}/${#AllEndpoints[*]} - Show more?" "Yes" "5" \
								&& ClearLines "1" \
								&& break
						fi

						Target_ENDPOINT[0]=${AllEndpoints[${i}]%%=>*}
						Target_ENDPOINT[1]=${AllEndpoints[${i}]##*=>}

						PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "${AllEndpoints[${i}]%:::*}_ENDPOINT" "${AllEndpoints[${i}]##*:::}"

						case ${ListMode} in
							"FOLLOW-ENDPOINTGROUPS")
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "ENDPOINTGROUPS" "endpoints/${Target_ENDPOINT[1]}/endpointGroups" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "EPG...." "NORMAL:::" "No EndpointGroup associations were found."
							;;

							"FOLLOW-APPWANS")
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "APPWANS" "endpoints/${Target_ENDPOINT[1]}/appWans" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "APW...." "NORMAL:::" "No direct AppWAN associations were found."
							;;

							"FOLLOW-PSERVICES")
								# Clients do not provide services and were auto-filtered prior to this switch.
								PrintHelper "BOXITEMASUBLINEA"
								if ! GetObjects_MOP "SERVICES" "endpoints/${Target_ENDPOINT[1]}/services" 2>/dev/null; then
									if [[ ${#AllServices[*]} -eq 0 ]]; then
										ClearLines "1"
										PrintHelper "BOXMIDLINEB"
									else
										ClearLines "1"
										PrintHelper "BOXFOOTLINEA"
										return 0
									fi
									continue
								fi
							;;

							"FOLLOW-ASERVICES")
								PrintHelper "BOXITEMASUBLINEA"
								(
									# Run in a subshell to prevent the global variables from being changed.
									GetObjects_MOP "APPWANS" "FOLLOW-ASERVICES" "${Target_ENDPOINT[1]}" 2>/dev/null
								)
							;;

							"FOLLOW-ALL")
								trap '' SIGINT SIGTERM # Ignore CTRL+C events.
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "ENDPOINTGROUPS" "endpoints/${Target_ENDPOINT[1]}/endpointGroups" 2>/dev/null \
									&& (( AskDelete++ ))
								GetObjects_MOP "SERVICES" "endpoints/${Target_ENDPOINT[1]}/services" 2>/dev/null &
								BGPID[0]=$!
								GetObjects_MOP "APPWANS" "endpoints/${Target_ENDPOINT[1]}/appWans" 2>/dev/null &
								BGPID[1]=$!
								! wait ${BGPID[0]} && (( AskDelete++ ))
								! wait ${BGPID[1]} && (( AskDelete++ ))
								trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.
								if [[ ${AskDelete:-0} -eq 3 ]]; then
									PrintHelper "BOXITEMASUB" "......." "WARNING:::WARNING" "No EndpointGroup, AppWAN, or Service associations were found."
									GetYorN "Do you wish to remove \"${Target_ENDPOINT[0]##*:::}\"?" "No" "10" \
										&& SetObjects_MOP_V6 "DELENDPOINT" "${Target_ENDPOINT[1]}"
									ClearLines "2"
								fi
							;;
						esac

						[[ $((i+1)) -eq ${#AllEndpoints[*]} ]] \
							|| PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					if [[ ${ListType} == "DERIVE-ENDPOINT" ]]; then

						DeriveDetail "${AllEndpoints[*]}" "endpoints"

					else

						for ((i=0;i<${#AllEndpoints[*]};i++)); do

							# URLTrail specification indicates this is a secondary GetObjects_MOP call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllEndpoints[*]} ]]; then
									PrintHelper "BOXITEMASUB" "EPT$(printf "%04d" "$((i+1))")" "${AllEndpoints[${i}]%:::*}_ENDPOINT" "┣━${AllEndpoints[${i}]##*:::}"
								else
									PrintHelper "BOXITEMASUB" "EPT$(printf "%04d" "$((i+1))")" "${AllEndpoints[${i}]%:::*}_ENDPOINT" "┗━${AllEndpoints[${i}]##*:::}"
								fi
							else
								PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "${AllEndpoints[${i}]%:::*}_ENDPOINT" "${AllEndpoints[${i}]##*:::}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"ENDPOINTGROUPS"|"ENDPOINTGROUPS-ENDPOINTS"|"SEARCH-ENDPOINTGROUPS-ENDPOINTS"|"DERIVE-ENDPOINTGROUP")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail:-endpointGroups}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>UUID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllEndpointGroups < <( \
					jq -r '
						select(._embedded.endpointGroups != null)
						| ._embedded.endpointGroups
						| .[]
						| .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}" \
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllEndpointGroups[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "EPG...." "WARNING:::WARNING" "No EndpointGroups found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW-ENDPOINTS" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent ListObject calls.

					for ((i=0;i<${#AllEndpointGroups[*]};i++)); do

						if [[ $((i%10)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
							! GetYorN "Shown ${i}/${#AllEndpointGroups[*]} - Show more?" "Yes" "5" \
								&& ClearLines "1" \
								&& break
						fi

						Target_ENDPOINTGROUP[0]=${AllEndpointGroups[${i}]%%=>*}
						Target_ENDPOINTGROUP[1]=${AllEndpointGroups[${i}]##*=>}

						PrintHelper "BOXITEMA" "EPG$(printf "%04d" "$((i+1))")" "NORMAL:::ENDPOINTGROUP" "${AllEndpointGroups[${i}]}"
						PrintHelper "BOXITEMASUBLINEA"

						! GetObjects_MOP "ENDPOINTS" "endpointGroups/${Target_ENDPOINTGROUP[1]}/endpoints" 2>/dev/null \
							&& PrintHelper "BOXITEMASUB" "EPT...." "NORMAL:::" "No direct Endpoint associations were found." \
							&& (GetYorN "Do you wish to remove \"${Target_ENDPOINTGROUP[0]}\"?" "No" "10" \
								&& SetObjects_MOP_V6 "DELENDPOINTGROUP" "${Target_ENDPOINTGROUP[1]}") \
							&& ClearLines "2"

						[[ $((i+1)) -eq ${#AllEndpointGroups[*]} ]] \
							|| PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					if [[ ${ListType} == "ENDPOINTGROUPS-ENDPOINTS" ]]; then

						# Special mode to sub-retrieve Endpoints within a each specific EndpointGroup.
						for ((i=0;i<${#AllEndpointGroups[*]};i++)); do

							Target_ENDPOINTGROUP[0]=${AllEndpointGroups[${i}]%%=>*}
							Target_ENDPOINTGROUP[1]=${AllEndpointGroups[${i}]##*=>}

							PrintHelper "BOXITEMASUB" "EPG$(printf "%04d" "$((i+1))")" "NORMAL:::ENDPOINTGROUP" "┏${AllEndpointGroups[${i}]}"
							! GetObjects_MOP "ENDPOINTS" "endpointGroups/${Target_ENDPOINTGROUP[1]}/endpoints" 2>/dev/null \
								&& PrintHelper "BOXITEMASUB" "EPT...." "NORMAL:::" "No direct Endpoint associations were found." \
								&& (GetYorN "Do you wish to remove \"${Target_ENDPOINTGROUP[0]}\"?" "No" "10" \
									&& SetObjects_MOP_V6 "DELENDPOINTGROUP" "${Target_ENDPOINTGROUP[1]}") \
								&& ClearLines "2"

							[[ $((i+1)) -eq ${#AllEndpointGroups[*]} ]] \
								|| PrintHelper "BOXMIDLINEA" >&2

						done

					elif [[ ${ListType} == "SEARCH-ENDPOINTGROUPS-ENDPOINTS" ]]; then

						# Special non-printing mode to sub-retrieve Endpoints within a each specific EndpointGroup, searching for one specific.
						for ((i=0;i<${#AllEndpointGroups[*]};i++)); do

							Target_ENDPOINTGROUP[0]=${AllEndpointGroups[${i}]%%=>*}
							Target_ENDPOINTGROUP[1]=${AllEndpointGroups[${i}]##*=>}

							# For each EndpointGroup, search for a specific Endpoint.
							GetObjects_MOP "ENDPOINTS" "endpointGroups/${Target_ENDPOINTGROUP[1]}/endpoints"
							echo -e "${ExplicitUUID}\n${AllEndpoints[*]}"
							[[ "${AllEndpoints[*]}" =~ ${ExplicitUUID} ]] \
								&& return 0 # Endpoint found in this EndpointGroup.

						done

						return 1 # Failure to find the Endpoint in this EndpointGroup.

					elif [[ ${ListType} == "DERIVE-ENDPOINTGROUP" ]]; then

						DeriveDetail "${AllEndpointGroups[*]}" "endpointGroups"

					else

						for ((i=0;i<${#AllEndpointGroups[*]};i++)); do

							# URLTrail specification indicates this is a secondary GetObjects_MOP call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllEndpointGroups[*]} ]]; then
									PrintHelper "BOXITEMASUB" "EPG$(printf "%04d" "$((i+1))")" "NORMAL:::ENDPOINTGROUP" "┣━${AllEndpointGroups[${i}]##*:::}"
								else
									PrintHelper "BOXITEMASUB" "EPG$(printf "%04d" "$((i+1))")" "NORMAL:::ENDPOINTGROUP" "┗━${AllEndpointGroups[${i}]##*:::}"
								fi
							else
								PrintHelper "BOXITEMA" "EPT$(printf "%04d" "$((i+1))")" "NORMAL:::ENDPOINTGROUP" "${AllEndpointGroups[${i}]##*:::}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"SERVICES"|"DERIVE-SERVICE")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail:-services}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>UUID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllServices < <( \
					jq -r '
						select(._embedded.services != null)
						| ._embedded.services
						| group_by(.endpointId,.serviceClass)[]
							| sort_by(.name)
						| .[]
						| .serviceClass + ":::" + .name + "=>" + .endpointId + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}" \
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllServices[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "SRV...." "WARNING:::WARNING" "No Services found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent calls.
					for ((i=0;i<${#AllServices[*]};i++)); do

						if [[ $((i%10)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
							! GetYorN "Shown ${i}/${#AllServices[*]} - Show more?" "Yes" "5" \
								&& ClearLines "1" \
								&& break
						fi

						Target_SERVICE[0]="${AllServices[${i}]%%=>*}" # TYPE:::NAME
						Target_SERVICE[1]="${AllServices[${i}]#*=>}" # GWUUID=>SERVICEUUID
						Target_SERVICE[2]="${AllServices[${i}]##*:::}" # NAME=>GWUUID=>SERVICEUUID
						Target_SERVICE[3]="${Target_SERVICE[0]#*:::}" # NAME
						Target_SERVICE[4]="${Target_SERVICE[1]%%=>*}" # GWUUID
						Target_SERVICE[5]="${Target_SERVICE[1]##*=>}" # SERVICEUUID

						PrintHelper "BOXITEMA" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::${Target_SERVICE[0]%:::*}_SERVICE" "${Target_SERVICE[3]}=>${Target_SERVICE[5]}"

						case ${ListMode} in
							"FOLLOW-ENDPOINTS")
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "ENDPOINTS" "endpoints/${Target_SERVICE[4]}" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "EPT...." "ERROR:::ERROR" "No direct Endpoint associations were found." \
									&& AskDelete="2"
							;;

							"FOLLOW-APPWANS")
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "APPWANS" "services/${Target_SERVICE[5]}/appWans" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "APW...." "WARNING:::WARNING" "No direct AppWAN associations were found." \
									&& AskDelete="2"
							;;

							"FOLLOW-ALL")
								trap '' SIGINT SIGTERM # Ignore CTRL+C events.
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "ENDPOINTS" "endpoints/${Target_SERVICE[4]}" 2>/dev/null \
									&& (( AskDelete++ ))
								! GetObjects_MOP "APPWANS" "services/${Target_SERVICE[5]}/appWans" 2>/dev/null \
									&& (( AskDelete++ ))
								trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.
						esac

						[[ ${AskDelete:-0} -eq 2 ]] \
							&& PrintHelper "BOXITEMASUB" "SRV...." "ERROR:::ERROR" "No direct Endpoint or AppWAN associations were found." \
							&& (GetYorN "Do you wish to remove \"${Target_SERVICE[0]##*:::}\"?" "No" "10" \
								&& SetObjects_MOP_V6 "DELSERVICE" "${Target_SERVICE[1]}") \
							&& ClearLines "2"

						[[ $((i+1)) -eq ${#AllServices[*]} ]] \
							|| PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					if [[ ${ListType} == "DERIVE-SERVICE" ]]; then

						DeriveDetail "${AllServices[*]}" "services"

					else

						for ((i=0;i<${#AllServices[*]};i++)); do

							Target_SERVICE[0]="${AllServices[${i}]%%=>*}" # TYPE:::NAME
							Target_SERVICE[1]="${AllServices[${i}]#*=>}" # GWUUID=>SERVICEUUID
							Target_SERVICE[2]="${AllServices[${i}]##*:::}" # NAME=>GWUUID=>SERVICEUUID
							Target_SERVICE[3]="${Target_SERVICE[0]#*:::}" # NAME
							Target_SERVICE[4]="${Target_SERVICE[1]%%=>*}" # GWUUID
							Target_SERVICE[5]="${Target_SERVICE[1]##*=>}" # SERVICEUUID

							# URLTrail specification indicates this is a secondary GetObjects_MOP call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllServices[*]} ]]; then
									PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::${Target_SERVICE[0]%:::*}_SERVICE" "┣━${Target_SERVICE[3]}=>${Target_SERVICE[5]}"
								else
									PrintHelper "BOXITEMASUB" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::${Target_SERVICE[0]%:::*}_SERVICE" "┗━${Target_SERVICE[3]}=>${Target_SERVICE[5]}"
								fi
							else
								PrintHelper "BOXITEMA" "SRV$(printf "%04d" "$((i+1))")" "NORMAL:::${Target_SERVICE[0]%:::*}_SERVICE" "${Target_SERVICE[3]}=>${Target_SERVICE[5]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

		"APPWANS"|"DERIVE-APPWAN")
			if ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail:-appWans}" "200"; then

				PrintHelper "BOXHEADLINEA" "ITEM #" "NORMAL:::TYPE/CLASS/INDICATOR" "DESCRIPTION=>UUID" >&2

				# Gather all objects which match one of the following in order of check A) FilterString=OnlyIfFollowed B) PrimaryFilterString=OnlyFirstList
				read -d '' -ra AllAppWANs < <( \
					jq -r '
						select(._embedded.appWans != null)
						| ._embedded.appWans
						| sort_by(.name)
						| .[]
						| .name + "=>" + (._links.self.href | split("/"))[-1]
					' <<< "${OutputJSON}" \
					| grep -Ei "${FilterString:-${PrimaryFilterString:-.}}" \
				)

				# No reason to continue if there are no objects to analyze.
				if [[ ${#AllAppWANs[*]} -eq 0 ]]; then

					PrintHelper "BOXITEMA" "APW...." "WARNING:::WARNING" "No AppWANs found." >&2
					PrintHelper "BOXFOOTLINEA" >&2
					return 1

				elif [[ ${ListMode} =~ "FOLLOW" ]]; then

					FilterString='.' # Set the filter to grab everything in subsequent calls.
					local iA # Local only variable for counting matching AppWANs in FOLLOW-ASERVICES.
					iA=0
					for ((i=0;i<${#AllAppWANs[*]};i++)); do

						Target_APPWAN[0]=${AllAppWANs[${i}]%%=>*}
						Target_APPWAN[1]=${AllAppWANs[${i}]##*=>}

						if [[ ${ListMode} == "FOLLOW-ASERVICES" ]]; then

							# If the Endpoint was found directly associated with the AppWAN, print AppWAN Services and move to the next AppWAN.
							AttentionMessage "GREENINFO" "Searching AppWAN $((i+1))/${#AllAppWANs[*]} \"${Target_APPWAN[0]}\" for Direct Associations."
							GetObjects_MOP "ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpoints" &>/dev/null
							ClearLines "1"
							if [[ "${AllEndpoints[*]}" =~ ${ExplicitUUID} ]]; then
								PrintHelper "BOXITEMASUB" "APW$(printf "%04d" "$((iA+1))")" "NORMAL:::APPWAN" "┏${AllAppWANs[${i}]}"
								GetObjects_MOP "SERVICES" "appWans/${Target_APPWAN[1]}/services"
								(( iA++ ))
								continue
							fi

							# If the EndpointGroup, and subsequent Endpoints within, was found associated with the AppWAN, print AppWAN Services and move to the next AppWAN.
							AttentionMessage "GREENINFO" "Searching AppWAN $((i+1))/${#AllAppWANs[*]} \"${Target_APPWAN[0]}\" for Group Associations."
							GetObjects_MOP "ENDPOINTGROUPS-ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpointGroups" &>/dev/null
							ClearLines "1"

							if [[ "${AllEndpoints[*]}" =~ ${ExplicitUUID} ]]; then

								local iGa iGb # Local only variable for counting matching AppWANs in FOLLOW-ASERVICES.
								iGa=0 iGb=0
								PrintHelper "BOXITEMASUB" "APW$(printf "%04d" "$((iA+1))")" "NORMAL:::APPWAN" "┏${AllAppWANs[${i}]}"
								for ((iGa=0;iGa<${#AllEndpointGroups[*]};iGa++)); do

									Target_EndpointGroup[0]=${AllEndpointGroups[${iGa}]%%=>*}
									Target_EndpointGroup[1]=${AllEndpointGroups[${iGa}]##*=>}

									# For each EndpointGroup, search for a specific Endpoint.
									AttentionMessage "GREENINFO" "Searching EndpointGroup $((iG+1))/${#AllEndpointGroups[*]} \"${Target_EndpointGroup[0]}\" for Group Associations."
									if GetObjects_MOP "ENDPOINTS" "endpointGroups/${Target_EndpointGroup[1]}/endpoints" &>/dev/null; then
										ClearLines "1"
										[[ "${AllEndpoints[*]}" =~ ${ExplicitUUID} ]] \
											&& PrintHelper "BOXITEMASUB" "EPG$(printf "%04d" "$((iGb+1))")" "NORMAL:::ENDPOINTGROUP" "┣${AllEndpointGroups[${iGa}]}" \
											&& (( iGb++ ))
									else
										ClearLines "1"
									fi

								done

								GetObjects_MOP "SERVICES" "appWans/${Target_APPWAN[1]}/services"
								(( iA++ ))
								continue

							fi

							# End of the line, no matching of any Endpoints for this AppWAN.
							if [[ $((i+1)) -lt ${#AllAppWANs[*]} ]]; then
								continue
							else
								break
							fi

						fi

						if [[ $((i%10)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
							! GetYorN "Shown ${i}/${#AllAppWANs[*]} - Show more?" "Yes" "5" \
								&& ClearLines "1" \
								&& break
						fi

						PrintHelper "BOXITEMA" "APW$(printf "%04d" "$((i+1))")" "NORMAL:::APPWAN" "${AllAppWANs[${i}]}"

						case ${ListMode} in
							"FOLLOW-SERVICES")
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "SERVICES" "appWans/${Target_APPWAN[1]}/services" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "SRV...." "NORMAL:::" "No Service associations were found." \
									&& AskDelete="2"
								;;

						"FOLLOW-ENDPOINTGROUPS_ENDPOINTS")
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpoints" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "EPT...." "NORMAL:::" "No direct Endpoint associations were found." \
									&& (( AskDelete++ ))
								! GetObjects_MOP "ENDPOINTGROUPS-ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpointGroups" 2>/dev/null \
									&& PrintHelper "BOXITEMASUB" "EPG...." "NORMAL:::" "No EndpointGroup associations were found." \
									&& (( AskDelete++ ))
								[[ ${AskDelete:-0} -eq 2 ]] \
									&& AskDelete="3"
							;;

						"FOLLOW-ALL")
								trap '' SIGINT SIGTERM # Ignore CTRL+C events.
								AskDelete="0"
								PrintHelper "BOXITEMASUBLINEA"
								! GetObjects_MOP "SERVICES" "appWans/${Target_APPWAN[1]}/services"  2>/dev/null \
									&& (( AskDelete++ ))
								! GetObjects_MOP "ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpoints" 2>/dev/null \
									&& (( AskDelete++ ))
								! GetObjects_MOP "ENDPOINTGROUPS-ENDPOINTS" "appWans/${Target_APPWAN[1]}/endpointGroups" 2>/dev/null \
									&& (( AskDelete++ ))
								trap 'GoToExit 2' SIGINT SIGTERM # Reset CTRL+C events.
							;;
						esac

						if [[ ${AskDelete:-0} -eq 3 ]]; then
							PrintHelper "BOXITEMASUB" "EPT...." "WARNING:::WARNING" "No direct Endpoint, EndpointGroup, or Service associations were found."
							GetYorN "Do you wish to remove \"${Target_APPWAN[0]##*:::}\"?" "No" "10" \
								&& SetObjects_MOP_V6 "DELAPPWAN" "${Target_APPWAN[1]}"
							ClearLines "2"
						fi

						[[ $((i+1)) -eq ${#AllAppWANs[*]} ]] \
							|| PrintHelper "BOXMIDLINEA" >&2

					done

					PrintHelper "BOXFOOTLINEB" >&2

				else

					if [[ ${ListType} == "DERIVE-APPWAN" ]]; then

						DeriveDetail "${AllAppWANs[*]}" "appWans"

					else

						for ((i=0;i<${#AllAppWANs[*]};i++)); do

							# URLTrail specification indicates this is a secondary GetObjects_MOP call which links to a parent/header.
							if [[ ${URLTrail} ]]; then
								if [[ $((i+1)) -ne ${#AllAppWANs[*]} ]]; then
									PrintHelper "BOXITEMASUB" "APW$(printf "%04d" "$((i+1))")" "NORMAL:::APPWAN" "┣━${AllAppWANs[${i}]}"
								else
									PrintHelper "BOXITEMASUB" "APW$(printf "%04d" "$((i+1))")" "NORMAL:::APPWAN" "┗━${AllAppWANs[${i}]}"
								fi
							else
								PrintHelper "BOXITEMA" "APW$(printf "%04d" "$((i+1))")" "NORMAL:::APPWAN" "${AllAppWANs[${i}]}"
							fi

						done

					fi

					PrintHelper "BOXFOOTLINEA" >&2

				fi

				return 0

			fi

			return 1
		;;

	esac

	return 0
}

#################################################################################
# Search S3 shards using the API.
function SearchShards() {
	# 1/TYPE 2-10/[DATAFIELDS]
	local i DATASyntax
	local SearchType="${1}"
	unset SearchShardsReturn # Ensure this is not already set.

	case ${SearchType} in

		"GETLASTACTIVITY")
			# 2/BEGINEPOCHMILLI 3/ENDEPOCHMILLI
			DATASyntax="--data '{\"aggs\":{\"EndpointName\":{\"terms\":{\"field\":\"commonName.keyword\",\"size\":10000,\"order\":{\"lastTimeOnline\":\"desc\"}},\"aggs\":{\"lastTimeOnline\":{\"max\":{\"field\":\"@timestamp\"}}}}},\"query\":{\"bool\":{\"must\":[{\"match_all\":{}},{\"match_phrase\":{\"networkId\":{\"query\":\"${Target_NETWORK[0]}\"}}},{\"range\":{\"@timestamp\":{\"gte\":\"${2}\",\"lte\":\"${3}\",\"format\":\"epoch_millis\"}}},{\"match_phrase\":{\"organizationId\":{\"query\":\"${Target_ORGANIZATION[0]}\"}}}],\"must_not\":[{\"match_phrase\":{\"nodeType.keyword\":{\"query\":\"TransferNode\"}}}]}},\"size\":0}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/elastic/ncvtchistorical/${Target_ORGANIZATION[0]}/_search/" "200"; then
				read -d '' -ra SearchShardsReturn < <( \
					jq -r '
						if type=="array" then
							(.[] | "NOTREADY: " + .message)
						elif .hits.total==0 then
							"NO SHARDS"
						else
							select(.aggregations != null)
								| .aggregations.EndpointName.buckets[]
								| .key + "=>" + .lastTimeOnline.value_as_string
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				return 1
			fi
		;;

		"GETSPECIFICSTATUS")
			# 2/BEGINEPOCHMILLI 3/RESOURCEID 4/ENDPOINTUUID
			DATASyntax="--data '{\"query\":{\"bool\":{\"must\":[{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},{\"match_phrase\":{\"tags.keyword\":{\"query\":\"customer\"}}},{\"range\":{\"@timestamp\":{\"gte\":${2},\"lte\":${3},\"format\":\"epoch_millis\"}}},{\"match_phrase\":{\"organizationId\":{\"query\":\"${Target_ORGANIZATION[0]}\"}}},{\"match_phrase\":{\"networkId\":{\"query\":\"${Target_NETWORK[0]}\"}}},{\"match_phrase\":{\"resourceId\":{\"query\":\"${4}\"}}}],\"must_not\":[{\"match_phrase\":{\"changeType\":{\"query\":\"soft\"}}}]}},\"size\":10000,\"sort\":[{\"@timestamp\":{\"order\":\"desc\",\"unmapped_type\":\"boolean\"}}],\"_source\":{\"excludes\":[]}}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/elastic/ncentityevent/${Target_ORGANIZATION[0]}/_search/" "200"; then
				read -d '' -ra SearchShardsReturn < <( \
					jq -r '
						if type=="array" then
							(.[] | "NOTREADY: " + .message)
						elif .hits.total==0 then
							"NO SHARDS"
						else
							select(.hits != null)
								| .hits.hits[]._source
								| ."@timestamp"
									+ "=>" + .eventDescription
									+ "=>" + (.ip // "UNKNOWN") + ":" + (.port // "UNKNOWN")
									+ "=>" + (.geo.city_name // "UNKNOWN") + "/" + (.geo.country_name // "UNKNOWN")
									+ "=>" + ((.geo.latitude // "0")|tostring) + "," + ((.geo.longitude // "0")|tostring)
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				return 1
			fi
		;;

		"GETSPECIFICUSAGE")
			# 2/BEGINDATE 3/ENDDATE 4/INCREMENT 5/ENDPOINTUUID
			DATASyntax="--data '{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"match_all\":{}},{\"range\":{\"@timestamp\":{\"gte\":\"${2}\",\"lte\":\"${3}\"}}},{\"match_phrase\":{\"networkId\":{\"query\":\"${Target_NETWORK[0]}\"}}},{\"match_phrase\":{\"organizationId\":{\"query\":\"${Target_ORGANIZATION[0]}\"}}},{\"match_phrase\":{\"resourceId\":{\"query\":\"${5}\"}}},{\"bool\":{\"should\":[{\"match_phrase\":{\"NetworkDataType\":\"DropTcpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropTcpRx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpRx\"}}],\"minimum_should_match\":1}}]}},\"aggs\":{\"Increments\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"${4}\",\"extended_bounds\":{\"min\":\"${2}\",\"max\":\"${3}\"},\"time_zone\":\"UTC\",\"min_doc_count\":0},\"aggs\":{\"EndpointName\":{\"terms\":{\"field\":\"resourceId.keyword\",\"order\":{\"TotalBytes\":\"desc\"}},\"aggs\":{\"TotalBytes\":{\"sum\":{\"field\":\"bytes\"}},\"ProtoBreakdown\":{\"filters\":{\"filters\":{\"DropTcpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpTx)\"}},\"DropTcpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpRx)\"}},\"DropUdpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpTx)\"}},\"DropUdpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpRx)\"}}}},\"aggs\":{\"Bytes\":{\"sum\":{\"field\":\"bytes\"}}}}}}}}}}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/elastic/ncvtchistorical/${Target_ORGANIZATION[0]}/_search/" "200"; then
				read -d '' -ra SearchShardsReturn < <( \
					jq -r '
						if type=="array" then
							(.[] | "NOTREADY: " + .message)
						elif .hits.total==0 then
							"NO SHARDS"
						else
							[
								select(.aggregations != null)
									| .aggregations.Increments.buckets[]
									| .key_as_string as $DATETIME
									| (
										.EndpointName.buckets[]
										| ((.TotalBytes.value // 0)|tostring) as $TOTALBYTES
										| .ProtoBreakdown.buckets
										| ((.DropTcpRx.Bytes.value // 0)|tostring) as $TCPRXBYTES
										| ((.DropTcpTx.Bytes.value // 0)|tostring) as $TCPTXBYTES
										| ((.DropUdpRx.Bytes.value // 0)|tostring) as $UDPRXBYTES
										| ((.DropUdpTx.Bytes.value // 0)|tostring) as $UDPTXBYTES
										| ((.DropTcpRx.Bytes.value + .DropUdpRx.Bytes.value // 0)|tostring) as $BILLRXBYTES
										| $DATETIME + "=>" + $TOTALBYTES + "," + $BILLRXBYTES + "," + $TCPRXBYTES + "," + $TCPTXBYTES + "," + $UDPRXBYTES + "," + $UDPTXBYTES
									) // $DATETIME + "=>0,0,0,0,0,0"
							] | reverse[]
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				return 1
			fi
		;;

		"GETNETWORKDRILLUSAGE")
			# 2/BEGINDATE 3/ENDDATE 4/INCREMENT
			DATASyntax="--data '{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"match_all\":{}},{\"range\":{\"@timestamp\":{\"gte\":\"${2}\",\"lte\":\"${3}\"}}},{\"match_phrase\":{\"networkId\":{\"query\":\"${Target_NETWORK[0]}\"}}},{\"match_phrase\":{\"organizationId\":{\"query\":\"${Target_ORGANIZATION[0]}\"}}},{\"bool\":{\"should\":[{\"match_phrase\":{\"NetworkDataType\":\"DropTcpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropTcpRx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpRx\"}}],\"minimum_should_match\":1}}]}},\"aggs\":{\"Months\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"${4}\",\"time_zone\":\"UTC\",\"min_doc_count\":0},\"aggs\":{\"CommonName\":{\"terms\":{\"field\":\"commonName.keyword\",\"size\":10000,\"order\":{\"TotalBytes\":\"desc\"}},\"aggs\":{\"TotalBytes\":{\"sum\":{\"field\":\"bytes\"}},\"ProtoBreakdown\":{\"filters\":{\"filters\":{\"DropTcpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpTx)\"}},\"DropTcpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpRx)\"}},\"DropUdpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpTx)\"}},\"DropUdpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpRx)\"}}}},\"aggs\":{\"Bytes\":{\"sum\":{\"field\":\"bytes\"}}}}}}}}}}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/elastic/ncvtchistorical/${Target_ORGANIZATION[0]}/_search/" "200"; then
				read -d '' -ra SearchShardsReturn < <( \
					jq -r '
						if type=="array" then
						(.[] | "NOTREADY: " + .message)
						elif .hits.total==0 then
						"NO SHARDS"
						else
						[
							select(.aggregations != null)
							| .aggregations.Months.buckets[]
							| .key_as_string as $DATETIME
							| (
								.CommonName.buckets[]
								| ((.TotalBytes.value // 0)|tostring) as $TOTALBYTES
								| .key as $ENDPOINTNAME
								| .ProtoBreakdown.buckets
								| ((.DropTcpRx.Bytes.value // 0)|tostring) as $TCPRXBYTES
								| ((.DropTcpTx.Bytes.value // 0)|tostring) as $TCPTXBYTES
								| ((.DropUdpRx.Bytes.value // 0)|tostring) as $UDPRXBYTES
								| ((.DropUdpTx.Bytes.value // 0)|tostring) as $UDPTXBYTES
								| ((.DropTcpRx.Bytes.value + .DropUdpRx.Bytes.value // 0)|tostring) as $BILLRXBYTES
								| $ENDPOINTNAME + "=>" + $TOTALBYTES + "," + $BILLRXBYTES + "," + $TCPRXBYTES + "," + $TCPTXBYTES + "," + $UDPRXBYTES + "," + $UDPTXBYTES
							) // $DATETIME + "=>0,0,0,0,0,0"
						] | reverse[]
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				return 1
			fi
		;;

		"GETNETWORKUSAGE")
			# 2/BEGINDATE 3/ENDDATE 4/INCREMENT
			DATASyntax="--data '{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"match_all\":{}},{\"range\":{\"@timestamp\":{\"gte\":\"${2}\",\"lte\":\"${3}\"}}},{\"match_phrase\":{\"networkId\":{\"query\":\"${Target_NETWORK[0]}\"}}},{\"match_phrase\":{\"organizationId\":{\"query\":\"${Target_ORGANIZATION[0]}\"}}},{\"bool\":{\"should\":[{\"match_phrase\":{\"NetworkDataType\":\"DropTcpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropTcpRx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpTx\"}},{\"match_phrase\":{\"NetworkDataType\":\"DropUdpRx\"}}],\"minimum_should_match\":1}}]}},\"aggs\":{\"Months\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"${4}\",\"extended_bounds\":{\"min\":\"${2}\",\"max\":\"${3}\"},\"time_zone\":\"UTC\",\"min_doc_count\":0},\"aggs\":{\"TotalBytes\":{\"sum\":{\"field\":\"bytes\"}},\"ProtoBreakdown\":{\"filters\":{\"filters\":{\"DropTcpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpTx)\"}},\"DropTcpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropTcpRx)\"}},\"DropUdpTx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpTx)\"}},\"DropUdpRx\":{\"query_string\":{\"query\":\"NetworkDataType:(DropUdpRx)\"}}}},\"aggs\":{\"Bytes\":{\"sum\":{\"field\":\"bytes\"}}}}}}}}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/elastic/ncvtchistorical/${Target_ORGANIZATION[0]}/_search/" "200"; then
				read -d '' -ra SearchShardsReturn < <( \
					jq -r '
						if type=="array" then
						(.[] | "NOTREADY: " + .message)
						elif .hits.total==0 then
						"NO SHARDS"
						else
						[
							select(.aggregations != null)
							| .aggregations.Months.buckets[]
							| .key_as_string as $DATETIME
							| ((.TotalBytes.value // 0)|tostring) as $TOTALBYTES
							| (
								.ProtoBreakdown.buckets
								| ((.DropTcpRx.Bytes.value // 0)|tostring) as $TCPRXBYTES
								| ((.DropTcpTx.Bytes.value // 0)|tostring) as $TCPTXBYTES
								| ((.DropUdpRx.Bytes.value // 0)|tostring) as $UDPRXBYTES
								| ((.DropUdpTx.Bytes.value // 0)|tostring) as $UDPTXBYTES
								| ((.DropTcpRx.Bytes.value + .DropUdpRx.Bytes.value // 0)|tostring) as $BILLRXBYTES
								| $DATETIME + "=>" + $TOTALBYTES + "," + $BILLRXBYTES + "," + $TCPRXBYTES + "," + $TCPTXBYTES + "," + $UDPRXBYTES + "," + $UDPTXBYTES
							) // $DATETIME + "=>0,0,0,0,0,0"
						] | reverse[]
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				return 1
			fi
		;;

	esac
}

#################################################################################
# An usage report is a list of per month cloud usage against a specific object.
function RunUsageReport() {
	function CheckSemaphore() {
		# 1/TRIGGER[BEGIN/MID/END] 2/INCREMENT[OPTIONAL]
		local PrintTrigger="${1}"
		local PrintIncrement="${2}"
		if [[ ${PrintTrigger} == "BEGIN" ]]; then
			if [[ ${PrintIncrement} == "hour" ]]; then
				PrintIncrement="YYYY-MM-DD:HH [UTC]"
			elif [[ ${PrintIncrement} == "day" ]]; then
				PrintIncrement="YYYY-MM-DD [UTC]"
			elif [[ ${PrintIncrement} == "month" ]]; then
				PrintIncrement="YYYY-MM [UTC]"
			elif [[ ${PrintIncrement} == "name" ]]; then
				PrintIncrement="Endpoint Name"
				PrintHelper "BOXHEADLINEB" "MERGE" "NORMAL:::${PrintIncrement}" "NORMAL:::Total MB,${Normal}:::Billable MB,${Normal}:::RX TCP MB,${Normal}:::TX TCP MB,${Normal}:::RX UDP MB,${Normal}:::TX UDP MB"
				return 0
			fi
			PrintHelper "BOXHEADLINEB" " INC #" "NORMAL:::${PrintIncrement}" "NORMAL:::Total MB,${Normal}:::Billable MB,${Normal}:::RX TCP MB,${Normal}:::TX TCP MB,${Normal}:::RX UDP MB,${Normal}:::TX UDP MB"
			SemaphoreState="FALSE"
		elif [[ ${PrintTrigger} == "MIDA" ]] && [[ ${SemaphoreState} == "FALSE" ]]; then
			PrintHelper "BOXITEMASUBLINEA"
			SemaphoreState="TRUE"
		elif [[ ${PrintTrigger} == "MIDB" ]] && [[ ${SemaphoreState} == "TRUE" ]]; then
			PrintHelper "BOXITEMASUBLINEB"
			SemaphoreState="FALSE"
		elif [[ ${PrintTrigger} == "END" ]]; then
			[[ ${SemaphoreState} == "TRUE" ]] \
				&& PrintHelper "BOXFOOTLINEB" \
				|| PrintHelper "BOXFOOTLINEA"
			SemaphoreState="FALSE"
		fi
	}

	function CalculateMetrics() {
		# 1/TYPE 2/INPUTVALUES
		local InputType="${1}"
		local InputValues="${2:-0}"
		local AvgCalc="0"
		local TrendCalc="0"
		local i InvertColor

		case ${InputType} in

			"B2MB")
				# InputValues = 0/Bytes
				InputValues[0]=$((InputValues[0]/10000)) # Reveal MB form in whole number format (x100) for SHELL interpretation. EX: 1000000 = 1MB (100 in-format)
				# Use SHELL to ascertain the E value.
				case ${#InputValues[0]} in
					0) echo "0.00";; # n^0 = 0
					1) echo "0.0${InputValues[0]}";; # n^1 = 1s (0.01xMBs)
					2) echo "0.${InputValues[0]}";; # n^2 = 10s (0.10xMBs)
					3) echo "${InputValues[0]:0:1}.${InputValues[0]:1:2}";; # n^3 = 100s (1.00xMBs)
					*) echo "${InputValues[0]:0:$((${#InputValues[0]}-2))}.${InputValues[0]:$((${#InputValues[0]}-2)):${#InputValues[0]}}";; # 1000s+ (10.00xMBs+)
				esac
			;;

			"TREND")
				# Parse out the values of the variable into an array.
				InputValues=( ${InputValues// /${NewLine}} )
				# InputValues in BYTES = 0/N3 1/N2 2/N1 3/C
				for ((i=0;i<${#InputValues[*]};i++)); do
					InputValues[${i}]="${InputValues[${i}]/\./}" # Value formated to whole number (x100) for SHELL interpretation.
					InputValues[${i}]="$((10#${InputValues[${i}]}))" # Further conditioning to remove leading zeros for SHELL interpretation.
				done
				# A special case where the user wants to flag certain values or higher.
				if [[ ${FlagValue:-NONE} != "NONE" ]] && [[ ${InputValues[3]} -gt ${FlagValue} ]]; then
					InvertColor="${Invert};${BBlack};"
				fi
				# The average for all values added thus far. ((N3)+(N2)+(N1))/3 =Average/A
				AvgCalc=$((((InputValues[0]+InputValues[1]+InputValues[2])*100))) # EX: (5+7+3)*100 =1500
				if [[ ${AvgCalc} -eq 0 ]]; then
					AvgCalc="1" # Average was all zeros, thus any C value will be a gain.
				else
					AvgCalc=$((AvgCalc/3)) # EX: 1500/3 =500 [5.00]
				fi
				# What percent greater/lesser is C compared to A determines the arrow type. (C/A) =Gain/Loss/Trend
				TrendCalc=$(((InputValues[3]*10000)/AvgCalc)) # EX: (8*10000/500) =160 [1.60 or 60% Gain]
				if [[ ${TrendCalc} -eq 0 ]]; then
					echo "${InvertColor}${Dimmed}:::PLACEHOLDER~" # Absolute zero is devoid of gain or loss.
				elif [[ ${TrendCalc} -gt 0 ]] && [[ ${TrendCalc} -le 1 ]]; then
					echo "${InvertColor}${FBlue}:::PLACEHOLDER${IconStash[15]}" # 0% to 1% is extreme loss.
				elif [[ ${TrendCalc} -gt 1 ]] && [[ ${TrendCalc} -le 3 ]]; then
					echo "${InvertColor}${FMagenta}:::PLACEHOLDER${IconStash[15]}" # 0% to 3% is very high loss.
				elif [[ ${TrendCalc} -ge 4 ]] && [[ ${TrendCalc} -le 25 ]]; then
					echo "${InvertColor}${FRed}:::PLACEHOLDER${IconStash[15]}" # 4% to 25% is high loss.
				elif [[ ${TrendCalc} -ge 26 ]] && [[ ${TrendCalc} -le 98 ]]; then
					echo "${InvertColor}${FYellow}:::PLACEHOLDER${IconStash[15]}" # 26% to 98% is moderate loss.
				elif [[ ${TrendCalc} -ge 99 ]] && [[ ${TrendCalc} -le 101 ]]; then
					echo "${InvertColor}${FGreen}:::PLACEHOLDER${IconStash[13]}" # 98% to 101% is no measurable gain or loss.
				elif [[ ${TrendCalc} -ge 102 ]] && [[ ${TrendCalc} -le 175 ]]; then
					echo "${InvertColor}${FYellow}:::PLACEHOLDER${IconStash[14]}" # 102% to 175% is moderate gain.
				elif [[ ${TrendCalc} -ge 176 ]] && [[ ${TrendCalc} -le 250 ]]; then
					echo "${InvertColor}${FRed}:::PLACEHOLDER${IconStash[14]}" # 176% to 250% is high gain.
				elif [[ ${TrendCalc} -ge 176 ]] && [[ ${TrendCalc} -le 300 ]]; then
					echo "${InvertColor}${FMagenta}:::PLACEHOLDER${IconStash[14]}" # 176% to 300% or greater is very high gain.
				elif [[ ${TrendCalc} -ge 301 ]]; then
					echo "${InvertColor}${FBlue}:::PLACEHOLDER${IconStash[14]}" # 300% or greater is extreme gain.
				fi
			;;

			"FINALREPORT")
				PrintHelper "BOXITEMASUBLINEC"
				# Parse out the values of the variable into an array.
				InputValues=( ${InputValues// /${NewLine}} )
				# InputValues in MEGABYTES = 0/N3 1/N2 2/N1 ... X/nX
				for ((i=0;i<${#InputValues[*]};i++)); do
					InputValues[${i}]=$(CalculateMetrics "B2MB" "${InputValues[${i}]}") # Bytes in MegaByte (MB).
				done
				PrintHelper "BOXITEMB" "MERGE" "NORMAL:::TOTALS" "${FGreen}:::${InputValues[0]} ,${FGreen}:::${InputValues[1]} ,${FGreen}:::${InputValues[2]} ,${FGreen}:::${InputValues[3]} ,${FGreen}:::${InputValues[4]} ,${FGreen}:::${InputValues[5]} "
			;;

		esac
	}

	# 1/TARGETUUID
	local i OutputResponse OutputHeaders OutputJSON EventTiming DrillInc DrillTiming SaveShards ReportDuration ReportIncrement DateFormat EachReportLine FlagValue
	local TotalMB BillMB TCPRXMB TCPTXMB UDPRXMB UDPTXMB
	local TrendTotalMB TrendBillMB TrendTCPRXMB TrendTCPTXMB TrendUDPRXMB TrendUDPTXMB TrendStore FinalTotals
	local Target_ENDPOINT[0]="${1}"
	SemaphoreState="FALSE"

	# Determine the type of report to perform.
	if [[ ${Target_ENDPOINT[0]} != "WHOLENETWORK" ]]; then
		# Input text "TYPE:::NAME:::UUID".
		Target_ENDPOINT[1]="${Target_ENDPOINT[0]%%=>*}" # TYPE:::NAME
		Target_ENDPOINT[2]="${Target_ENDPOINT[0]##*=>}" # UUID
		Target_ENDPOINT[3]="GETSPECIFICUSAGE" # Set to type.
	else
		Target_ENDPOINT[1]="NETWORK:::${Target_NETWORK[1]}" # NULL.
		Target_ENDPOINT[2]="${Target_NETWORK[0]}" # UUID (of Network).
		Target_ENDPOINT[3]="GETNETWORKUSAGE" # Set to type.
	fi

	while true; do

		# The user needs to select how many months in arears to span the search.
		ReportDuration=( "1 Month Back" "2 Months Back" "3 Months Back" "4 Months Back" "5 Months Back" "6 Months Back" "7 Months Back" "8 Months Back" "9 Months Back" "10 Months Back" "11 Months Back" "12 Months Back" "24 Months Back" "36 Months Back" "48 Months Back" )
 		! GetSelection "How many months in arears from the beginning of the current month should the report on \"${Target_ENDPOINT[1]}\" contain?" "${ReportDuration[*]}" \
			&& return 1
		EventTiming[0]="${UserResponse//\ */}" # The months requested factor.

		# The user needs to select how to increment the report.
		[[ ${EventTiming[0]} -le 2 ]] \
			&& ReportIncrement=( "Hourly" "Daily" "Monthly" ) \
			|| ReportIncrement=( "Daily" "Monthly" ) # Greater than 2 months will generate too many results for hour Increments.
		! GetSelection "How should the report on \"${Target_ENDPOINT[1]}\" be incremented?" "${ReportIncrement[*]}" \
			&& continue
		case ${UserResponse} in
			"Hourly")
				EventTiming[1]="hour"
				DateFormat="13"
			;;
			"Daily")
				EventTiming[1]="day"
				DateFormat="10"
			;;
			"Monthly")
				EventTiming[1]="month"
				DateFormat="7"
			;;
		esac # The incrementing factor.

		# Does the user want to flag values higher than a specific amount?
		if GetYorN "Do you wish to flag values higher than a specific amount (in whole MegaBytes)?" "No" ; then
			while true; do
				! GetResponse "Enter a valid number (in whole MegaBytes) to flag in the report output." \
					&& break
				if [[ ${UserResponse} =~ ${ValidNumber} ]]; then
					FlagValue="$((UserResponse*100))" # Times 100 for SHELL purposes.
					break
				else
					AttentionMessage "ERROR" "The value you entered \"${UserResponse}\" is not valid. Try again."
				fi
			done
		fi

		AttentionMessage "GENERALINFO" "Historical information trails current time by approximately two hours. [NOW=$(date -u)]"
		AttentionMessage "GENERALINFO" "Searching and generating (${EventTiming[0]} Month(s) + Current Month, per ${EventTiming[1]}) Endpoint Usage report for \"${Target_ENDPOINT[1]}\"."
		# The return code was TRUE/0.
		if SearchShards "${Target_ENDPOINT[3]}" "now-${EventTiming[0]}M" "now" "${EventTiming[1]}" "${Target_ENDPOINT[2]}"; then

			if [[ ${SearchShardsReturn[0]} != "NO SHARDS" ]] && [[ ${#SearchShardsReturn[*]} -le 9999 ]]; then

				for ((i=${#SearchShardsReturn[*]};i>=0;i--)); do

					# Begin the printing.
					if [[ ${i} -eq ${#SearchShardsReturn[*]} ]]; then
						# This is the most current state - the top of the report.
						CheckSemaphore "BEGIN" "${EventTiming[1]}"
						continue
					fi

					if [[ $(((${#SearchShardsReturn[*]}-i-1)%100)) -eq 0 ]] && [[ $((${#SearchShardsReturn[*]}-i-1)) -ne 0 ]]; then
						! GetYorN "Shown $((${#SearchShardsReturn[*]}-i-1))/${#SearchShardsReturn[*]} - Show more?" "Yes" "5" \
							&& ClearLines "1" \
							&& break
					fi

					# 0/UTCDATE 1/TOTALBYTES 2/BILLBYTES 3/TCPRXBYTES 4/TCPTXBYTES 5/UDPRXBYTES 6/UDPTXBYTES
					IFS=','; EachReportLine=( ${SearchShardsReturn[${i}]//=>/,} ); IFS=$'\n'

					# Calculations.
					EachReportLine[0]="${EachReportLine[0]:0:${DateFormat}}" # Date in one of YYYY-MM-DDTHH/YYYY-MM-DD/YYYY-MM format.
					TotalMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[1]}") # Bytes in MegaByte (MB) for Total.
					BillMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[2]}") # Bytes in MegaByte (MB) for Billable.
					TCPRXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[3]}") # Bytes in MegaByte (MB) for RX TCP.
					TCPTXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[4]}") # Bytes in MegaByte (MB) for TX TCP.
					UDPRXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[5]}") # Bytes in MegaByte (MB) for RX UDP.
					UDPTXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[6]}") # Bytes in MegaByte (MB) for TX UDP.

					# Tracking for final totals.
					(( FinalTotals[0]+=EachReportLine[1] )) # Bytes cumulative for Total.
					(( FinalTotals[1]+=EachReportLine[2] )) # Bytes cumulative for Bill.
					(( FinalTotals[2]+=EachReportLine[3] )) # Bytes cumulative for TCPRX.
					(( FinalTotals[3]+=EachReportLine[4] )) # Bytes cumulative for TCPTX.
					(( FinalTotals[4]+=EachReportLine[5] )) # Bytes cumulative for UDPRX.
					(( FinalTotals[5]+=EachReportLine[6] )) # Bytes cumulative for UDPTX.

					# Perform analysis of the trending.
					TrendStore[0]="${TotalMB[${i}]}"
					TrendStore[1]="${TotalMB[$((i+1))]:-${TotalMB[${i}]}}"
					TrendStore[2]="${TotalMB[$((i+2))]:-${TotalMB[$((i+1))]:-${TotalMB[${i}]}}}"
					TrendStore[3]="${TotalMB[$((i+3))]:-${TotalMB[$((i+2))]:-${TotalMB[$((i+1))]:-${TotalMB[${i}]}}}}"
					TrendTotalMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain TotalMB Trend.
					TrendStore[0]="${BillMB[${i}]}"
					TrendStore[1]="${BillMB[$((i+1))]:-${BillMB[${i}]}}"
					TrendStore[2]="${BillMB[$((i+2))]:-${BillMB[$((i+1))]:-${BillMB[${i}]}}}"
					TrendStore[3]="${BillMB[$((i+3))]:-${BillMB[$((i+2))]:-${BillMB[$((i+1))]:-${BillMB[${i}]}}}}"
					TrendBillMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain BillMB Trend.
					TrendStore[0]="${TCPTXMB[${i}]}"
					TrendStore[1]="${TCPTXMB[$((i+1))]:-${TCPTXMB[${i}]}}"
					TrendStore[2]="${TCPTXMB[$((i+2))]:-${TCPTXMB[$((i+1))]:-${TCPTXMB[${i}]}}}"
					TrendStore[3]="${TCPTXMB[$((i+3))]:-${TCPTXMB[$((i+2))]:-${TCPTXMB[$((i+1))]:-${TCPTXMB[${i}]}}}}"
					TrendTCPTXMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain TCPRXMB Trend.
					TrendStore[0]="${TCPRXMB[${i}]}"
					TrendStore[1]="${TCPRXMB[$((i+1))]:-${TCPRXMB[${i}]}}"
					TrendStore[2]="${TCPRXMB[$((i+2))]:-${TCPRXMB[$((i+1))]:-${TCPRXMB[${i}]}}}"
					TrendStore[3]="${TCPRXMB[$((i+3))]:-${TCPRXMB[$((i+2))]:-${TCPRXMB[$((i+1))]:-${TCPRXMB[${i}]}}}}"
					TrendTCPRXMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain TCPTXMB Trend.
					TrendStore[0]="${UDPRXMB[${i}]}"
					TrendStore[1]="${UDPRXMB[$((i+1))]:-${UDPRXMB[${i}]}}"
					TrendStore[2]="${UDPRXMB[$((i+2))]:-${UDPRXMB[$((i+1))]:-${UDPRXMB[${i}]}}}"
					TrendStore[3]="${UDPRXMB[$((i+3))]:-${UDPRXMB[$((i+2))]:-${UDPRXMB[$((i+1))]:-${UDPRXMB[${i}]}}}}"
					TrendUDPRXMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain UDPRXMB Trend.
					TrendStore[0]="${UDPTXMB[${i}]}"
					TrendStore[1]="${UDPTXMB[$((i+1))]:-${UDPTXMB[${i}]}}"
					TrendStore[2]="${UDPTXMB[$((i+2))]:-${UDPTXMB[$((i+1))]:-${UDPTXMB[${i}]}}}"
					TrendStore[3]="${UDPTXMB[$((i+3))]:-${UDPTXMB[$((i+2))]:-${UDPTXMB[$((i+1))]:-${UDPTXMB[${i}]}}}}"
					TrendUDPTXMB=$(CalculateMetrics "TREND" "${TrendStore[3]} ${TrendStore[2]} ${TrendStore[1]} ${TrendStore[0]}") # Ascertain UDPTXMB Trend.

					PrintHelper "BOXITEMB" "INC$(printf "%04d" "$((${#SearchShardsReturn[*]}-i))")" "NORMAL:::${EachReportLine[0]/T/:}" "${TrendTotalMB/PLACEHOLDER/${TotalMB[${i}]}},${TrendBillMB/PLACEHOLDER/${BillMB[${i}]}},${TrendTCPRXMB/PLACEHOLDER/${TCPRXMB[${i}]}},${TrendTCPTXMB/PLACEHOLDER/${TCPTXMB[${i}]}},${TrendUDPRXMB/PLACEHOLDER/${UDPRXMB[${i}]}},${TrendUDPTXMB/PLACEHOLDER/${UDPTXMB[${i}]}}"

					CheckSemaphore "MIDB"

				done

				CalculateMetrics "FINALREPORT" "${FinalTotals[*]}"
				CheckSemaphore "END"

				# For whole network, drill deeper if required.
				while true; do

					if [[ ${Target_ENDPOINT[0]} == "WHOLENETWORK" ]] && GetYorN "Drill deeper for usage breakdown on one of the increments?" "No"; then

						while true; do
							# Get the selected increment as the from boundary.
							! GetResponse "Which increment number? (1-${#SearchShardsReturn[*]})" \
								&& DrillInc="NULL" \
								&& break
							# Ensure this number does not go out of bounds.
							if [[ ${UserResponse} =~ ${ValidNumber} ]] && [[ ${UserResponse} -ge 1 ]] && [[ ${UserResponse} -le ${#SearchShardsReturn[*]} ]]; then
								DrillInc="${UserResponse}"
								DrillTiming[0]="${SearchShardsReturn[$((${#SearchShardsReturn[*]}-DrillInc[0]))]%=>*}"
								break
							else
								AttentionMessage "ERROR" "The value you entered \"${UserResponse}\" is not valid. Try again."
							fi
						done
						[[ ${DrillInc:-NULL} == "NULL" ]] \
							&& continue

						# Get the next increment as the to boundary.
						if [[ ${DrillInc} -eq ${#SearchShardsReturn[*]} ]]; then
							DrillTiming[1]="now"
						else
							DrillTiming[1]="${SearchShardsReturn[$((${#SearchShardsReturn[*]}-DrillInc[0]-1))]%=>*}"
						fi

						# Save the current shard information.
						SaveShards=( ${SearchShardsReturn[*]} )

						# At this point, there is a valid FROM and TO time period.
						AttentionMessage "GENERALINFO" "Historical information trails current time by approximately two hours. [NOW=$(date -u)]"
						AttentionMessage "GENERALINFO" "Searching and generating (${EventTiming[1]} of ${DrillTiming[0]:0:${DateFormat}}) usage breakdown report for \"${Target_ENDPOINT[1]}\"."

						# The return code was TRUE/0.
						if SearchShards "GETNETWORKDRILLUSAGE" "${DrillTiming[0]}" "${DrillTiming[1]}" "${EventTiming[1]}"; then

							if [[ ${SearchShardsReturn[0]} != "NO SHARDS" ]]; then

								for ((i=${#SearchShardsReturn[*]};i>=0;i--)); do

									# Begin the printing.
									if [[ ${i} -eq ${#SearchShardsReturn[*]} ]]; then
										# This is the most current state - the top of the report.
										CheckSemaphore "BEGIN" "name"
										continue
									fi

									# 0/ENDPOINTNAME 1/TOTALBYTES 2/BILLBYTES 3/TCPRXBYTES 4/TCPTXBYTES 5/UDPRXBYTES 6/UDPTXBYTES
									IFS=','; EachReportLine=( ${SearchShardsReturn[${i}]//=>/,} ); IFS=$'\n'

									# Calculations.
									EachReportLine[0]="${EachReportLine[0]}" # The endpoint name.
									TotalMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[1]}") # Bytes in MegaByte (MB) for Total.
									BillMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[2]}") # Bytes in MegaByte (MB) for Billable.
									TCPRXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[3]}") # Bytes in MegaByte (MB) for RX TCP.
									TCPTXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[4]}") # Bytes in MegaByte (MB) for TX TCP.
									UDPRXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[5]}") # Bytes in MegaByte (MB) for RX UDP.
									UDPTXMB[${i}]=$(CalculateMetrics "B2MB" "${EachReportLine[6]}") # Bytes in MegaByte (MB) for TX UDP.

									PrintHelper "BOXITEMB" "MERGE" "NORMAL:::${EachReportLine[0]}" "NORMAL:::${TotalMB[${i}]},${Normal}:::${BillMB[${i}]},${Normal}:::${TCPRXMB[${i}]},${Normal}:::${TCPTXMB[${i}]},${Normal}:::${UDPRXMB[${i}]},${Normal}:::${UDPTXMB[${i}]}"

									CheckSemaphore "MIDB"

								done

								#CalculateMetrics "FINALREPORT" "${FinalTotals[*]}"
								CheckSemaphore "END"

							fi

						else

							# Conditional catches.
							[[ ${SearchShardsReturn[0]} == "NO SHARDS" ]] \
								&& AttentionMessage "WARNING" "The search returned ZERO matching shards/events."

						fi

						# Restore the shard information from prior.
						SearchShardsReturn=( ${SaveShards[*]} )

					else

						break

					fi

				done

				! GetYorN "Perform another Endpoint search and report?" "Yes" \
					&& break 2 \
					|| break

			else

				# Conditional catches.
				[[ ${SearchShardsReturn[0]} == "NO SHARDS" ]] \
					&& AttentionMessage "WARNING" "The search returned ZERO matching shards/events."
				[[ ${#SearchShardsReturn[*]} -gt 9999 ]] \
					&& AttentionMessage "WARNING" "The search returned too many matching shards/events (${#SearchShardsReturn[*]}). Please narrow the search."
				! GetYorN "Perform another Endpoint search and report?" "Yes" \
					&& break 2 \
					|| break

			fi

		# The return code was FALSE/1.
		else

			AttentionMessage "ERROR" "FAILED! The search request failed. See message below."
			echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
			! GetYorN "Perform another Endpoint search and report?" "Yes" \
				&& break 2 \
				|| break

		fi

	done
}

#################################################################################
# A last activity report is a for review of the last activity event for all Dndpoints.
function RunLastActivityReport() {
	local i ReportBegin ReportDuration SearchShardsReturn EachReportLine LastEventEpoch
	local OutputResponse OutputHeaders OutputJSON
	local EventTiming # 0/CUREPOCHSEC 1/REQSTART 2/REQDAYS 3/REQSEC 4/BEGINEPOCHSEC
	local TotalSeconds DeltaDays DeltaHours DeltaMinutes DeltaSeconds

	while true; do

		# The user needs to select how many days in arears to begin the search.
		EventTiming[0]="$(date +"%s")" # Epoch time for now.
		ReportBegin=( "0 Days Ago [NOW]" "1 Day Ago" "7 Days Ago" "14 Days Ago" "30 Days Ago" "60 Days Ago" "90 Days Ago" )
		for ((i=0;i<${#ReportBegin[*]};i++)); do
			ReportBegin[${i}]="${ReportBegin[${i}]} ($(date -d @$((EventTiming[0]-(${ReportBegin[${i}]//\ */}*86400)))))"
		done
		! GetSelection "How many days back should the report begin?" "${ReportBegin[*]}" \
			&& break 2
		EventTiming[1]="$((EventTiming[0]-(${UserResponse//\ */}*86400)))" # The epoch start.

		# The user needs to select how many days in arears to span the search.
		ReportDuration=( "1 Day Back" "7 Days Back" "14 Days Back" "30 Days Back" "60 Days Back" "90 Days Back" "365 Days Back" )
		for ((i=0;i<${#ReportDuration[*]};i++)); do
			ReportDuration[${i}]="${ReportDuration[${i}]} ($(date -d @$((EventTiming[1]-(${ReportDuration[${i}]//\ */}*86400)))))"
		done
		! GetSelection "How many days should the report contain?" "${ReportDuration[*]}" \
			&& continue
		EventTiming[2]="${UserResponse//\ */}" # The days requested factor.
		EventTiming[3]="$((EventTiming[2]*86400))" # The days requested factor in seconds.
		EventTiming[4]="$((EventTiming[1]-EventTiming[3]))" # The beginning of the search in epoch.

		AttentionMessage "GENERALINFO" "Last activity is determined by data flow on an Endpoint's control channel."
		AttentionMessage "GENERALINFO" "Historical information trails current time by approximately two hours. [NOW=$(date -u)]"
		AttentionMessage "GENERALINFO" "Searching and generating (${EventTiming[2]} Days, UTC Time Descending) Endoints Last Activity report."
		# The return code was TRUE/0.
		if SearchShards "GETLASTACTIVITY" "${EventTiming[4]}000" "${EventTiming[1]}000"; then

			if [[ ${SearchShardsReturn} != "NO SHARDS" ]]; then

				PrintHelper "BOXHEADLINEA" "EPT # " "NORMAL:::YYYY/MM/DD HH:MM [UTC]" "NAME=>UNTIL NOW"

				for ((i=0;i<${#SearchShardsReturn[*]};i++)); do

					# 0/NAME 1/LASTACTIVITY
					IFS=','; EachReportLine=( ${SearchShardsReturn[${i}]//=>/,} ); IFS=$'\n'
					EachReportLine[1]="$(date -d "${EachReportLine[1]}" "+%s")" # Time converted to epoch seconds.
					TotalSeconds="${EventTiming[0]}-${EachReportLine[1]}"
					DeltaDays="$(((EventTiming[0]-EachReportLine[1])/86400))"
					DeltaHours="$((((EventTiming[0]-EachReportLine[1])/3600)%24))"
					DeltaMinutes="$(((EventTiming[0]-EachReportLine[1])%3600/60))"
					PrintHelper "BOXITEMA" "EPT$(printf "%04d" "${i}")" "NORMAL:::$(date -ud @${EachReportLine[1]} +'%Y/%m/%d %H:%M')" "${EachReportLine[0]}=>${IconStash[12]} $(printf "%02dd %02dh %02dm %02ds" "${DeltaDays:-0}" "${DeltaHours:-0}" "${DeltaMinutes:-0}" "${DeltaSeconds:-0}")"

				done

				PrintHelper "BOXFOOTLINEA"

			else

				# Conditional catches.
				[[ ${SearchShardsReturn} == "NO SHARDS" ]] \
					&& AttentionMessage "WARNING" "The search returned ZERO matching shards/events."
				! GetYorN "Perform another Endpoint search and report?" "Yes" \
					&& break 2 \
					|| break

			fi

		! GetYorN "Perform another Endpoint search and report?" "Yes" \
			&& break 2 \
			|| break

		# The return code was FALSE/1.
		else

			AttentionMessage "ERROR" "FAILED! The search request failed. See message below."
			echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
			! GetYorN "Perform another Endpoint search and report?" "Yes" \
				&& break 2 \
				|| break

		fi

	done
}

#################################################################################
# An event report is a list of all events against a specific object.
function RunEventReport() {
	function CheckSemaphore() {
		# 1/TRIGGER[BEGIN/MID/END]
		local PrintTrigger="${1}"
		if [[ ${PrintTrigger} == "BEGIN" ]]; then
			PrintHelper "BOXHEADLINEA" "EVENT # " "NORMAL:::INDICATOR" "DESCRIPTION=>UNTIL NEXT EVENT"
			SemaphoreState="FALSE"
		elif [[ ${PrintTrigger} == "MIDA" ]] && [[ ${SemaphoreState} == "FALSE" ]]; then
			PrintHelper "BOXITEMASUBLINEA"
			SemaphoreState="TRUE"
		elif [[ ${PrintTrigger} == "MIDB" ]] && [[ ${SemaphoreState} == "TRUE" ]]; then
			PrintHelper "BOXITEMASUBLINEB"
			SemaphoreState="FALSE"
		elif [[ ${PrintTrigger} == "END" ]]; then
			[[ ${SemaphoreState} == "TRUE" ]] \
				&& PrintHelper "BOXFOOTLINEB" \
				|| PrintHelper "BOXFOOTLINEA"
			SemaphoreState="FALSE"
		fi
	}

	function CalculateMetrics() {
		function CalculatePercent() {
			# 1/ENDVALUE 2/INITVALUE 3/OFVALUE
			printf "%.2f" "$(bc -l <<< "100 * (${3} / (${2} - ${1}))" 2>/dev/null)"
		}

		# 1/TYPE
		# DELTASTATE       2/FROMSTATE 3/TOSTATE
		# DELTATIME        2/STARTEPOCH 3/ENDEPOCH
		# DELTADISTANCE    2/FROMLAT,FROMLON 3/TOLAT,TOLON
		# DELTAIPORT       2/FROMIP:FROMPORT 3/TOIP:TOPORT
		# DELTACITYSTATE   2/FROMCITY/FROMSTATE 3/TOCITY/TOSTATE
		# FINALREPORT      2/INITEPOCH 3/ENDEPOCH
		local MetricsType="${1}"
		local PrintHeader PrintTopic ReturnCode
		local FromState ToState
		local TotalSeconds DeltaDays DeltaHours DeltaMinutes DeltaSeconds
		local DeltaDistance
		local FromIPPORT DeltaIPPORT DeltaIP DeltaPORT
		local FromCityCountry ToCityCountry DeltaCityCountry DeltaCity DeltaCountry

		case ${MetricsType} in
			"DELTASTATE")
				FromState="${3}"
				# Translate the state into the common format.
				if [[ "${2}" =~ "Offline" ]]; then
					ToState="OFFLINE"
					ReturnCode="1"
					(( TallyOffline[0]++ ))
				elif [[ "${2}" =~ "Online" ]]; then
					ToState="ONLINE"
					ReturnCode="2"
					(( TallyOnline[0]++ ))
				elif [[ "${2}" =~ "fstration" ]] || [[ "${2}" =~ "Register" ]] || [[ "${2}" =~ "CSR request" ]] || [[ "${2}" =~ "VTC Provisioning" ]]; then
					ToState="PROVISIONING"
					PrintHeader="   ${IconStash[13]}  "
					PrintTopic=":::PROVISIONING INFO"
					ReturnCode="3"
					(( TallyProvision[0]++ ))
				else
					ToState="STATUS"
					PrintHeader="   ${IconStash[10]} "
					PrintTopic=":::STATUS INFO"
					ReturnCode="4"
					(( TallyStatus[0]++ ))
				fi
				# Analyze.
				if [[ ${ToState} == "PROVISIONING" ]]; then
					CheckSemaphore "MIDA"
					PrintHelper "BOXITEMASUB" "${PrintHeader}" "${PrintTopic}" "${2/with key:*/}"
				elif [[ ${ToState} == "STATUS" ]]; then
					CheckSemaphore "MIDA"
					PrintHelper "BOXITEMASUB" "${PrintHeader}" "${PrintTopic}" "${2}"
				elif [[ ${FromState} == "${ToState}" ]] || [[ ${FromState} == "${ToState}" ]]; then
					(( ReturnCode+=10 ))
				fi
				return ${ReturnCode}
			;;

			"DELTATIME"|"DELTATIMEREVERSE"|"DELTATIMEQUICK"|"DELTATIMETALLY")
				if [[ ${3} == "0/0" ]]; then
					TotalSeconds="0"
					DeltaDays="0"
					DeltaHours="0"
					DeltaMinutes="0"
					DeltaSeconds="0"
				else
					TotalSeconds="$((${3}-${2}))"
					DeltaDays="$(((${3}-${2})/86400))"
					DeltaHours="$((((${3}-${2})/3600)%24))"
					DeltaMinutes="$(((${3}-${2})%3600/60))"
					DeltaSeconds="$(((${3}-${2})%60))"
				fi
				if [[ ${MetricsType} == "DELTATIMETALLY" ]]; then
					printf "%s\n" "${TotalSeconds:-0}"
				elif [[ ${MetricsType} == "DELTATIMEQUICK" ]]; then
					printf "%02dd %02dh %02dm %02ds" "${DeltaDays:-0}" "${DeltaHours:-0}" "${DeltaMinutes:-0}" "${DeltaSeconds:-0}"
				elif [[ ${MetricsType} == "DELTATIMEREVERSE" ]]; then
					if [[ ${TotalSeconds} -ge 21600 ]]; then
						# Greater than or equal to 6 hours.
						PrintHeader="   ${IconStash[8]} "
						PrintTopic="INFO:::TIME MOVE INFO"
					elif [[ ${TotalSeconds} -ge 10800 ]]; then
						# Greater than or equal to 3 hours.
						PrintHeader=" ! ${IconStash[8]} "
						PrintTopic="WARNING:::TIME MOVE WARNING"
					elif [[ ${TotalSeconds} -lt  10800 ]]; then
						# less than 3 hours.
						PrintHeader=" !!${IconStash[8]} "
						PrintTopic="ALERT:::TIME MOVE ALERT"
					fi
					CheckSemaphore "MIDA"
					PrintHelper "BOXITEMASUB" "${PrintHeader}" "${PrintTopic}" "Traveled in $(printf "%02dd %02dh %02dm %02ds" "${DeltaDays:-0}" "${DeltaHours:-0}" "${DeltaMinutes:-0}" "${DeltaSeconds:-0}")"
				elif [[ ${MetricsType} == "DELTATIME" ]]; then
					if [[ ${DeltaDays} -gt 30 ]]; then
						PrintHeader=" !!${IconStash[8]} "
						PrintTopic="ALERT:::TIME SINCE ALERT"
					elif [[ ${DeltaDays} -gt 14 ]]; then
						PrintHeader=" ! ${IconStash[8]} "
						PrintTopic="WARNING:::TIME SINCE WARNING"
					elif [[ ${DeltaDays} -gt 7 ]]; then
						PrintHeader="   ${IconStash[8]} "
						PrintTopic="INFO:::TIME SINCE INFO"
					elif [[ ${DeltaDays} -le 7 ]]; then
						return 0
					fi
					CheckSemaphore "MIDA"
					PrintHelper "BOXITEMASUB" "${PrintHeader}" "${PrintTopic}" "Since Last Event $(printf "%02dd %02dh %02dm %02ds" "${DeltaDays:-0}" "${DeltaHours:-0}" "${DeltaMinutes:-0}" "${DeltaSeconds:-0}")"
				fi
			;;

			"DELTADISTANCE")
				DeltaDistance="$(GetLatLonDistance "${2%,*}" "${2#*,}" "${3%,*}" "${3#*,}" 2>/dev/null)"
				if [[ ${DeltaDistance:-0} -gt 300 ]]; then
					PrintHeader=" ! ${IconStash[9]} "
					PrintTopic="WARNING:::DISTANCE SIZE WARNING"
					ReturnCode="1"
				elif [[ ${DeltaDistance:-0} -le 30 ]]; then
					return 0
				else
					PrintHeader="   ${IconStash[9]} "
					PrintTopic="INFO:::DISTANCE SIZE INFO"
					ReturnCode="0"
				fi
				CheckSemaphore "MIDA"
				PrintHelper "BOXITEMASUB" "${PrintHeader}" "${PrintTopic}" "Traveled ${DeltaDistance}mi"
				return ${ReturnCode}
			;;

			"DELTAIPPORT")
				FromIPPORT=( ${2/\:/${NewLine}} ) # From, 0/IP 1/PORT
				ToIPPORT=( ${3/\:/${NewLine}} ) # To, 0/IP 1/PORT
				DeltaIP[0]="${FromIPPORT[0]:-UNKNOWN}" # FromIP
				DeltaIP[1]="${ToIPPORT[0]:-UNKNOWN}" # ToIP
				DeltaPORT[0]="${FromIPPORT[1]:-UNKNOWN}" # FromPORT
				DeltaPORT[1]="${ToIPPORT[1]:-UNKNOWN}" # ToPORT
				if [[ ${DeltaIP[0]} != "${DeltaIP[1]}" ]] && [[ ${DeltaPORT[0]} != "${DeltaPORT[1]}" ]]; then
					DeltaIPPORT="IP and PORT Changed [${DeltaIP[0]}:${DeltaPORT[0]} > ${DeltaIP[1]}:${DeltaPORT[1]}]"
				elif [[ ${DeltaIP[0]} != "${DeltaIP[1]}" ]] && [[ ${DeltaPORT[0]} == "${DeltaPORT[1]}" ]]; then
					DeltaIPPORT="IP Changed [${DeltaIP[0]}:${DeltaPORT[0]} > ${DeltaIP[1]}:${DeltaPORT[1]}]"
				elif [[ ${DeltaIP[0]} == "${DeltaIP[1]}" ]] && [[ ${DeltaPORT[0]} != "${DeltaPORT[1]}" ]]; then
					#DeltaIPPORT="PORT Changed [${DeltaIP[0]}:${DeltaPORT[0]} > ${DeltaIP[1]}:${DeltaPORT[1]}]"
					return 0
				else
					return 0
				fi
				CheckSemaphore "MIDA"
				PrintHelper "BOXITEMASUB" "   ${IconStash[10]} " "INFO:::IP:PORT CHANGE INFO" "${DeltaIPPORT}"
			;;

			"DELTACITYCOUNTRY")
				FromCityCountry=( ${2/\//${NewLine}} ) # From, 0/City 1/Country
				ToCityCountry=( ${3/\//${NewLine}} ) # To, 0/City 1/Country
				DeltaCity[0]="${FromCityCountry[0]:-UNKNOWN}" # FromCity
				DeltaCity[1]="${ToCityCountry[0]:-UNKNOWN}" # ToCity
				DeltaCountry[0]="${FromCityCountry[1]:-UNKNOWN}" # FromCountry
				DeltaCountry[1]="${ToCityCountry[1]:-UNKNOWN}" # ToCountry
				if [[ ${DeltaCity[0]} != "${DeltaCity[1]}" ]] && [[ ${DeltaCountry[0]} != "${DeltaCountry[1]}" ]]; then
					DeltaCityCountry="City and Country Changed [${DeltaCity[0]}/${DeltaCountry[0]} > ${DeltaCity[1]}/${DeltaCountry[1]}]"
				elif [[ ${DeltaCity[0]} != "${DeltaCity[1]}" ]] && [[ ${DeltaCountry[0]} == "${DeltaCountry[1]}" ]]; then
					DeltaCityCountry="City Changed [${DeltaCity[0]}/${DeltaCountry[0]} > ${DeltaCity[1]}/${DeltaCountry[1]}]"
				elif [[ ${DeltaCity[0]} == "${DeltaCity[1]}" ]] && [[ ${DeltaCountry[0]} != "${DeltaCountry[1]}" ]]; then
					DeltaCityCountry="Country Changed [${DeltaCity[0]}/${DeltaCountry[0]} > ${DeltaCity[1]}/${DeltaCountry[1]}]"
				else
					return 0
				fi
				CheckSemaphore "MIDA"
				PrintHelper "BOXITEMASUB" "   ${IconStash[11]} " "INFO:::LOCATION CHANGE INFO" "${DeltaCityCountry}"
			;;

			"FINALREPORT")
				InitEpoch="${2}"
				EndEpoch="${3}"
				AttentionMessage "GENERALINFO" "Final report for \"${Target_ENDPOINT[0]}\"."
				printf "%-35s: %s\n" \
					"Report Begin" \
					"$(date -d @${InitEpoch})"
				printf "%-35s: %s\n" \
					"Report End Actual" \
					"$(date -d @${EndEpoch})"
				printf "%-35s: %s\n" "Report Span Actual" \
					"$(CalculateMetrics "DELTATIMEQUICK" "${EndEpoch}" "${InitEpoch}")"
				printf "%-35s: %-5s / %15s (%5s%%) / %15s\n" \
					"ONLINE Events    / Time (%) / Avg" \
					"${TallyOnline[0]}" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyOnline[1]}")" \
					"$(CalculatePercent "${EndEpoch}" "${InitEpoch}" "${TallyOnline[1]}")" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyOnline[1]}/${TallyOnline[0]}")"
				printf "%-35s: %-5s / %15s (%5s%%) / %15s\n" \
					"OFFLINE Events   / Time (%) / Avg" \
					"${TallyOffline[0]}" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyOffline[1]}")" \
					"$(CalculatePercent "${EndEpoch}" "${InitEpoch}" "${TallyOffline[1]}")" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyOffline[1]}/${TallyOffline[0]}")"
				printf "%-35s: %-5s / %15s (%5s%%) / %15s\n" \
					"PROVISION Events / Time (%) / Avg" \
					"${TallyProvision[0]}" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyProvision[1]}")" \
					"$(CalculatePercent "${EndEpoch}" "${InitEpoch}" "${TallyProvision[1]}")" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyProvision[1]}/${TallyProvision[0]}")"
				printf "%-35s: %-5s / %15s (%5s%%) / %15s\n" \
					"STATUS Events    / Time (%) / Avg" \
					"${TallyStatus[0]}" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyStatus[1]}")" \
					"$(CalculatePercent "${EndEpoch}" "${InitEpoch}" "${TallyStatus[1]}")" \
					"$(CalculateMetrics "DELTATIMEQUICK" "0" "${TallyStatus[1]}/${TallyStatus[0]}")"
			;;

		esac

		return 0
	}

	# 1/TARGETUUID
	local i ReportBegin ReportDuration SearchShardsReturn EachReportLine LastEventEpoch EventDeltaTime LastEventState LastEventIPPORT LastEventLatLon
	local OutputResponse OutputHeaders OutputJSON
	local EventTiming # 0/CUREPOCHSEC 1/REQDAYS 2/REQSEC 3/BEGINEPOCHSEC
	local Target_ENDPOINT[0]="${1}"
	SemaphoreState="FALSE"

	# Reset the global counters.
	# 0/EVENTSQUANTITY 1/EVENTSTOTALTIME
	TallyOnline[0]="0" TallyOffline[0]="0" TallyStatus[0]="0" TallyProvision[0]="0"
	TallyOnline[1]="0" TallyOffline[1]="0" TallyStatus[1]="0" TallyProvision[1]="0"

	# Input text "TYPE:::NAME:::UUID".
	Target_ENDPOINT[1]="${Target_ENDPOINT[0]%%=>*}" # TYPE:::NAME
	Target_ENDPOINT[2]="${Target_ENDPOINT[0]##*=>}" # UUID
	while true; do

		# The user needs to select how many days in arears to begin the search.
		EventTiming[0]="$(date +"%s")" # Epoch time for now.
		ReportBegin=( "0 Days Ago [NOW]" "1 Day Ago" "7 Days Ago" "14 Days Ago" "30 Days Ago" "60 Days Ago" "90 Days Ago" )
		for ((i=0;i<${#ReportBegin[*]};i++)); do
			ReportBegin[${i}]="${ReportBegin[${i}]} ($(date -d @$((EventTiming[0]-(${ReportBegin[${i}]//\ */}*86400)))))"
		done
		! GetSelection "How many days back should the report on \"${Target_ENDPOINT[1]}\" begin?" "${ReportBegin[*]}" \
			&& return 0
		EventTiming[0]="$((EventTiming[0]-(${UserResponse//\ */}*86400)))" # The epoch start.

		# The user needs to select how many days in arears to span the search.
		ReportDuration=( "1 Day Back" "7 Days Back" "14 Days Back" "30 Days Back" "60 Days Back" "90 Days Back" "365 Days Back" )
		for ((i=0;i<${#ReportDuration[*]};i++)); do
			ReportDuration[${i}]="${ReportDuration[${i}]} ($(date -d @$((EventTiming[0]-(${ReportDuration[${i}]//\ */}*86400)))))"
		done
		! GetSelection "How many days should the report on \"${Target_ENDPOINT[1]}\" contain?" "${ReportDuration[*]}" \
			&& return 0
		EventTiming[1]="${UserResponse//\ */}" # The days requested factor.
		EventTiming[2]="$((EventTiming[1]*86400))" # The days requested factor in seconds.
		EventTiming[3]="$((EventTiming[0]-EventTiming[2]))" # The beginning of the search in epoch.

		AttentionMessage "GENERALINFO" "Searching and generating (${EventTiming[1]} Days) Endpoint Events report for \"${Target_ENDPOINT[1]}\"."
		# The return code was TRUE/0.
		if SearchShards "GETSPECIFICSTATUS" "${EventTiming[3]}000" "${EventTiming[0]}000" "${Target_ENDPOINT[2]}"; then

			if [[ ${SearchShardsReturn} != "NO SHARDS" ]] && [[ ${#SearchShardsReturn[*]} -le 9999 ]]; then

				for ((i=0;i<${#SearchShardsReturn[*]};i++)); do

					if [[ $((i%100)) -eq 0 ]] && [[ ${i} -ne 0 ]]; then
						! GetYorN "Shown ${i}/${#SearchShardsReturn[*]} - Show more?" "Yes" "5" \
							&& ClearLines "1" \
							&& CheckSemaphore "END" \
							&& CalculateMetrics "FINALREPORT" "${EventTiming[0]}" "${LastEventEpoch}" \
							&& break
					fi

					# 0/RFC3339DATE 1/[EVENT/STATE] 2/IP:PORT 3/CITYSTATE 4/LAT,LON
					IFS=','; EachReportLine=( ${SearchShardsReturn[${i}]//=>/,} ); IFS=$'\n'

					EachReportLine[0]="$(date -d "${EachReportLine[0]}" "+%s")" # Time converted to epoch seconds.

					# The printing for A to B analysis.
					if [[ ${i} -eq 0 ]]; then
						# This is the most current state - the top of the report.
						CheckSemaphore "BEGIN"
						PrintHelper "BOXITEMA" "EVT$(printf "%04d" "$((${#SearchShardsReturn[*]}+1))")" "BEGIN:::CURRENT" "$(date -d @${EventTiming[0]} '+%d/%m/%y %T %Z')"
						CalculateMetrics "DELTASTATE" "${EachReportLine[1]}" "${LastEventState}"
						EachReportLine[1]=$? # A temporary storage of state for translation later.
						CalculateMetrics "DELTATIME" "${EachReportLine[0]}" "${EventTiming[0]}"
						LastEventEpoch="${EventTiming[0]}"
					else
						CalculateMetrics "DELTASTATE" "${EachReportLine[1]}" "${LastEventState}"
						EachReportLine[1]=$? # A temporary storage of state for translation later.
						CalculateMetrics "DELTATIME" "${EachReportLine[0]}" "${LastEventEpoch}"
						CalculateMetrics "DELTACITYCOUNTRY" "${EachReportLine[3]}" "${LastEventCityCountry}"
						! CalculateMetrics "DELTADISTANCE" "${EachReportLine[4]}" "${LastEventLatLon}" \
							&& CalculateMetrics "DELTATIMEREVERSE" "${EachReportLine[0]}" "${LastEventEpoch}"
						CalculateMetrics "DELTAIPPORT" "${EachReportLine[2]}" "${LastEventIPPORT}"
					fi

					# Store the last event details to analyze it against the next one.
					EventDeltaTime[0]="$(CalculateMetrics "DELTATIMETALLY" "${EachReportLine[0]}" "${LastEventEpoch}")"
					EventDeltaTime[1]="$(CalculateMetrics "DELTATIMEQUICK" "${EachReportLine[0]}" "${LastEventEpoch}")"
					LastEventEpoch="${EachReportLine[0]}"
					case "${EachReportLine[1]}" in
						1)
							LastEventState="OFFLINE"
							(( TallyOffline[1]+=EventDeltaTime[0] ))
						;;
						11)
							LastEventState="^LINKED-OFFLINE"
							(( TallyOffline[1]+=EventDeltaTime[0] ))
						;;
						2)
							LastEventState="ONLINE"
							(( TallyOnline[1]+=EventDeltaTime[0] ))
						;;
						12)
							LastEventState="^LINKED-ONLINE"
							(( TallyOnline[1]+=EventDeltaTime[0] ))
						;;
						3|13)
							LastEventState="PROVISIONING"
							(( TallyProvision[1]+=EventDeltaTime[0] ))
						;;
						4|14)
							LastEventState="STATUS"
							(( TallyStatus[1]+=EventDeltaTime[0] ))
						;;
					esac
					LastEventIPPORT="${EachReportLine[2]}"
					LastEventCityCountry="${EachReportLine[3]}"
					LastEventLatLon="${EachReportLine[4]}"

					CheckSemaphore "MIDB"

					# Printing for the event.
					PrintHelper "BOXITEMA" "EVT$(printf "%04d" "$((${#SearchShardsReturn[*]}-i))")" "${LastEventState#*-}:::" "$(printf "%-15s" "${LastEventState}") at $(date -d @${LastEventEpoch} '+%d/%m/%y %T %Z')=>${IconStash[12]} ${EventDeltaTime[1]}"

					# This is the last state - the bottom of the report.
					if [[ $((${#SearchShardsReturn[*]}-i)) -eq 1 ]]; then
						CalculateMetrics "DELTACITYCOUNTRY" "UNKNOWN" "${EachReportLine[3]}"
						CalculateMetrics "DELTAIPPORT" "UNKNOWN" "${EachReportLine[2]}"
						CheckSemaphore "END"
						CalculateMetrics "FINALREPORT" "${EventTiming[0]}" "${LastEventEpoch}"
					fi

				done

				! GetYorN "Perform another Endpoint search and report?" "Yes" \
					&& break 2 \
					|| break

			else

				# Conditional catches.
				[[ ${SearchShardsReturn} == "NO SHARDS" ]] \
					&& AttentionMessage "WARNING" "The search returned ZERO matching shards/events."
				[[ ${#SearchShardsReturn[*]} -gt 9999 ]] \
					&& AttentionMessage "WARNING" "The search returned too many matching shards/events (${#SearchShardsReturn[*]}). Please narrow the search."
				! GetYorN "Perform another Endpoint search and report?" "Yes" \
					&& break 2 \
					|| break

			fi


		# The return code was FALSE/1.
		else

			AttentionMessage "ERROR" "FAILED! The search request failed. See message below."
			echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
			! GetYorN "Perform another Endpoint search and report?" "Yes" \
				&& break 2 \
				|| break

		fi

	done
}

#################################################################################
# Macros which are workflows of instructions.
function RunMacro() {
	# 1/TYPE
	local i AllNetworksExt
	local MacroType="${1}"

	case ${MacroType} in

		"ORGANIZATIONSEARCH"|"NETWORKSEARCH")

			# Single vs All Network search in the Organization.
			if [[ ${MacroType} == "NETWORKSEARCH" ]]; then
				! GetFilterString "Your filter input applies to only elements in the \"${Target_NETWORK[1]}\" Network which the Console Bearer Token permits access to." \
					&& return 0
				AllNetworksExt="${Target_NETWORK[1]}=>${Target_NETWORK[0]}" # Reassemble NAME=>UUID for the function to follow.
			elif [[ ${MacroType} == "ORGANIZATIONSEARCH" ]]; then
				! GetFilterString "Your filter input applies to ALL Networks in Organization \"${Target_ORGANIZATION[1]}\" which the Console Bearer Token permits access to." \
					&& return 0
				AllNetworksExt=( ${AllV6Networks[*]} ${AllNetworks_V7[*]} )
			fi

			# Get the filter and kick off the search.
			for EachNetwork in ${AllNetworksExt[*]}; do
				Target_NETWORK[0]="${EachNetwork##*=>}" # UUID.
				Target_NETWORK[1]="${EachNetwork%%=>*}" # Name.
				AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of criteria matching Endpoints, EndpointGroups, Services, or AppWANs in Network \"${Target_NETWORK[1]}\"."
				GetObjects_MOP "ENDPOINTS"
				GetObjects_MOP "ENDPOINTGROUPS"
				GetObjects_MOP "SERVICES"
				GetObjects_MOP "APPWANS"
				[[ ${#AllEndpoints} -eq 0 ]] && [[ ${#AllEndpoints} -eq 0 ]] && [[ ${#AllEndpoints} -eq 0 ]] && [[ ${#AllEndpoints} -eq 0 ]] \
					&& AttentionMessage "WARNING" "There were no matching Endpoints, EndpointGroups, Services, or AppWANs."
			done

		;;

		"CREATEINTERNETSERVICES")
			CreateInternetServices \
				&& AttentionMessage "VALIDATED" "The macro to create Internet Services completed successfully." \
				|| AttentionMessage "REDINFO" "The macro to create Internet Services did not complete successfully."
		;;

		"BULKCREATEENDPOINTS")

			while true; do

				! GetResponse "Enter /path/filename [EX: /home/myuser/BulkEndpoints.csv or BulkEndpoints.csv]. [LS=LISTLOCAL]" \
					&& return 0
				BulkImportFile="${UserResponse}"
				case ${BulkImportFile} in
					"LS"|"ls")
						AttentionMessage "GENERALINFO" "The following is a list of files/folders in your local/relative directory."
						(pwd)
						(ls .)
						continue
					;;
					*)
						if [[ -e ${BulkImportFile:-NOTSET} ]]; then
							BulkCreateEndpoints "${BulkImportFile}" \
								&& AttentionMessage "VALIDATED" "The macro to bulk Create Endpoints completed successfully." \
								|| AttentionMessage "REDINFO" "The macro to bulk Create Endpoints did not complete successfully."
						else
							AttentionMessage "ERROR" "Bulk Create Endpoints reported invalid/missing file \"${BulkImportFile:-NOTSET}\"."
						fi
					;;
				esac

			done

		;;

	esac
}

#################################################################################
# Sets objects using the API.
function SetObjects_MOP_V6() {
	# 1/TYPE 2-10/[DATAFIELDS]
	local SetType="${1}"
	local MaxTries="10" # MACD max attempts.
	local DATASyntax # The syntax to send to API.
	unset SetObjectReturn # Ensure this is not already set.

	# Set what type of object?
	case ${SetType} in

		"LOGOUT")
			# No input.
			if ProcessResponse "${POSTSyntax_MOP}" "${APIIDENTITYURL}/logout" "200"; then
				return 0
			else
				SetObjectReturn="${OutputJSON}"
				return 1
			fi
		;;

		"EMAILALERT")
			# 2/ENDPOINTUUID 3/EMAILADDRESS 4/MESSAGE
			DATASyntax="--data '{\"toList\":\""${3}"\",\"subject\":\"NetFoundry - Registration Information\",\"from\":\"no-reply@netfoundry.io\",\"replacementParams\":{\"USER\":\""${4}"\"}}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpoints/${2}/share" "202"; then
				return 0
			else
				SetObjectReturn="${OutputJSON}"
				return 1
			fi
		;;

		"CREATEAPPWAN")
			# 2/APPWANNAME
			DATASyntax="--data '{\"name\":\""${2}"\"}'"
			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/appWans" "202"; then
				read -d '' -ra SetObjectReturn < <( \
					jq -r '
						(select(.name != null) .name + "=>" + (._links.self.href | split("/"))[-1])
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				SetObjectReturn[0]="${OutputJSON}"
				return 1
			fi
		;;

		"DELAPPWAN")
			# 2/UUID
			if ProcessResponse "${DELETESyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/appWans/${2}" "202"; then
				read -d '' -ra SetObjectReturn < <( \
					jq -r '
						if type=="array" then
							(.[] | "NOTREADY: " + .message)
						else
							empty
						end
					' <<< "${OutputJSON}" 2>&1
				)
				return 0
			else
				SetObjectReturn[0]="${OutputJSON}"
				return 1
			fi
		;;

		"CREATEENDPOINTGROUP")
			# 2/ENDPOINTGROUPNAME
			DATASyntax="--data '{\"name\":\""${2}"\",\"source\":null,\"syncId\":null}'"
			ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpointGroups" "201" \
				|| return 1
			read -d '' -ra SetObjectReturn < <( \
				jq -r '
					if type=="array" then
						(.[] | "NOTREADY: " + .message)
					else
						empty
					end
				' <<< "${OutputJSON}" 2>&1
			)
			[[ ${SetObjectReturn:-NOTREADY} =~ "NOTREADY" ]] \
				&& return 1 \
				|| return 0
		;;

		"DELENDPOINTGROUP")
			# 2/UUID
			ProcessResponse "${DELETESyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpointGroups/${2}" "202" \
				&& return 0 \
				|| return 1
		;;

		"DELSERVICE")
			# 2/UUID
			ProcessResponse "${DELETESyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/services/${2}" "202" \
				&& return 0 \
				|| return 1
		;;

		"DELENDPOINT")
			# 2/UUID
			ProcessResponse "${DELETESyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpoints/${2}" "202" \
				&& return 0 \
				|| return 1
		;;

		"CREATENETSERVICE")
			# 2/GWUUID 3/SERVICENAME 4/INTERCEPTIP 5/GWIP 6/CIDR
			DATASyntax="--data '{\"serviceClass\":\"GW\",\"serviceInterceptType\":\"IP\",\"serviceType\":\"ALL\",\"lowLatency\":\"YES\",\"dataInterleaving\":\"NO\",\"transparency\":\"NO\",\"localNetworkGateway\":\"YES\",\"multicast\":\"OFF\",\"dnsOptions\":\"NONE\",\"icmpTunnel\":\"YES\",\"cryptoLevel\":\"STRONG\",\"permanentConnection\":\"NO\",\"collectionLocation\":\"BOTH\",\"pbrType\":\"WAN\",\"rateSmoothing\":\"NO\",\"networkIp\":null,\"networkNetmask\":null,\"networkFirstPort\":0,\"networkLastPort\":0,\"interceptFirstPort\":0,\"interceptLastPort\":0,\"protectionGroupId\":null,\"portInterceptMode\":\"INTERCEPT_ALL\",\"endpointId\":\""${2}"\",\"name\":\""${3}"\",\"interceptIp\":\""${4}"\",\"gatewayIp\":\""${5}"\",\"gatewayCidrBlock\":\""${6}"\"}'"
			ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/services" "202" \
				|| return 1
			read -d '' -ra SetObjectReturn < <( \
				jq -r '
					if type=="array" then
						(.[] | "NOTREADY: " + .message)
					else
						(select(.name != null) .name + "=>" + (._links.self.href | split("/"))[-1])
					end
				' <<< "${OutputJSON}" 2>&1
			)
			[[ ${SetObjectReturn:-NOTREADY} =~ "NOTREADY" ]] \
				&& return 1 \
				|| return 0
		;;

		"CREATEENDPOINT")
			# 2/ENDPOINTNAME 3/ENDPOINTTYPE 4/GEOREGIONUUID
			DATASyntax="--data '{\"name\":\""${2}"\",\"endpointType\":\""${3}"\",\"geoRegionId\":\""${4}"\",\"dataCenterId\":null,\"haEndpointType\":null,\"o365BreakoutNextHopIp\":null,\"source\":null,\"syncId\":null}'"
			ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpoints" "202" \
				return 1
			read -d '' -ra SetObjectReturn < <( \
				jq -r '
					if type=="array" then
						(.[] | "NOTREADY: " + .message)
					else
						(select(.registrationKey != null) | .registrationKey + "=>" + (._links.self.href | split("/"))[-1])
					end
				' <<< "${OutputJSON}" 2>&1
			)
			[[ ${SetObjectReturn:-NOTREADY} =~ "NOTREADY" ]] \
				&& return 1 \
				|| return 0
		;;

		"ADD"*"TOENDPOINTGROUP"|"DEL"*"FROMENDPOINTGROUP")
			# 2/NAME=>UUID(s) 3/NAME=>ENDPOINTGROUPUUID
			local SyntaxType SyntaxFlip URLTrail
			local AllUUIDs EndpointGroupUUID
			AllUUIDs=( $(echo "${2}") )
			EndpointGroupUUID="${3##*=>}"

			# Determine what is being added to interact with the API correctly.
			# Only Endpoints are allowed to be added to EndpointGroups.
			case "${1}" in
				"ADD"*"TOENDPOINTGROUP")
					SyntaxFlip="${POSTSyntax_MOP}"
					SyntaxType="ADD"
					[[ ${1} == "ADDENDPOINTTOENDPOINTGROUP" ]] \
						&& URLTrail="endpoints"
				;;
				"DEL"*"FROMENDPOINTGROUP")
					SyntaxFlip="${DELETESyntax_MOP}"
					SyntaxType="DELETE"
					[[ ${1} == "DELENDPOINTFROMENDPOINTGROUP" ]] \
						&& URLTrail="endpoints"
				;;
			esac

			# A multi-scenario.
			if [[ ${#AllUUIDs[*]} -gt 1 ]]; then
				# Begin the syntax.
				DATASyntax="--data '{\"ids\":["
				for ((i=0;i<${#AllUUIDs[*]};i++)); do
					# If at the end of the array, close it up.
					if [[ $((i+1)) -eq ${#AllUUIDs[*]} ]]; then
						DATASyntax="${DATASyntax}\""${AllUUIDs[${i}]##*=>}"\"]}'"
					else
						DATASyntax="${DATASyntax}\""${AllUUIDs[${i}]##*=>}"\","
					fi
				done
			else
				DATASyntax="--data '{\"ids\":[\""${AllUUIDs[*]##*=>}"\"]}'"
			fi

			echo -n 'Waiting for Reply...'
			while true; do
				(for ((i=0;i<3;i++)); do sleep 1 && echo -n '.'; done)
				ProcessResponse "${SyntaxFlip} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/endpointGroups/${EndpointGroupUUID}/${URLTrail}" "202"
				if [[ $? -ne 0 ]] && [[ ${MaxTries} -ge 1 ]]; then
					(( MaxTries-- ))
					echo -n 'R'
				elif [[ $? -ne 0 ]] && [[ ${MaxTries} -lt 1 ]]; then
					echo '.FAILED!'
					return 1
				else
					echo '.SUCCESS!'
					return 0
				fi
			done
		;;

		"ADD"*"TOAPPWAN"|"DEL"*"FROMAPPWAN")
			# 2/NAME=>UUID(s) 3/NAME=>APPWANUUID
			local AllUUIDs=( $(echo "${2}") )
			local AppWANUUID="${3##*=>}"
			local SyntaxType SyntaxFlip URLTrail

			# Determine what is being added to interact with the API correctly.
			# Endpoints and EndpointGroups and Services are allowed to be added to AppWANs.
			case "${1}" in
				"ADDENDPOINTTOAPPWAN")
					SyntaxType="ADD"
					SyntaxFlip="${POSTSyntax_MOP}"
					URLTrail="endpoints"
				;;
				"ADDENDPOINTGROUPTOAPPWAN")
					SyntaxType="ADD"
					SyntaxFlip="${POSTSyntax_MOP}"
					URLTrail="endpointGroups"
				;;
				"ADDSERVICETOAPPWAN")
					SyntaxType="ADD"
					SyntaxFlip="${POSTSyntax_MOP}"
					URLTrail="services"
				;;
				"DELENDPOINTFROMAPPWAN")
					SyntaxType="DELETE"
					SyntaxFlip="${DELETESyntax_MOP}"
					URLTrail="endpoints"
				;;
				"DELENDPOINTGROUPFROMAPPWAN")
					SyntaxType="DELETE"
					SyntaxFlip="${DELETESyntax_MOP}"
					URLTrail="endpointGroups"
				;;
				"DELSERVICEFROMAPPWAN")
					SyntaxType="DELETE"
					SyntaxFlip="${DELETESyntax_MOP}"
					URLTrail="services"
				;;
			esac

			# A multi-scenario.
			if [[ ${#AllUUIDs[*]} -gt 1 ]]; then
				# Begin the syntax.
				DATASyntax="--data '{\"ids\":["
				for ((i=0;i<${#AllUUIDs[*]};i++)); do
					# If at the end of the array, close it up.
					if [[ $((i+1)) -eq ${#AllUUIDs[*]} ]]; then
						DATASyntax="${DATASyntax}\""${AllUUIDs[${i}]##*=>}"\"]}'"
					else
						DATASyntax="${DATASyntax}\""${AllUUIDs[${i}]##*=>}"\","
					fi
				done
			else
				DATASyntax="--data '{\"ids\":[\""${AllUUIDs[*]##*=>}"\"]}'"
			fi

			echo -n 'Waiting for Reply...'
			while true; do
				(for ((i=0;i<3;i++)); do sleep 1 && echo -n '.'; done)
				ProcessResponse "${SyntaxFlip} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/appWans/${AppWANUUID}/${URLTrail}" "202"
				if [[ $? -ne 0 ]] && [[ ${MaxTries} -ge 1 ]]; then
					(( MaxTries-- ))
					echo -n 'R'
				elif [[ $? -ne 0 ]] && [[ ${MaxTries} -lt 1 ]]; then
					echo '.FAILED!'
					return 1
				else
					echo '.SUCCESS!'
					return 0
				fi
			done
		;;

		"CHANGE"*"NAME")
			# 2/OLDNAME=>UUID 3/NEWNAME
			# Determine what is being changed to interact with the API correctly.
			case "${1}" in
				"CHANGEENDPOINTNAME")
					local URLTrail="endpoints/${2##*=>}"
					local ExpectedStatus="202"
					DATASyntax="--data '{\"name\":\""${3}"\"}'"
				;;
				"CHANGEENDPOINTGROUPNAME")
					local URLTrail="endpointGroups/${2##*=>}"
					local ExpectedStatus="200"
					DATASyntax="--data '{\"name\":\""${3}"\"}'"
				;;
				"CHANGEAPPWANNAME")
					local URLTrail="appWans/${2##*=>}"
					local ExpectedStatus="200"
					DATASyntax="--data '{\"name\":\""${3}"\"}'"
				;;
				"CHANGESERVICENAME")
					local URLTrail="services/${2##*=>}"
					local ExpectedStatus="202"
					# The complete JSON object already in existance is required to update the name of a Service.
					ProcessResponse "${GETSyntax_MOP}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail}" "200"
					read -d '' -ra SetObjectReturn < <( \
						jq -r '
							if (.name) then
								(del(._links) | .name = "'${3}'")
							else
								"ERROR - Could not fetch existing JSON object for the Service."
							end
						' <<< "${OutputJSON}" 2>&1
					)
					[[ ${SetObjectReturn:-ERROR} =~ "ERROR" ]] \
						&& return 1
					DATASyntax="--data '"${SetObjectReturn[0]}"'"
				;;
			esac

			ProcessResponse "${PUTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[0]}/networks/${Target_NETWORK[0]}/${URLTrail}" "${ExpectedStatus}" \
				&& return 0 \
				|| return 1
		;;

	esac
}

#################################################################################
# Sets objects using the API (V7).
function SetObjects_MOP_V7() {
	# 1/TYPE 2-10/[DATAFIELDS]
	local SetType="${1}"
	local MaxTries="10" # MACD max attempts.
	local DATASyntax # The syntax to send to API.
	unset SetObjectReturn # Ensure this is not already set.

	# Set what type of object?
	case ${SetType} in

		"EMAILALERT")
			# 2/ENDPOINTUUID 3/EMAILADDRESS 4/MESSAGE
			DATASyntax="--data '[{\"toList\":[\"${3}\"],\"subject\":\"NetFoundry - Enrollment Information\",\"id\":\"${2}\",\"from\":\"no-reply@netfoundry.io\",\"replacementParams\":{\"NETWORKNAME\":\"${Target_NETWORK[1]}<br>INFO: ${4:-NONE}\"}}]'"

			if ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[1]}/endpoints/share" "202"; then
				return 0
			else
				SetObjectReturn="${OutputJSON}"
				return 1
			fi
		;;	

		"CREATEENDPOINT")
			# 2/ENDPOINTNAME 3/ENDPOINTTYPE 4/GEOREGIONUUID
			DATASyntax="--data '{\"networkId\":\"${Target_NETWORK[0]}\",\"name\":\"${2}\",\"enrollmentMethod\":{\"ott\":true,\"updb\":null,\"ottca\":null},\"attributes\":null}'"
			! ProcessResponse "${POSTSyntax_MOP} ${DATASyntax}" "${APIRESTURL[1]}/endpoints" "200" \
				&& return 1
			read -d '' -ra SetObjectReturn < <( \
				jq -r '
					if type=="array" then
						(.[] | "NOTREADY: " + .message)
					else
						(select(.jwt != null) | .jwt + "=>" + (._links.self.href | split("/"))[-1])
					end
				' <<< "${OutputJSON}" 2>&1
			)
			[[ ${SetObjectReturn:-NOTREADY} =~ "NOTREADY" ]] \
				&& return 1 \
				|| return 0
		;;

	esac
}

#################################################################################
# Select and store available networks.
function SelectOrganization() {
	CurrentPath="/SelectOrganization"

	# Auto select the Organization if there is only one.
	if [[ ${#AllOrganizations[*]} -eq 1 ]]; then

		AttentionMessage "GREENINFO" "Auto-selecting singular Organization found \"${AllOrganizations[0]}\"."
		Target_ORGANIZATION[0]="${AllOrganizations[0]##*=>}"
		Target_ORGANIZATION[1]="${AllOrganizations[0]%%=>*}"
		return 0

	else

		! GetSelection "Which Organization do you wish to work within?" "${AllOrganizations[*]}" "NONE" \
			&& GoToExit "0"
		Target_ORGANIZATION[0]="${UserResponse##*=>}"
		Target_ORGANIZATION[1]="${UserResponse%%=>*}"
		return 0

	fi

	return 0
}

#################################################################################
# Select and store available networks.
function SelectNetwork() {
	function ControllerLogin_V7() {
		if GetObjects_V7C "NETWORKMETADATA_V7C" 2>/dev/null; then
			ClearLines "1"
			AttentionMessage "GENERALINFO" "Successfully obtained the Network Controller metadata for \"${Target_NETWORK[1]}\"."
			AttentionMessage "DEBUG" "The following is highly sensitive. DO NOT STORE THIS CONTEXT."
			AttentionMessage "DEBUG" "Console  (NAME)    = ${Target_NETWORK[1]}"
			AttentionMessage "DEBUG" "Console  (UUID)    = ${Target_NETWORK[0]}"
			AttentionMessage "DEBUG" "Access   (ZTUSER)  = ${NetworkAccess_V7C[1]}"
			AttentionMessage "DEBUG" "Access   (ZTPASS)  = ${NetworkAccess_V7C[2]}"
			AttentionMessage "DEBUG" "Metadata (IP)      = ${NetworkMetadata_V7C[0]%%=>*}"
			AttentionMessage "DEBUG" "Metadata (SESSION) = ${NetworkMetadata_V7C[0]##*=>}"
			AttentionMessage "DEBUG" "Metadata (VERSION) = ${NetworkMetadata_V7C[1]}"
			AttentionMessage "DEBUG" "Metadata (CACERT)  = SEE BELOW FOR PEM FORMAT CERTIFICATE."
			[[ ${DebugInfo} == "TRUE" ]] \
				&& echo "${NetworkMetadata_V7C[2]}"
			return 0
		else
			ClearLines "1"
			AttentionMessage "ERROR" "Unsuccessful attempt to obtain the Network Controller metadata."
			AttentionMessage "ERROR" "This could mean that the Network Controller API interface is unavailable or your CONSOLE BEARER TOKEN lacks permissions."
			GetYorN "SPECIAL-PAUSE"
			return 1
		fi
	}

	CurrentPath="/${Target_ORGANIZATION[1]}/SelectNetwork"

	# Conglomerate all the networks together.
	AllNetworks=( ${AllV6Networks[*]} ${AllNetworks_V7[*]} )

	# Auto select the Network if there is only one.
	if [[ ${#AllV6Networks[*]} -eq 1 ]] && [[ ${#AllNetworks_V7[*]} -eq 0 ]]; then

		AttentionMessage "GREENINFO" "Auto-selecting singular V6 Network found \"${AllV6Networks[0]}\"."
		Target_NETWORK[0]="${AllV6Networks[0]##*=>}"
		Target_NETWORK[1]="${AllV6Networks[0]%%=>*}"
		return 0

	elif [[ ${#AllV6Networks[*]} -eq 0 ]] && [[ ${#AllNetworks_V7[*]} -eq 1 ]]; then

		AttentionMessage "GREENINFO" "Auto-selecting singular V7 Network found \"${AllNetworks_V7[0]}\"."
		Target_NETWORK[0]="${AllNetworks_V7[0]##*=>}" # Name.
		Target_NETWORK[1]="${AllNetworks_V7[0]%%=>*}" # UUID.

		# Logout of any existing systems if active.
		SetObjects_V7C "LOGOUT"
		# Collect the API information required to interact directly with this V7 Controller.
		AttentionMessage "GENERALINFO" "Attempting to contact the Network Controller."
		# Login to the requested system.
		ControllerLogin_V7 \
			&& return 0 \
			|| return 1

	else

		! GetSelection "Which Network do you wish to work within?" "${AllNetworks[*]}" "NONE" \
			&& return 1
		Target_NETWORK[0]="${UserResponse##*=>}"
		Target_NETWORK[1]="${UserResponse%%=>*}"

		if [[ ${Target_NETWORK[1]} =~ ^"(V7)" ]]; then
			# Logout of any existing systems if active.
			SetObjects_V7C "LOGOUT"
			# Collect the API information required to interact directly with this V7 Controller.
			AttentionMessage "GENERALINFO" "Attempting to contact the Network Controller."
			# Login to the requested system.
			ControllerLogin_V7 \
				&& return 0 \
				|| return 1
		else
			return 0
		fi

	fi

	return 0
}

#################################################################################
# Create an AppWAN using the API.
function CreateAppWAN() {
	local Target_APPWANNAME
	CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/CreateAppWAN"

	# Ask the user for a name.
	! GetObjectName "for the new AppWAN" \
		&& return 0

	Target_APPWANNAME="${UserResponse}"

	AttentionMessage "WARNING" "You are about to create a new AppWAN named \"${Target_APPWANNAME}\" in Network \"${Target_NETWORK[1]}\"."
	GetYorN "Ready?" "No" \
		|| return 0

	AttentionMessage "GENERALINFO" "Creating AppWAN \"${Target_APPWANNAME}\"."
	SetObjects_MOP_V6 "CREATEAPPWAN" "${Target_APPWANNAME}" \
		&& AttentionMessage "VALIDATED" "Request to create AppWAN is complete." \
		|| (AttentionMessage "ERROR" "FAILED! Request to create AppWAN. See message below." \
			&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
}

#################################################################################
# Create an EndpointGroup using the API.
function CreateEndpointGroup() {
	local Target_ENDPOINTGROUPNAME
	CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/CreateEndpointGroup"

	# Ask the user for a name.
	! GetObjectName "for the new EndpointGroup" \
		&& return 0

	Target_ENDPOINTGROUPNAME="${UserResponse}"

	AttentionMessage "WARNING" "You are about to create a new EndpointGroup named \"${Target_ENDPOINTGROUPNAME}\" in Network \"${Target_NETWORK[1]}\"."
	GetYorN "Ready?" "No" \
		|| return 0

	AttentionMessage "GENERALINFO" "Creating EndpointGroup \"${Target_ENDPOINTGROUPNAME}\"."
	SetObjects_MOP_V6 "CREATEENDPOINTGROUP" "${Target_ENDPOINTGROUPNAME}" \
		&& AttentionMessage "VALIDATED" "Request to create EndpointGroup is complete." \
		|| (AttentionMessage "ERROR" "FAILED! Request to create EndpointGroup. See message below." \
			&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
}

#################################################################################
# Create Internet Services using the API.
function CreateInternetServices() {
	local i ShortID FullName GatewayIP InterceptIP InterceptCIDR ServicesAddedArray Target_APPWANNAME
	local AllInternetServices=(
		0.0.0.0/5 8.0.0.0/7 11.0.0.0/8 12.0.0.0/6 16.0.0.0/4
		32.0.0.0/3 64.0.0.0/3 96.0.0.0/4 112.0.0.0/5 120.0.0.0/6
		126.0.0.0/8 128.0.0.0/3 160.0.0.0/5 168.0.0.0/6 172.0.0.0/12
		172.32.0.0/11 172.64.0.0/10 172.128.0.0/9 173.0.0.0/8 174.0.0.0/7
		176.0.0.0/4 192.0.0.0/9 192.128.0.0/11 192.160.0.0/13 192.169.0.0/16
		192.170.0.0/15 192.172.0.0/14 192.176.0.0/12 192.192.0.0/10 193.0.0.0/8
		194.0.0.0/7 196.0.0.0/6 200.0.0.0/5 208.0.0.0/4 224.0.0.0/3
	) # All Internet NETWORK/CIDR combinations which avoid RFC1918 private spaces.

	# Ask the user which Gateway.
	AttentionMessage "GENERALINFO" "Fetching all Gateway Endpoints in Network \"${Target_NETWORK[1]}\"."
	GetObjects_MOP "GATEWAYS" &>/dev/null

	# The user needs to select a Gateway within the Network to target.
	! GetSelection "Select the target Gateway Endpoint for this operation." "${AllGateways[*]}" "NONE" \
		&& return 0
	# NAME=>TYPE-UUID
	Target_GATEWAY[0]="${UserResponse##*=>}" # UUID.
	Target_GATEWAY[1]="${UserResponse%%=>*}" # NAME.
	# Random name.
	ShortID="Group-${RANDOM}"
	Target_APPWANNAME[0]="Internet Proxy ${ShortID}"

	# Tell the user what Services are currently associated to the Gateway they targeted.
	PrimaryFilterString="${Target_GATEWAY[0]#*\-}"
	AttentionMessage "GREENINFO" "The following is a list of Services and associated Endpoints with \"${Target_GATEWAY[1]}\" in Network \"${Target_NETWORK[1]}\"."
	GetObjects_MOP "SERVICES" "FOLLOW-ENDPOINTS"

	AttentionMessage "WARNING" "You are about to create (${#AllInternetServices[*]}) new Services associated to Gateway Endpoint \"${Target_GATEWAY[1]}\" in Network \"${Target_NETWORK[1]}\"."
	AttentionMessage "WARNING" "This process will also add a new AppWAN named \"${Target_APPWANNAME[0]}\" and associate the new Services to it."
	GetYorN "Ready?" "No" \
		|| return 0

	# First, create the AppWAN the Services will reside in.
	AttentionMessage "GREENINFO" "Creating AppWAN \"${Target_APPWANNAME[0]}\"."
	if SetObjects_MOP_V6 "CREATEAPPWAN" "${Target_APPWANNAME[0]}"; then
		Target_APPWANNAME[1]="${SetObjectReturn##*=>}" # The UUID of the AppWAN.
	else
		AttentionMessage "ERROR" "FAILED! Request to create AppWAN \"${Target_APPWANNAME[0]}\" did not complete. See message below."
		echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
		AttentionMessage "REDINFO" "Cannot continue further, thus no Services were created."
		return 1
	fi

	# Next, create each network/CIDR listed in the AllInternetServices array.
	for ((i=0;i<${#AllInternetServices[*]};i++)); do
		FullName="${Target_APPWANNAME[0]} ${AlphaArray[$((i/${#AlphaArray[*]}))]}${AlphaArray[$((i%${#AlphaArray[*]}))]}" # Internet Proxy Group-XXXX [A-Z][A-Z]
		GatewayIP="${AllInternetServices[${i}]%%\/*}" # WWW.XXX.YYY.ZZZ
		InterceptIP="${AllInternetServices[${i}]%%\/*}" # WWW.XXX.YYY.ZZZ
		InterceptCIDR="${AllInternetServices[${i}]##*\/}" # [1-32]
		AttentionMessage "GREENINFO" "[$((i+1))/${#AllInternetServices[*]}] Adding Service \"${FullName}\". [INGRESS > EGRESS : ${InterceptIP}/${InterceptCIDR} > ${GatewayIP}/${InterceptCIDR}]"
		if SetObjects_MOP_V6 "CREATENETSERVICE" "${Target_GATEWAY[0]}" "${FullName}" "${InterceptIP}" "${GatewayIP}" "${InterceptCIDR}"; then
			ServicesAddedArray=( "${SetObjectReturn##*=>}" ${ServicesAddedArray[*]} )
		else
			AttentionMessage "ERROR" "FAILED! Request to add Internet Service \"${FullName}\" to Gateway Endpoint \"${Target_GATEWAY[1]}\" did not complete. See message below."
			echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
		fi
	done

	# Validation checkpoint.
	if [[ ${#ServicesAddedArray[*]} -eq ${#AllInternetServices[*]} ]]; then
		AttentionMessage "VALIDATED" "Request to create all (${#AllInternetServices[*]}) Internet Services associated to \"${Target_GATEWAY[1]}\" is complete."
	else
		AttentionMessage "REDINFO" "Failed to create and associate all (${#AllInternetServices[*]}) Internet Services to Gateway Endpoint \"${Target_GATEWAY[1]}\"."
		AttentionMessage "REDINFO" "Cannot continue further, thus no Services were associated to the AppWAN created for this process."
		return 1
	fi

	# Finally, associate all Services to the AppWAN.
	AttentionMessage "GREENINFO" "Associating all (${#AllInternetServices[*]}) Internet Services to AppWAN \"${Target_APPWANNAME[0]}\"."
	if SetObjects_MOP_V6 "ADDSERVICETOAPPWAN" "${ServicesAddedArray[*]}" "${Target_APPWANNAME[1]}"; then
		AttentionMessage "VALIDATED" "Successfully associated (${#AllInternetServices[*]}) Internet Services to AppWAN \"${Target_APPWANNAME[0]}\"."
		return 0
	else
		AttentionMessage "ERROR" "FAILED! Request to associate all (${#AllInternetServices[*]}) Internet Services to AppWAN \"${Target_APPWANNAME[0]}\" did not complete. See message below."
		echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
		AttentionMessage "REDINFO" "Cannot continue further, thus no Services were associated to the AppWAN of this process."
		return 1
	fi

	# Error.
	return 1
}

#################################################################################
# Rename an object using the API.
# 1/OBJECTTYPE 2/NAME=>UUID
function ChangeObjectName() {
	# 1/TYPE 2/OLDNAMEUUID
	local Target_OBJECTTYPE="${1}"
	local Target_OBJECTOLD="${2}"

	# The menu will loop around.
	while true; do

			# The user needs to re-name the object.
			! GetObjectName "for re-naming existing ${Target_OBJECTTYPE} currently named \"${Target_OBJECTOLD%%=>*}\"" \
				&& return 0
			Target_OBJECTNEW="${UserResponse}"

			AttentionMessage "GREENINFO" "Re-naming ${Target_OBJECTTYPE} \"${Target_OBJECTOLD%%=>*}\" to \"${Target_OBJECTNEW}\"."
			! SetObjects_MOP_V6 "CHANGE${Target_OBJECTTYPE}NAME" "${Target_OBJECTOLD}" "${Target_OBJECTNEW}" \
				&& AttentionMessage "ERROR" "Re-naming of object failed. Object remains unchanged." \
				&& echo "MESSSAGE: \"${SetObjectReturn:-NO MESSAGE RETURNED}\"." \
				|| AttentionMessage "VALIDATED" "Re-naming was successful."
			break

	done
}

#################################################################################
# Modify existing Endpoint associations using the API.
# 1/TYPE[APPWAN|ENDPOINTGROUP] 2/NAME=>UUID
function ModifyEndpointAssociations() {
	local i j Target_ASSOCIATION
	Target_ASSOCIATION[1]="${1}"
	Target_ASSOCIATION[2]="${2}"
	CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ModifyEndpointAssociations"

	# Fill the selectornetwork array with all matching endpoints (/endpointgroups). This array will be static.
	if [[ ${Target_ASSOCIATION[1]} == "ENDPOINTGROUP" ]]; then
		PrimaryFilterString='.' # Select all.
		! GetFilterString "Narrow the Endpoints for modification selection." \
			&& return 0
		AttentionMessage "GENERALINFO" "Fetching list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTS" &>/dev/null
		EndpointSelectorNetwork=( ${AllEndpoints[*]/???:::/} )
	elif [[ ${Target_ASSOCIATION[1]} == "APPWAN" ]]; then
		PrimaryFilterString='.' # Select all.
		! GetFilterString "Narrow the Endpoints for modification selection." \
			&& return 0
		AttentionMessage "GENERALINFO" "Fetching list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTS" &>/dev/null
		PrimaryFilterString='.' # Select all.
		! GetFilterString "Narrow the EndpointGroups for modification selection." \
			&& return 0
		AttentionMessage "GENERALINFO" "Fetching list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTGROUPS" &>/dev/null
		EndpointSelectorNetwork=( ${AllEndpoints[*]/???:::/} ${AllEndpointGroups[*]/#/GROUP:::} )
	fi

	# Fill the selectorgroup array with all currently associated endpoints (/endpointgroups). This array will be static.
	# Fill the selectortoggle array with the same context above and append "ASSOCIATED" to them. This array will be changable.
	PrimaryFilterString='.' # All Endpoints are required, so clear the filter.
	if [[ ${Target_ASSOCIATION[1]} == "ENDPOINTGROUP" ]]; then
		AttentionMessage "GENERALINFO" "Fetching all Endpoints associated to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTS" "endpointGroups/${Target_ASSOCIATION[2]##*=>}/endpoints" &>/dev/null
		EndpointSelectorGroup=( ${AllEndpoints[*]/???:::/} )
		EndpointSelectorToggle=( ${EndpointSelectorGroup[*]/#/ASSOCIATED:::} )
		CurrentPath="${CurrentPath}/EndpointGroups/${Target_ASSOCIATION[2]%%=>*}"
	elif [[ ${Target_ASSOCIATION[1]} == "APPWAN" ]]; then
		AttentionMessage "GENERALINFO" "Fetching all Endpoints associated to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTS" "appWans/${Target_ASSOCIATION[2]##*=>}/endpoints" &>/dev/null
		AttentionMessage "GENERALINFO" "Fetching all EndpointGroups associated to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTGROUPS" "appWans/${Target_ASSOCIATION[2]##*=>}/endpointGroups" &>/dev/null
		EndpointSelectorGroup=( ${AllEndpoints[*]/???:::/} ${AllEndpointGroups[*]/#/GROUP:::} )
		EndpointSelectorToggle=( ${EndpointSelectorGroup[*]/#/ASSOCIATED:::} )
		CurrentPath="${CurrentPath}/AppWANs/${Target_ASSOCIATION[2]%%=>*}"
	fi

	# Add Endpoints which are not part of the association (now in toggle array).
	for ((i=0;i<${#EndpointSelectorNetwork[*]};i++)); do
		# A special condition where there are no current associations.
		if [[ ${#EndpointSelectorGroup[*]} -eq 0 ]]; then
			# Every Endpoint/Group in the system is currently not associated.
			EndpointSelectorToggle=( ${EndpointSelectorToggle[*]} "NOTASSOCIATED:::${EndpointSelectorNetwork[${i}]}" )
		else
			# Match every Endpoint/Group in the system against what is already in the toggle array.
			for ((j=0;j<${#EndpointSelectorGroup[*]};j++)); do
				# This Endpoint/Group was found in the system array - skip it.
				if [[ "${EndpointSelectorNetwork[${i}]}" == "${EndpointSelectorGroup[${j}]}" ]]; then
					break
				# Signals the end of the toggle array, thus no match - add and change the header of the Endpoint (NOTASSOCIATED:::ZZZ).
				elif [[ $((j+1)) -eq ${#EndpointSelectorGroup[*]} ]]; then
					EndpointSelectorToggle=( ${EndpointSelectorToggle[*]} "NOTASSOCIATED:::${EndpointSelectorNetwork[${i}]}" )
				fi
			done
		fi
	done

	EndpointSelectorToggle=( "SUBMIT" "ADD-ALL-NOTASSOCIATED" "DELETE-ALL-ASSOCIATED" "ADD-ALL" "DELETE-ALL" "INVERT" ${EndpointSelectorToggle[*]} )
	# The menu will loop around.
	while true; do

		if [[ ${Target_ASSOCIATION[1]} == "ENDPOINTGROUP" ]]; then
			! GetSelection "Toggle the Endpoints into the desired states. Select 3/SUBMIT when done." "${EndpointSelectorToggle[*]}" "NONE" \
				&& return 0
		elif [[ ${Target_ASSOCIATION[1]} == "APPWAN" ]]; then
			! GetSelection "Toggle the Endpoints and EndpointGroups into the desired states. Select 3/SUBMIT when done." "${EndpointSelectorToggle[*]}" "NONE" \
				&& return 0
		fi

		Target_ENDPOINT=( "${UserResponse}" )
		if [[ ${UserResponse} == "BACK" ]]; then

			unset Target_ASSOCIATION EndpointSelectorGroup EndpointSelectorToggle AllEndpointsAddition AllEndpointGroupsAddition AllEndpointsDeletion AllEndpointGroupsDeletion
			return 0

		elif [[ ${UserResponse} == "SUBMIT" ]]; then
			# Clear the working arrays.
			unset AllEndpointsAddition AllEndpointGroupsAddition AllEndpointsDeletion AllEndpointGroupsDeletion

			# Move all Endpoints into their respective arrays.
			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case ${EndpointSelectorToggle[${i}]} in
					$"ADDITION:::GROUP:::"*)
						AllEndpointGroupsAddition=( "${EndpointSelectorToggle[${i}]//ADDITION:::/}" ${AllEndpointGroupsAddition[*]} )
					;;
					$"DELETION:::GROUP"*)
						AllEndpointGroupsDeletion=( "${EndpointSelectorToggle[${i}]//DELETION:::/}" ${AllEndpointGroupsDeletion[*]} )
					;;
					$"ADDITION:::"*)
						AllEndpointsAddition=( "${EndpointSelectorToggle[${i}]//ADDITION:::/}" ${AllEndpointsAddition[*]} )
					;;
					$"DELETION:::"*)
						AllEndpointsDeletion=( "${EndpointSelectorToggle[${i}]//DELETION:::/}" ${AllEndpointsDeletion[*]} )
					;;
				esac
			done

			([[ ${#AllEndpointGroupsAddition[*]} -eq 0 ]] && [[ ${#AllEndpointGroupsDeletion[*]} -eq 0 ]]) \
				&& ([[ ${#AllEndpointsAddition[*]} -eq 0 ]] && [[ ${#AllEndpointsDeletion[*]} -eq 0 ]]) \
					&& AttentionMessage "ERROR" "Nothing was selected for modification, try again." \
					&& sleep 3 \
					&& continue
			[[ ${#AllEndpointGroupsAddition[*]} -gt 0 ]] \
				&& AttentionMessage "GREENINFO" "The following EndpointGroups will be added to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"." \
				&& echo "${AllEndpointGroupsAddition[*]}"
			[[ ${#AllEndpointGroupsDeletion[*]} -gt 0 ]] \
				&& AttentionMessage "REDINFO" "The following EndpointGroups will be deleted from ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"." \
				&& echo "${AllEndpointGroupsDeletion[*]}"
			[[ ${#AllEndpointsAddition[*]} -gt 0 ]] \
				&& AttentionMessage "GREENINFO" "The following Endpoints will be added to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"." \
				&& echo "${AllEndpointsAddition[*]}"
			[[ ${#AllEndpointsDeletion[*]} -gt 0 ]] \
				&& AttentionMessage "REDINFO" "The following Endpoints will be deleted from ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\" in Network \"${Target_NETWORK[1]}\"." \
				&& echo "${AllEndpointsDeletion[*]}"

			# Take no action, yet save their current settings by simply looping back, if the user is not ready.
			if GetYorN "Ready?" "No"; then
				if [[ ${#AllEndpointGroupsAddition[*]} -gt 0 ]]; then
					AttentionMessage "GREENINFO" "Adding selected EndpointGroups to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\"."
					SetObjects_MOP_V6 "ADDENDPOINTGROUPTO${Target_ASSOCIATION[1]}" "${AllEndpointGroupsAddition[*]}" "${Target_ASSOCIATION[2]}" \
						&& AttentionMessage "VALIDATED" "Request to add EndpointGroup(s) is complete. Actual changes may still be underway." \
						|| (AttentionMessage "ERROR" "FAILED! Request to add EndpointGroup(s) did not complete. See message below." \
							&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
				fi
				if [[ ${#AllEndpointGroupsDeletion[*]} -gt 0 ]]; then
					AttentionMessage "GREENINFO" "Deleting selected EndpointGroups from ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\"."
					SetObjects_MOP_V6 "DELENDPOINTGROUPFROM${Target_ASSOCIATION[1]}" "${AllEndpointGroupsDeletion[*]}" "${Target_ASSOCIATION[2]}" \
					&& AttentionMessage "VALIDATED" "Request to delete EndpointGroup(s) is complete. Actual changes may still be underway." \
						|| (AttentionMessage "ERROR" "FAILED! Request to delete EndpointGroup(s) did not complete. See message below." \
							&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
				fi
				if [[ ${#AllEndpointsAddition[*]} -gt 0 ]]; then
					AttentionMessage "GREENINFO" "Adding selected Endpoints to ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\"."
					SetObjects_MOP_V6 "ADDENDPOINTTO${Target_ASSOCIATION[1]}" "${AllEndpointsAddition[*]}" "${Target_ASSOCIATION[2]}" \
						&& AttentionMessage "VALIDATED" "Request to add Endpoint(s) is complete. Actual changes may still be underway." \
						|| (AttentionMessage "ERROR" "FAILED! Request to add Endpoint(s) did not complete. See message below." \
							&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
				fi
				if [[ ${#AllEndpointsDeletion[*]} -gt 0 ]]; then
					AttentionMessage "GREENINFO" "Deleting selected Endpoints from ${Target_ASSOCIATION[1]} \"${Target_ASSOCIATION[2]%%=>*}\"."
					SetObjects_MOP_V6 "DELENDPOINTFROM${Target_ASSOCIATION[1]}" "${AllEndpointsDeletion[*]}" "${Target_ASSOCIATION[2]}" \
					&& AttentionMessage "VALIDATED" "Request to delete Endpoint(s) is complete. Actual changes may still be underway." \
						|| (AttentionMessage "ERROR" "FAILED! Request to delete Endpoint(s) did not complete. See message below." \
							&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}")
				fi
			else
				continue
			fi

			unset Target_ASSOCIATION EndpointSelectorGroup EndpointSelectorToggle AllEndpointsAddition AllEndpointsDeletion
			return 0

		elif [[ ${UserResponse} == "ADD-ALL-NOTASSOCIATED" ]]; then

			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case "${EndpointSelectorToggle[${i}]%%:::*}" in
					"NOTASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/NOTASSOCIATED/ADDITION}} )
					;;
				esac
			done

		elif [[ ${UserResponse} == "DELETE-ALL-ASSOCIATED" ]]; then

			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case "${EndpointSelectorToggle[${i}]%%:::*}" in
					"ASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/ASSOCIATED/DELETION}} )
					;;
				esac
			done

		elif [[ ${UserResponse} == "ADD-ALL" ]]; then

			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case "${EndpointSelectorToggle[${i}]%%:::*}" in
					"NOTASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/NOTASSOCIATED/ADDITION}} )
					;;
					"DELETION")
						# Currently associated Endpoint, deleted in this session, targeted to be added to this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/DELETION/ASSOCIATED}} )
					;;
				esac
			done

		elif [[ ${UserResponse} == "DELETE-ALL" ]]; then

			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case "${EndpointSelectorToggle[${i}]%%:::*}" in
					"ASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/ASSOCIATED/DELETION}} )
					;;
					"ADDITION")
						# Currently associated Endpoint, deleted in this session, targeted to be removed from this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/ADDITION/NOTASSOCIATED}} )
					;;
				esac
			done

		elif [[ ${UserResponse} == "INVERT" ]]; then

			for ((i=0;i<${#EndpointSelectorToggle[*]};i++)); do
				case "${EndpointSelectorToggle[${i}]%%:::*}" in
					"NOTASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/NOTASSOCIATED/ADDITION}} )
					;;
					"DELETION")
						# Currently associated Endpoint, deleted in this session, targeted to be added to this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/DELETION/ASSOCIATED}} )
					;;
					"ASSOCIATED")
						# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/ASSOCIATED/DELETION}} )
					;;
					"ADDITION")
						# Currently associated Endpoint, deleted in this session, targeted to be removed from this EndpointGroup/AppWAN.
						EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${EndpointSelectorToggle[${i}]}/${EndpointSelectorToggle[${i}]/ADDITION/NOTASSOCIATED}} )
					;;
				esac
			done

		else

			case "${UserResponse%%:::*}" in
				"ASSOCIATED")
					# Currently associated Endpoint targeted to be removed from this EndpointGroup/AppWAN.
					EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${UserResponse}/${UserResponse/ASSOCIATED/DELETION}} )
				;;
				"NOTASSOCIATED")
					# Currently un-associated Endpoint targeted to be added this EndpointGroup/AppWAN.
					EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${UserResponse}/${UserResponse/NOTASSOCIATED/ADDITION}} )
				;;
				"ADDITION")
					# Currently un-associated Endpoint, added in this session, targeted to be removed from this EndpointGroup/AppWAN.
					EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${UserResponse}/${UserResponse/ADDITION/NOTASSOCIATED}} )
				;;
				"DELETION")
					# Currently associated Endpoint, deleted in this session, targeted to be added to this EndpointGroup/AppWAN.
					EndpointSelectorToggle=( ${EndpointSelectorToggle[*]/${UserResponse}/${UserResponse/DELETION/ASSOCIATED}} )
				;;
			esac

		fi

	done
}

#################################################################################
# Delete existing Endpoints.
function DeleteEndpoints() {
	local i

	# The menu will loop around.
	while true; do

		# Ask the user which Endpoint.
		FilterString='.'
		AttentionMessage "GENERALINFO" "Fetching all Endpoints in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTS" &>/dev/null
		AllEndpoints=( ${AllEndpoints[*]/???:::/} )
		# The user needs to select an Endpoint within the Network to target.
		! GetSelection "Select the target Endpoint to delete." "${AllEndpoints[*]}" "NONE" \
			&& return 0
		# NAME=>TYPE-UUID
		Target_ENDPOINT[0]="${UserResponse%%=>*}" # TYPE:::NAME
		Target_ENDPOINT[1]="${UserResponse##*=>}" # UUID

		AttentionMessage "GENERALINFO" "Validating if Endpoint \"${Target_ENDPOINT[0]}\" is allowed deletion in Network \"${Target_NETWORK[1]}\". Just a moment..."
		FilterString='*=>'"${Target_ENDPOINT[1]}"'' # Hard filter for this UUID.
		GetObjects_MOP "SERVICES" "endpoints/${Target_ENDPOINT[1]}/services" &>/dev/null
		if [[ $? -eq 0 ]]; then
			AttentionMessage "ERROR" "The Endpoint \"${Target_ENDPOINT[0]}\" is NOT allowed deletion in Network \"${Target_NETWORK[1]}\" due to the following associated Services."
			echo "${AllServices[*]}"
			sleep 5
			continue
		else
			AttentionMessage "VALIDATED" "The Endpoint \"${Target_ENDPOINT[0]}\" is allowed deletion in Network \"${Target_NETWORK[1]}\"."
		fi

		AttentionMessage "WARNING" "You are about to delete Endpoint \"${Target_ENDPOINT[0]}\" from Network \"${Target_NETWORK[1]}\"."
		GetYorN "Ready?" "No" \
			|| return 0

		SetObjects_MOP_V6 "DELENDPOINT" "${Target_ENDPOINT[1]}"
		if [[ $? -eq 0 ]]; then
			AttentionMessage "GREENINFO" "Endpoint \"${Target_ENDPOINT[0]}\" has been deleted."
			return 0
		else
			AttentionMessage "ERROR" "Endpoint deletion failed. Endpoint remains available."
			echo "MESSAGE: \"${SetObjectReturn:-NO MESSAGE RETURNED}\"."
			sleep 5
			return 1
		fi

done
}

#################################################################################
# Delete existing EndpointGroups.
function DeleteEndpointGroups() {
	local i

	# The menu will loop around.
	while true; do

		# Ask the user which EndpointGroup.
		FilterString='.'
		AttentionMessage "GENERALINFO" "Fetching all EndpointGroups in Network \"${Target_NETWORK[1]}\"."
		GetObjects_MOP "ENDPOINTGROUPS" &>/dev/null
		AllEndpointGroups=( ${AllEndpointGroups[*]/???:::/} )
		# The user needs to select an EndpointGroup within the Network to target.
		! GetSelection "Select the target EndpointGroup to delete." "${AllEndpointGroups[*]}" "NONE" \
			&& return 0
		# NAME=>TYPE-UUID
		Target_ENDPOINTGROUP[0]="${UserResponse%%=>*}" # TYPE:::NAME
		Target_ENDPOINTGROUP[1]="${UserResponse##*=>}" # UUID

		AttentionMessage "WARNING" "You are about to delete EndpointGroup \"${Target_ENDPOINTGROUP[0]}\" from Network \"${Target_NETWORK[1]}\"."
		GetYorN "Ready?" "No" \
			|| return 0

		SetObjects_MOP_V6 "DELENDPOINTGROUP" "${Target_ENDPOINTGROUP[1]}"
		if [[ $? -eq 0 ]]; then
			AttentionMessage "GREENINFO" "EndpointGroup \"${Target_ENDPOINTGROUP[0]}\" has been deleted."
			return 0
		else
			AttentionMessage "ERROR" "EndpointGroup deletion failed. EndpointGroup remains available."
			echo "MESSAGE: \"${SetObjectReturn:-NO MESSAGE RETURNED}\"."
			sleep 5
			return 1
		fi

done
}

#################################################################################
# Create new endpoints in bulk from file.
function BulkCreateEndpoints() {

	function AttemptEmail() {
		# Common context.
		local Target_CONTEXT
		Target_CONTEXT="$(date +'%s'),${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION},${EndpointGroupState},${AppWANState}"

		if [[ ${Target_EMAIL[0]} != "NOEMAIL" ]]; then

			# Alerting.
			AttentionMessage "GREENINFO" " ┣━Now attempting Email alert to \"${Target_EMAIL[0]}\"."

			if [[ ${Target_EMAIL[0]} =~ "@" ]]; then

				if ! SetObjects_MOP_V6 "EMAILALERT" "${StoredAttributes[0]:-ERRNOUUID}" "${Target_EMAIL[0]}" "${Target_EMAIL[1]}"; then

					(( OutputCounter[5]++ ))
					AttentionMessage "ERROR" " ┗━━Email alert transmission failed. Endpoint remains available."
					echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
					echo "${Target_CONTEXT},${StoredAttributes[0]:-UUID_NA},${StoredAttributes[1]:-REGKEY:NA},FAIL:${Target_EMAIL[0]}" >> ${OutputFile}

				else

					(( OutputCounter[4]++ ))
					AttentionMessage "VALIDATED" " ┗━━Email alert transmission succeeded with registration information and message \"${Target_EMAIL[1]:0:75}\"."
					echo "${Target_CONTEXT},${StoredAttributes[0]:-UUID_NA},${StoredAttributes[1]:-REGKEY:NA},SENT:${Target_EMAIL[0]}" >> ${OutputFile}

				fi

			else

				(( OutputCounter[5]++ ))
				AttentionMessage "ERROR" " ┗━━Email alert transmission failed due to badly formed address. Endpoint remains available."
				echo "${Target_CONTEXT},${StoredAttributes[0]:-UUID_NA},${StoredAttributes[1]:-REGKEY:NA},BADEMAIL:${Target_EMAIL[0]}" >> ${OutputFile}

			fi

		else

			AttentionMessage "GREENINFO" " ┗━━Email alert not required."
			echo "${Target_CONTEXT},${StoredAttributes[0]:-UUID_NA},${StoredAttributes[1]:-REGKEY:NA},NOEMAIL" >> ${OutputFile}

		fi
	}

	function DeconstructLine() {
		local ThisMode="${1}" #

		if [[ ${ThisMode} == "INIT" ]]; then

			# 0/COMPLETECOUNT 1/ALLCOUNT 2/PASSCOUNT 3/FAILCOUNT 4/EMAILSENT 5/EMAILFAIL 6/PASSEPG 7/FAILEPG 8/PASSAPW 9/FAILAPW
			OutputCounter=( "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" )
			AppWANState=''
			EndpointGroupState=''
			BulkExportVar="# ${CSVHeader[0]},${CSVHeader[1]},${CSVHeader[2]},${CSVHeader[3]},${CSVHeader[4]},${CSVHeader[5]},${CSVHeader[6]},${CSVHeader[7]}"
			return 0

		elif [[ ${ThisMode} == "PARSE" ]] || [[ ${ThisMode} == "PARSECHECKONLY" ]]; then

			# Deconstruction of the line.
			IFS=',' # Lists are comma delimited arrays.
			(( OutputCounter[0]++ )) # Count for every line.
			EachLine=( ${InputLine} ) # Insert into array.
			Target_ENDPOINTNAME="${EachLine[0]:-MISSINGNAME}" # Local variable - TEXT.
			IFS=$'\n' # Reset field separator.

			# Check for comments/headers.
			case "${Target_ENDPOINTNAME}" in
				'# NAME')
					return 3 # Header line not required, will be recreated later. Not shown.
				;;
				"# VALIDATED"*)
					BulkExportVar="${BulkExportVar}${NewLine}${InputLine}" # A validation from previous success to be retained.
					[[ ${ThisMode} != "PARSECHECKONLY" ]] \
						&& return 2 # Not counted. Shown if in checking mode only.
				;;
				"#"*)
					BulkExportVar="${BulkExportVar}${NewLine}${InputLine}" # A simple commented line to be retained.
					return 3 # Not shown.
				;;
				*)
					(( OutputCounter[1]++ )) # All lines that made it here count to be processed.
				;;
			esac

			# Continue parsing.
			Target_ENDPOINTTYPE="${EachLine[1]:-MISSINGTYPE}" # Local variable - TEXT.
			Target_NETWORK[0]="${EachLine[2]:-MISSINGNETWORK}" # Local variable - UUID.
			Target_GEOREGION[0]="${EachLine[3]:-MISSINGGEOREGION}" # Local variable - UUID.
			AllEndpointGroups[0]="${EachLine[4]:-NOENDPOINTGROUPS}" # Local variable - UUID.
			AllAppWANs[0]="${EachLine[5]:-NOAPPWANS}" # Local variable - UUID.
			Target_EMAIL[0]="${EachLine[6]:-NOEMAIL}" # Local array - EMAIL/TEXT.
			Target_EMAIL[0]="${Target_EMAIL[0]//[[:space:]]/}" # Remove SPACES.
			Target_EMAIL[0]="${Target_EMAIL[0]//\;/,}" # Convert semicolon to commas.
			Target_EMAIL[1]="${EachLine[7]:-API AUTOMATION}" # Local array - TEXT.
			Target_EMAIL[1]="${Target_EMAIL[1]:0:75}" # Limit message to 75 chars.

			# Specific to parsing the AllEndpointGroups and AllAppWANs arrays.
			IFS=';' # AllEndpointGroups and AllAppWANs lists are semi-colon delimited arrays.
			if [[ ${AllEndpointGroups[0]} != "NOENDPOINTGROUPS" ]]; then
				AllEndpointGroups=( ${AllEndpointGroups} )
				for ((i=0;i<${#AllEndpointGroups[*]};i++)); do AllEndpointGroupsShort[${i}]="...${AllEndpointGroups[${i}]: -5}"; done
			else
				AllEndpointGroupsShort=( 'NOENDPOINTGROUPS' )
			fi
			if [[ ${AllAppWANs[0]} != "NOAPPWANS" ]]; then
				AllAppWANs=( ${AllAppWANs} )
				for ((i=0;i<${#AllAppWANs[*]};i++)); do AllAppWANsShort[${i}]="...${AllAppWANs[${i}]: -5}"; done
			else
				AllAppWANsShort[0]='NOAPPWANS'
			fi
			IFS=$'\n' # Reset field separator.

			# Line checking.
			if [[ ${Target_ENDPOINTNAME[0]} == "MISSINGNAME" ]] || [[ ${Target_ENDPOINTTYPE} == "MISSINGTYPE" ]] || [[ ${Target_NETWORK[0]} == "MISSINGNETWORK" ]] || [[ ${Target_GEOREGION[0]} == "MISSINGGEOREGION" ]]; then
				[[ ${ThisMode} == "PARSECHECKONLY" ]] \
					&& AttentionMessage "ERROR" "The following line is missing required context. Ignoring line."
				(( OutputCounter[3]++ )) # Increment the failure counter.
				(( OutputCounter[1]-- )) # Decrement the valid counter.
				return 1
			elif [[ ${#Target_ENDPOINTNAME} -lt 5 ]] || [[ ${#Target_ENDPOINTNAME} -gt 64 ]] || [[ ! ${Target_ENDPOINTNAME} =~ ^[[:alnum:]].*[[:alnum:]]$ ]]; then
				if [[ ${ThisMode} == "PARSECHECKONLY" ]] && [[ ${Target_ENDPOINTNAME} =~ "VALIDATED" ]]; then
					Target_ENDPOINTNAME="${Target_ENDPOINTNAME/\# VALIDATED*\#/}"
					return 2
				elif [[ ${ThisMode} == "PARSECHECKONLY" ]]; then
					AttentionMessage "ERROR" "The following line contains a name that does not meet naming criteria. Name must be >=5 chars, <=64 chars, and only alphanumeric. Ignoring line."
				fi
				(( OutputCounter[3]++ )) # Increment the failure counter.
				(( OutputCounter[1]-- )) # Decrement the valid counter.
				return 1
			elif [[ ${#Target_NETWORK} -ne 36 ]] || [[ ${#Target_GEOREGION} -ne 36 ]]; then
				[[ ${ThisMode} == "PARSECHECKONLY" ]] \
					&& AttentionMessage "ERROR" "The following line contains a Network UUID or GeoRegion UUID that is not 36 chars. Ignoring line."
				(( OutputCounter[3]++ )) # Increment the failure counter.
				(( OutputCounter[1]-- )) # Decrement the valid counter.
				return 1
			elif [[ ${AllEndpointGroups[0]} != "NOENDPOINTGROUPS" ]] && [[ ${#AllEndpointGroups} -lt 36 ]]; then
				[[ ${ThisMode} == "PARSECHECKONLY" ]] && [[ ${AllEndpointGroups[0]} =~ "@" ]] \
					&& AttentionMessage "ERROR" "The following line contains EndpointGroup UUID(s) which have an email address instead of a UUID. Ignoring line." \
					|| AttentionMessage "ERROR" "The following line contains EndpointGroup UUID(s) that are in error. Ignoring line."
				(( OutputCounter[3]++ )) # Increment the failure counter.
				(( OutputCounter[1]-- )) # Decrement the valid counter.
				return 1
			elif [[ ${AllAppWANs[0]} != "NOAPPWANS" ]] && [[ ${#AllAppWANs} -lt 36 ]]; then
				[[ ${ThisMode} == "PARSECHECKONLY" ]] && [[ ${AllAppWANs[0]} =~ "@" ]] \
					&& AttentionMessage "ERROR" "The following line contains AppWAN UUID(s) which have an email address instead of a UUID. Ignoring line." \
					|| AttentionMessage "ERROR" "The following line contains AppWAN UUID(s) that are in error. Ignoring line."
				(( OutputCounter[3]++ )) # Increment the failure counter.
				(( OutputCounter[1]-- )) # Decrement the valid counter.
				return 1
			else
				return 0
			fi

		fi
	}

	# 1/BULKIMPORTFILE
	local i Target_ENDPOINTNAME Target_ENDPOINTTYPE Target_GEOREGION StoredAttributes
	local Target_APPWAN Target_ENDPOINTGROUP AllEndpointGroups AllEndpointGroupsShort EndpointGroupState AllAppWANs AllAppWANsShort AppWANState
	local InputLine EachLine BulkExportVar OutputCounter OutputCounterComplete
	local BulkImportFile TimeCapture CSVHeader BulkImportVar OutputFile
	BulkImportFile="${1}"
	TimeCapture=( "$(date +%s)" "0" "0" ) # EPOCH seconds. 1=CURRENT 2=ENDOFIMPORT 3=DELTA
	CSVHeader=( "NAME" "TYPE" "NETWORK_UUID" "GEOREGION_UUID" "ENDPOINTGROUP_UUIDS_[OPT]" "APPWAN_UUIDS_[OPT]" "EMAIL_[OPT]" "EMAIL_MSG_[OPT]" )
	BulkImportVar=$(grep -Ev '^[[:space:]]*$' ${BulkImportFile} | tr -dC '[:print:]\t\n') # Sanitized input.
	OutputFile="BulkEndpoints-OUTPUT_${TimeCapture[0]}.csv"

	# Alert the user about how registration keys will be displayed.
	[[ ${BulkCreateLogRegKey:-FALSE} == "TRUE" ]] \
		&& AttentionMessage "WARNING" "The flag \"BulkCreateLogRegKey=${BulkCreateLogRegKey:-ERROR}\" and registration keys WILL be placed into the OUTPUT file." \
		|| AttentionMessage "GREENINFO" "The flag \"BulkCreateLogRegKey=${BulkCreateLogRegKey:-ERROR}\" and registration keys WILL NOT be placed into the OUTPUT file."

	# Give the user a way out of this.
	AttentionMessage "WARNING" "You are about to bulk create new Endpoints as listed below."
	DeconstructLine "INIT"
	printf "%-40s %-12s %-15s %-15s %-28s %-28s %-35s %-15s\n" "${CSVHeader[0]}" "${CSVHeader[1]}" "${CSVHeader[2]}" "${CSVHeader[3]}" "${CSVHeader[4]}" "${CSVHeader[5]}" "${CSVHeader[6]}" "${CSVHeader[7]}"
	for InputLine in ${BulkImportVar};	do
		DeconstructLine "PARSECHECKONLY" # RC#0=VALID_PRINT, RC#1=INVALID_PRINT, RC#2=VALID,PRINT, RC#3=VALID,NOPRINT
		case $? in
			0) printf "%-40.40s %-12s %-15s %-15s %-28s %-28s %-35.35s %-15.15s\n" \
				"${Target_ENDPOINTNAME}" "${Target_ENDPOINTTYPE}" "...${Target_NETWORK: -5}" "...${Target_GEOREGION: -5}" "${AllEndpointGroupsShort[*]}" "${AllAppWANsShort[*]}" "${Target_EMAIL[0]/,*/ ++}" "${Target_EMAIL[1]:0:12}..."
				;;
			1) printf "\e[${FRed}m%-40.40s\e[1;${Normal}m %-12s %-15s %-15s %-28s %-28s %-35.35s %-15.15s\n" \
				"${Target_ENDPOINTNAME}" "${Target_ENDPOINTTYPE}" "...${Target_NETWORK: -5}" "...${Target_GEOREGION: -5}" "${AllEndpointGroupsShort[*]}" "${AllAppWANsShort[*]}" "${Target_EMAIL[0]/,*/ ++}" "${Target_EMAIL[1]:0:12}..."
				;;
			2) printf "\e[${FGreen}m%-40.40s\e[1;${Normal}m %-12s %-15s %-15s %-28s %-28s %-35.35s %-15.15s\n" \
				"${Target_ENDPOINTNAME}" "${Target_ENDPOINTTYPE}" "...${Target_NETWORK: -5}" "...${Target_GEOREGION: -5}" "${AllEndpointGroupsShort[*]}" "${AllAppWANsShort[*]}" "${Target_EMAIL[0]/,*/ ++}" "${Target_EMAIL[1]:0:12}..."
				;;
		esac
	done
	OutputCounterComplete[0]="${OutputCounter[0]}" # Save the complete count.
	OutputCounterComplete[1]="${OutputCounter[1]}" # Save the complete and valid count.

	# Ensure the file is actually populated.
	[[ ${OutputCounter[0]} -eq 0 ]] \
		&& ClearLines "2" \
		&& AttentionMessage "ERROR" "Bulk Import File \"./${BulkImportFile}\" had ZERO entries - Check the file, its permissions, and try again." \
		&& return 1

	# Ensure the file is actually populated with something that can be used.
	[[ ${OutputCounter[1]} -eq 0 ]] \
		&& ClearLines "2" \
		&& AttentionMessage "YELLOWINFO" "Bulk Import File \"./${BulkImportFile}\" had ZERO usable entries." \
		&& return 0

	# Check point.
	AttentionMessage "GREENINFO" "Found ${OutputCounterComplete[1]}/${OutputCounterComplete[0]} lines in the import file for processing."
	! GetYorN "Ready?" "Yes" "20" \
		&& return 1

	# Ensure the output file can be written to.
	! touch "${OutputFile}" \
		&& AttentionMessage "ERROR" "Could not create \"./${OutputFile}\" - Check your user permissions for the working directory." \
		&& return 1 \
		|| echo "# EPOCH,ENDPOINT_NAME,ENDPOINT_TYPE,NETWORK_UUID,GEOREGION_UUID,ENDPOINTGROUPS_STATE,APPWANS_STATE,ENDPOINT_UUID,REGISTRATION_KEY,EMAIL_STATE" > ${OutputFile}

	# Run the analysis over each line in the file.

	DeconstructLine "INIT"
	for InputLine in ${BulkImportVar};	do

		# Ensure idle tracking does not cancel the work.
		TrackLastTouch "UPDATE"

		DeconstructLine "PARSE" \
			|| continue

		# Run creation.
		AttentionMessage "GREENINFO" " ┏[${OutputCounter[1]}/${OutputCounterComplete[1]}] Creating new Endpoint \"${Target_ENDPOINTNAME}\"."
		# This Endpoint was newly created.
		if SetObjects_MOP_V6 "CREATEENDPOINT" "${Target_ENDPOINTNAME}" "${Target_ENDPOINTTYPE}" "${Target_GEOREGION}"; then

			(( OutputCounter[2]++ )) # Increment the success count.

			# Determine how to treat the returned registration key.
			if [[ ${BulkCreateLogRegKey:-FALSE} == "TRUE" ]]; then
				StoredAttributes=( "${SetObjectReturn##*=>}" "${SetObjectReturn%%=>*}" ) # 0/ENDPOINT_UUID 1/REGISTRATION_KEY.
			else
				StoredAttributes=( "${SetObjectReturn##*=>}" "REGKEY:REDACTED" ) # 0/ENDPOINT_UUID 1/REGISTRATION_KEY.
			fi

			AttentionMessage "GREENINFO" " ┣━━Endpoint \"${Target_ENDPOINTNAME}\" creation succeeded."
			BulkExportVar="${BulkExportVar}${NewLine}${InputLine}"

			# Attempt to add to an AppWAN before conclusion?
			if [[ ${AllEndpointGroups} != "NOENDPOINTGROUPS" ]]; then
				for ((i=0;i<${#AllEndpointGroups[*]};i++)); do
					AttentionMessage "GREENINFO" " ┣━Request to add Endpoint to EndpointGroup \"${AllEndpointGroups[${i}]}\" started."
					if SetObjects_MOP_V6 "ADDENDPOINTTOENDPOINTGROUP" "${StoredAttributes[0]}" "${AllEndpointGroups[${i}]}" &>/dev/null; then
						AttentionMessage "GREENINFO" " ┣━━Request to add Endpoint to EndpointGroup is complete."
						(( OutputCounter[6]++ )) # Increment the pass counter.
						EndpointGroupState[${i}]="ADDEPG_OK:${AllEndpointGroups[${i}]}"
					else
						AttentionMessage "ERROR" " ┣━━Request to add Endpoint to EndpointGroup did not complete. Endpoint remains available."
						(( OutputCounter[7]++ )) # Increment the fail counter.
						EndpointGroupState[${i}]="ADDEPG_FAIL:${AllEndpointGroups[${i}]}"
					fi
				done
			else
				EndpointGroupState[0]="ADDEPG:NA"
			fi

			# Attempt to add to an AppWAN before conclusion?
			if [[ ${AllAppWANs} != "NOAPPWANS" ]]; then
				for ((i=0;i<${#AllAppWANs[*]};i++)); do
					AttentionMessage "GREENINFO" " ┣━Request to add \"${Target_ENDPOINTNAME}\" to AppWAN \"${AllAppWANs[${i}]}\" started."
					if SetObjects_MOP_V6 "ADDENDPOINTTOAPPWAN" "${StoredAttributes[0]}" "${AllAppWANs[${i}]}" &>/dev/null; then
						AttentionMessage "GREENINFO" " ┣━Request to add \"${Target_ENDPOINTNAME}\" to AppWAN(s) is complete."
						(( OutputCounter[8]++ )) # Increment the pass counter.
						AppWANState[${i}]="ADDAPW_OK:${AllAppWANs[${i}]}"
					else
						AttentionMessage "ERROR" " ┣━━Request to add Endpoint to AppWAN did not complete. Endpoint remains available."
						(( OutputCounter[9]++ )) # Increment the fail counter.
						AppWANState[${i}]="ADDAPW_FAIL:${AllAppWANs[${i}]}"
					fi
				done
			else
				AppWANState[0]="ADDAPW:NA"
			fi

			# Conclude.
			AttemptEmail

		# This Endpoint failed to create. Possibly due to already existing, or actually a true failure.
		else

			# Do a lookup on the name and see if it can return a UUID and STATE.
			FilterString="${Target_ENDPOINTNAME}" # Set the filter to grab only this specific Endpoint name.
			StoredAttributes[0]="${SetObjectReturn:-NO MESSAGE RETURNED}" # 0/OriginalReturnMsg

			# If the GetObject returns false, then this is a true failure (could not create and no UUID returned).
			if ! GetObjects_MOP "ENDPOINT-REGSTATE"; then

				(( OutputCounter[3]++ ))
				AttentionMessage "ERROR" " ┗━Endpoint creation failed. See message below."
				echo "${StoredAttributes[0]:-NO MESSAGE RETURNED}"
				echo "$(date +'%s'),${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION},CREATION_FAILED_NOUUID,CREATION_FAILED_NO_REGISTRATION_KEY,CREATION_FAILED_NO_ENDPOINTGROUP,CREATION_FAILED_NO_APPWAN,EMAIL:${Target_EMAIL[0]}" >> ${OutputFile}
				BulkExportVar="${BulkExportVar}${NewLine}${InputLine}"

			# If the GetObject returns true, then this is not a failure as the Endpoint exists already.
			else

				StoredAttributes[0]="${AllEndpoints##*=>}" # 0/ENDPOINT_UUID.
				StoredAttributes[1]="${AllEndpoints%:::*}" # 1/STATE:::REG_ATTEMPTS_LEFT.
				StoredAttributes[2]="${AllEndpoints##*:::}" # 2/REGISTRATION_KEY.

				# Determine how to treat the returned registration key.
				[[ ${BulkCreateLogRegKey:-FALSE} != "TRUE" ]] \
					&& StoredAttributes[2]="REGKEY:REDACTED" # 2/REGISTRATION_KEY.

				# A state of any except 400 indicates the Endpoint is not registered.
				if [[ ${StoredAttributes[1]%:::*} -ne 400 ]] && [[ ${StoredAttributes[1]#*:::} -gt 0 ]]; then

					(( OutputCounter[2]++ )) # Increment the success counter.
					AttentionMessage "YELLOWINFO" " ┣━━Endpoint exists but has not registered yet. (STATE=${StoredAttributes[1]%:::*} | ATTEMPTS LEFT=${StoredAttributes[1]#*:::})"
					BulkExportVar="${BulkExportVar}${NewLine}${InputLine}"

					# Attempt to add to an AppWAN before conclusion?
					if [[ ${AllEndpointGroups} != "NOENDPOINTGROUPS" ]]; then
						for ((i=0;i<${#AllEndpointGroups[*]};i++)); do
							AttentionMessage "GREENINFO" " ┣━Request to add Endpoint to EndpointGroup \"${AllEndpointGroups[${i}]}\" started."
							if SetObjects_MOP_V6 "ADDENDPOINTTOENDPOINTGROUP" "${StoredAttributes[0]}" "${AllEndpointGroups[${i}]}" &>/dev/null; then
								AttentionMessage "VALIDATED" " ┣━━Request to add Endpoint to EndpointGroup is complete."
								(( OutputCounter[6]++ )) # Increment the pass counter.
								EndpointGroupState[${i}]="ADDEPG_OK:${AllEndpointGroups[${i}]}"
							else
								AttentionMessage "ERROR" " ┣━━Request to add Endpoint to EndpointGroup did not complete. Endpoint remains available."
								(( OutputCounter[7]++ )) # Increment the fail counter.
								EndpointGroupState[${i}]="ADDEPG_FAIL:${AllEndpointGroups[${i}]}"
							fi
						done
					else
						EndpointGroupState[0]="ADDEPG:NA"
					fi

					# Attempt to add to an AppWAN before conclusion?
					if [[ ${AllAppWANs} != "NOAPPWANS" ]]; then
						for ((i=0;i<${#AllAppWANs[*]};i++)); do
							AttentionMessage "GREENINFO" " ┣━Request to add Endpoint to AppWAN \"${AllAppWANs[${i}]}\" started."
							if SetObjects_MOP_V6 "ADDENDPOINTTOAPPWAN" "${StoredAttributes[0]}" "${AllAppWANs[${i}]}" &>/dev/null; then
								AttentionMessage "VALIDATED" " ┣━━Request to add Endpoint to AppWAN is complete."
								(( OutputCounter[8]++ )) # Increment the pass counter.
								AppWANState[${i}]="ADDAPW_OK:${AllAppWANs[${i}]}"
							else
								AttentionMessage "ERROR" " ┣━━Request to add Endpoint to AppWAN did not complete. Endpoint remains available."
								(( OutputCounter[9]++ )) # Increment the fail counter.
								AppWANState[${i}]="ADDAPW_FAIL:${AllAppWANs[${i}]}"
							fi
						done
					else
						AppWANState[0]="ADDAPW:NA"
					fi

					# Conclude.
					AttemptEmail

				# Registration attempts equal to zero indicate the user cannot register anymore.
				elif [[ ${StoredAttributes[1]%:::*} -ne 400 ]] && [[ ${StoredAttributes[1]#*:::} -eq 0 ]]; then

					(( OutputCounter[3]++ ))
					AttentionMessage "ERROR" " ┗━━Endpoint exists but has not registered yet and has run out of attempts. (STATE=${StoredAttributes[1]%:::*}) | ATTEMPTS LEFT=${StoredAttributes[1]#*:::})"
					echo "$(date +'%s'),${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION},${StoredAttributes[0]:-UUID_NA},NO_ATTEMPTS_LEFT:${StoredAttributes[1]:-REGKEY:NA},EMAIL:${Target_EMAIL[0]}" >> ${OutputFile}
					BulkExportVar="${BulkExportVar}${NewLine}${InputLine}"

				else

					AttentionMessage "VALIDATED" " ┗━Endpoint \"${Target_ENDPOINTNAME}\" exists and is registered. No further action taken. (STATE=${StoredAttributes[2]})"
					(( OutputCounter[10]++ )) # Increment the registered counter.
					BulkExportVar="${BulkExportVar}${NewLine}# VALIDATED_${TimeCapture[0]} #${InputLine}"

				fi

			fi

		fi

	done

	# Analysis.
	TimeCapture[1]="$(date +%s)"
	TimeCapture[2]="$((TimeCapture[1]-TimeCapture[0]))"
	echo " ┏BULK ENDPOINT CREATION START AT $(date -d @${TimeCapture[0]})"
	echo " ┣━TOTAL LINES:       ${OutputCounterComplete[0]}"
	echo " ┣━━LINES COUNTED:    ${OutputCounterComplete[1]}"
	if [[ $((OutputCounter[1])) -ge 1 ]]; then
		echo " ┣━CREATE SUCCESS:    ${OutputCounter[2]} ($(((OutputCounter[2]*100)/OutputCounter[1]))%)"
		echo " ┣━━REGISTERED:       ${OutputCounter[10]:-0} ($(((${OutputCounter[10]:-0}*100)/OutputCounter[1]))%)"
		echo " ┣━━CREATE/REG FAIL:  ${OutputCounter[3]} ($(((OutputCounter[3]*100)/OutputCounter[1]))%)"
	fi
	if [[ $((OutputCounter[6]+OutputCounter[7])) -ge 1 ]]; then
		echo " ┣━GROUP-ADD SUCCESS: ${OutputCounter[6]} ($(((OutputCounter[6]*100)/(OutputCounter[6]+OutputCounter[7])))%)"
		echo " ┣━━GROUP-ADD FAIL:   ${OutputCounter[7]} ($(((OutputCounter[7]*100)/(OutputCounter[6]+OutputCounter[7])))%)"
	fi
	if [[ $((OutputCounter[8]+OutputCounter[9])) -ge 1 ]]; then
		echo " ┣━APPWAN-ADD SUCCESS:${OutputCounter[8]} ($(((OutputCounter[8]*100)/(OutputCounter[8]+OutputCounter[9])))%)"
		echo " ┣━━APPWAN-ADD FAIL:  ${OutputCounter[9]} ($(((OutputCounter[9]*100)/(OutputCounter[8]+OutputCounter[9])))%)"
	fi
	if [[ $((OutputCounter[4]+OutputCounter[5])) -ge 1 ]]; then
		echo " ┣━EMAIL-SEND SUCCESS:${OutputCounter[4]} ($(((OutputCounter[4]*100)/(OutputCounter[4]+OutputCounter[5])))%)"
		echo " ┣━━EMAIL-SEND FAIL:  ${OutputCounter[5]} ($(((OutputCounter[5]*100)/(OutputCounter[4]+OutputCounter[5])))%)"
	fi
	echo " ┗COMPLETE AT $(date). TOTAL TIME $((TimeCapture[2]/60))m $((TimeCapture[2]%60))s."

	# Update the import file and reveal the output file.
	AttentionMessage "GREENINFO" "Output results stored in file \"${OutputFile}\"."
	echo "${BulkExportVar}" > ${BulkImportFile} \
		&& AttentionMessage "GREENINFO" "Updated the import file \"${BulkImportFile}\"." \
		|| AttentionMessage "ERROR" "Could not update the import file \"${BulkImportFile}\"."

	# Only complete 100% pass rate is considered success in the end.
	[[ ${OutputCounter[2]} -eq ${OutputCounter[1]} ]] \
		&& return 0 \
		|| return 1
}

#################################################################################
# Create new endpoints (V6).
function CreateEndpoints_V6() {
	# An array of all Endpoint Types and selectors.
	local AllEndpointTypes=( \
		"NetFoundry Client=>CL"
		"NetFoundry ZITI Client=>ZTCL"
		"NetFoundry Internet Gateway=>GW"
		"NetFoundry AWS Gateway=>AWSCPEGW"
		"NetFoundry Azure Gateway=>AZVCPEGW"
		"NetFoundry Azure Stack Gateway=>AZSGW"
		"NetFoundry GCP Google Gateway=>GCPCPEGW"
		"NetFoundry Hosted ZITI Bridge=>ZTGW"
		"NetFoundry Private ZITI Bridge=>ZTHGW"
		"NetFoundry Generic Premise Gateway=>VCPEGW"
	)
	local AddTo=( \
		"ENDPOINTGROUP"
		"APPWAN"
		"No Association"
	)
	local Target_ENDPOINTNAME Target_ENDPOINTTYPE Target_GEOREGION Target_ASSOCIATION Target_EMAIL Target_ENDPOINTUUID Target_ENDPOINTKEY

	# The menu will loop around.
	CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/CreateEndpoint"
	while true; do

		# The user needs to assert the type of the new Endpoint.
		! GetSelection "Select the Endpoint type you will be creating." "${AllEndpointTypes[*]}" "${Target_ENDPOINTTYPE}" \
			&& return 0
		Target_ENDPOINTTYPE="${UserResponse##*=>}"

		while true; do

			# The user needs to name the new Endpoint.
			! GetObjectName "for the new Endpoint" \
				&& return 0
			Target_ENDPOINTNAME="${UserResponse}"

			while true; do

				# The user needs to select a GeoRegion that is appropriate.
				GetObjects_MOP "GEOREGIONS" &>/dev/null
				! GetSelection "Select the target GeoRegion for \"${Target_ENDPOINTNAME}\"." "${AllGeoRegions[*]}" "${Target_GEOREGION}" \
					&& break
				Target_GEOREGION=${UserResponse}

				while true; do

					# The user needs to instruct if to add this Endpoint to an EndpointGroup, directly to an AppWAN, or nothing.
					! GetSelection "Select an EndpointGroup or AppWAN association for \"${Target_ENDPOINTNAME}\"." "${AddTo[*]}" "${Target_ASSOCIATION}" \
						&& break

					case ${UserResponse} in

						"ENDPOINTGROUP")
							! GetFilterString "Fetching available EndpointGroups in \"${Target_NETWORK[1]}\"." \
								&& break
							GetObjects_MOP "ENDPOINTGROUPS" &>/dev/null
							AllEndpointGroups=( "${AllEndpointGroups[*]}"	)
							! GetSelection "Select the target EndpointGroup to associate \"${Target_ENDPOINTNAME}\" with." "${AllEndpointGroups[*]}" "${Target_ASSOCIATION[1]}" \
								&& break
							Target_ASSOCIATION[0]="ENDPOINTGROUP"
							Target_ASSOCIATION[1]="${UserResponse}"
						;;

						"APPWAN")
							AllAppWANs=( "${AllAppWANs[*]}"	)
							! GetFilterString "Fetching available AppWANs in \"${Target_NETWORK[1]}\"." \
								&& break
							GetObjects_MOP "APPWANS" &>/dev/null
							! GetSelection "Select the target AppWAN to associate \"${Target_ENDPOINTNAME}\" with." "${AllAppWANs[*]}" "${Target_ASSOCIATION[0]}" \
								&& break
							Target_ASSOCIATION[0]="APPWAN"
							Target_ASSOCIATION[1]="${UserResponse}"
						;;

						"No Association")
							unset Target_ASSOCIATION
						;;

					esac

					# Does the user wish to email the owner of this new Endpoint?
					if GetYorN "Send an Email to alert the owner of this new Endpoint?" "No"; then

						# The user needs to give an Email to send the new Endpoint information to.
						! GetResponse "Enter a valid Email to send an alert to." \
							&& continue
						Target_EMAIL[0]="${UserResponse}"

						# The user needs to give a name (and instructions) which appears in the email.
						! GetResponse "Enter your First/Last name followed by <br> and a message if desired. (MAX 75 CHARS)" \
							&& continue
						Target_EMAIL[1]="${UserResponse:0:75}"

					fi

					while true; do

						AttentionMessage "WARNING" "Review New Endpoint Details Carefully!"
						echo "ORGANIZATION:  \"${Target_ORGANIZATION[1]}\""
						echo "NETWORK:       \"${Target_NETWORK[1]}\""
						echo "NAME:          \"${Target_ENDPOINTNAME}\""
						echo "TYPE:          \"${Target_ENDPOINTTYPE}\""
						echo "REGION:        \"${Target_GEOREGION%%=>*}\""
						[[ -z ${Target_ASSOCIATION[0]} ]] \
							&& echo "ASSOCIATION:   \"No Association\"" \
							|| echo "ASSOCIATION:   \"${Target_ASSOCIATION[0]}=>${Target_ASSOCIATION[1]%%=>*}\""
						[[ -z ${Target_EMAIL[0]} ]] \
							&& echo "EMAIL ALERT:   \"NONE\"" \
							|| echo "EMAIL ALERT:   \"${Target_EMAIL[0]}\" FROM \"${Target_EMAIL[1]}\""
						GetYorN "Ready?" \
							|| break 4

						# Create the new Endpoint.
						AttentionMessage "GREENINFO" "Creating new Endpoint \"${Target_ENDPOINTNAME}\"."
						SetObjects_MOP_V6 "CREATEENDPOINT" "${Target_ENDPOINTNAME}" "${Target_ENDPOINTTYPE}" "${Target_GEOREGION##*=>}"

						if [[ $? -eq 0 ]]; then

							Target_ENDPOINTUUID="${SetObjectReturn##*=>}"
							Target_ENDPOINTKEY="${SetObjectReturn%%=>*}"

							AttentionMessage "VALIDATED" "ENDPOINT_NAME=\"${Target_ENDPOINTNAME}\", ENDPOINT_TYPE=\"${Target_ENDPOINTTYPE}\", ENDPOINT_UUID=\"${Target_ENDPOINTUUID}\", REGISTRATIONKEY=\"${Target_ENDPOINTKEY}\"."

							if [[ -n ${Target_ASSOCIATION[0]} ]]; then
								AttentionMessage "GREENINFO" "Adding \"${Target_ENDPOINTNAME}\" to ${Target_ASSOCIATION[0]} \"${Target_ASSOCIATION[1]%%=>*}\"."
								! SetObjects_MOP_V6 "ADDENDPOINTTO${Target_ASSOCIATION[0]}" "${SetObjectReturn##*=>}" "${Target_ASSOCIATION[1]##*=>}" \
									&& AttentionMessage "ERROR" "Endpoint association failed. Endpoint remains available." \
									&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}" \
									|| AttentionMessage "VALIDATED" "New Endpoint \"${Target_ENDPOINTNAME}\" added to \"${Target_ASSOCIATION[1]%%=>*}\"."
							fi

							if [[ -n ${Target_EMAIL[0]} ]]; then
								AttentionMessage "GREENINFO" "Sending alert to \"${Target_EMAIL[0]}\" with information about new Endpoint \"${Target_ENDPOINTNAME}\"."
								! SetObjects_MOP_V6 "EMAILALERT" "${Target_ENDPOINTUUID}" "${Target_EMAIL[0]}" "${Target_EMAIL[1]}" \
									&& AttentionMessage "ERROR" "Email alert transmission failed. Endpoint remains available." \
									&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}" \
									|| AttentionMessage "VALIDATED" "Email alert transmission succeeded."
							fi

							# Add the Endpoint to the default bulk import file if desired.
							if GetYorN "Do you want to add the Endpoint as a line in \"$(pwd)/BulkEndpoints.csv\" for subsequent Bulk Import?" "Yes"; then

								case ${Target_ASSOCIATION[0]} in
									"ENDPOINTGROUP")
										echo "${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION##*=>},${Target_ASSOCIATION[1]##*=>},,${Target_EMAIL[0]}" >> BulkEndpoints.csv # Add the line elements to the file.
									;;
									"APPWAN")
										echo "${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION##*=>},,${Target_ASSOCIATION[1]##*=>},${Target_EMAIL[0]}" >> BulkEndpoints.csv # Add the line elements to the file.
									;;
									*)
										echo "${Target_ENDPOINTNAME},${Target_ENDPOINTTYPE},${Target_NETWORK[0]},${Target_GEOREGION##*=>},,,${Target_EMAIL[0]}" >> BulkEndpoints.csv # Add the line elements to the file.
									;;
								esac

							fi

						else

							AttentionMessage "ERROR" "Endpoint creation failed, thus will not perform further actions."
							echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
							return 1

						fi

						# Finished.
						return 0

					done
				done
			done
		done
	done
}

#################################################################################
# Create new endpoints (V7).
function CreateEndpoints_V7() {
	local Target_ENDPOINTNAME Target_EMAIL Target_ENDPOINTUUID Target_ENDPOINTJWT

	# The menu will loop around.
	CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/CreateEndpoint"

	while true; do

		# The user needs to name the new Endpoint.
		! GetObjectName "for the new Endpoint" \
			&& return 0
		Target_ENDPOINTNAME="${UserResponse}"

		while true; do

			# Does the user wish to email the owner of this new Endpoint?
			if GetYorN "Send an Email to alert the owner of this new Endpoint?" "No"; then

				# The user needs to give an Email to send the new Endpoint information to.
				! GetResponse "Enter a valid Email to send an alert to." \
					&& continue
				Target_EMAIL[0]="${UserResponse}"

				# The user needs to give a name (and instructions) which appears in the email.
				#! GetResponse "Enter a message if desired. (MAX 75 CHARS)" \
				#	&& continue
				#Target_EMAIL[1]="${UserResponse:0:75}"

			fi

			while true; do

				AttentionMessage "WARNING" "Review New Endpoint Details Carefully!"
				echo "ORGANIZATION:  \"${Target_ORGANIZATION[1]}\""
				echo "NETWORK:       \"${Target_NETWORK[1]}\""
				echo "NAME:          \"${Target_ENDPOINTNAME}\""
				[[ -z ${Target_EMAIL[0]} ]] \
					&& echo "EMAIL ALERT:   \"NONE\"" \
					|| echo "EMAIL ALERT:   \"${Target_EMAIL[0]}\""
					#|| echo "EMAIL ALERT:   \"${Target_EMAIL[0]}\" MESSAGE \"${Target_EMAIL[1]}\""
				GetYorN "Ready?" \
					|| break 4

				# Create the new Endpoint.
				AttentionMessage "GREENINFO" "Creating new Endpoint \"${Target_ENDPOINTNAME}\"."
				

				if SetObjects_MOP_V7 "CREATEENDPOINT" "${Target_ENDPOINTNAME}"; then

					Target_ENDPOINTUUID="${SetObjectReturn##*=>}"
					Target_ENDPOINTJWT="${SetObjectReturn%%=>*}"

					AttentionMessage "VALIDATED" "ENDPOINT_NAME=\"${Target_ENDPOINTNAME}\", ENDPOINT_UUID=\"${Target_ENDPOINTUUID}\", REGISTRATIONJWT=\"${Target_ENDPOINTJWT}\"."

					if [[ -n ${Target_EMAIL[0]} ]]; then
						AttentionMessage "GREENINFO" "Sending alert to \"${Target_EMAIL[0]}\" with information about new Endpoint \"${Target_ENDPOINTNAME}\"."
						#! SetObjects_MOP_V7 "EMAILALERT" "${Target_ENDPOINTUUID}" "${Target_EMAIL[0]}" "${Target_EMAIL[1]}" \
						! SetObjects_MOP_V7 "EMAILALERT" "${Target_ENDPOINTUUID}" "${Target_EMAIL[0]}" "NONE" \
							&& AttentionMessage "ERROR" "Email alert transmission failed. Endpoint remains available." \
							&& echo "${SetObjectReturn:-NO MESSAGE RETURNED}" \
							|| AttentionMessage "VALIDATED" "Email alert transmission succeeded."
					fi

				else

					AttentionMessage "ERROR" "Endpoint creation failed, thus will not perform further actions."
					echo "${SetObjectReturn:-NO MESSAGE RETURNED}"
					return 1

				fi

				# Finished.
				return 0

			done

		done

	done
}

#################################################################################
# Destroy the NFN Console Bearer Token.
function DestroyBearerToken() {
	# Trigger V7 Metadata destruction.
	SetObjects_V7C "LOGOUT"

	# Destroy the Console Console Bearer Token should it exist.
	if [[ ${NFN_BEARER[0]:-UNSET} == "UNSET" ]] || [[ ${NFN_BEARER[0]} == "null" ]]; then
		return 0
	elif [[ ${NFN_BEARER[1]} == "RETAIN" ]]; then
		AttentionMessage "YELLOWINFO" "Console Bearer Token was passed in. Not attempting to destroy it."
		return 0
	elif SetObjects_MOP_V6 "LOGOUT"; then
		[[ -n ${NFN_BEARER[0]} ]] \
			&& NFN_BEARER[0]="${RANDOM}${RANDOM}" \
			&& unset NFN_BEARER
		AttentionMessage "GENERALINFO" "Console Bearer Token was destroyed successfully."
		return 0
	else
		AttentionMessage "REDINFO" "Console Bearer Token could not be destroyed and potentially continues to exist."
		AttentionMessage "REDINFO" "Please be aware that the Console Bearer Token remains active for use approximately 24hrs after creation."
		return 1
	fi
}

#################################################################################
# Get and store the NFN Console Bearer Token and Network List.
function CheckBearerToken() {

	# Initialize the access mechanisms.
	APIGatewayDomain="https://gateway.${APIMOP}.netfoundry.io"
	APIRESTURL[0]="${APIGatewayDomain}/rest/v1" # MOP V1 Access.
	APIRESTURL[1]="${APIGatewayDomain}/core/v2" # MOP V2 Access.
	APIRESTURL[2]="UNSET" # ZITI (V7) Direct Controller Access.
	APIIDENTITYURL="${APIGatewayDomain}/identity/v1"

	# ThisAuthURL is a global variable that will exist in newer SAFE files only.
	if [[ -z ${ThisAuthURL} ]]; then
		APIAuthURL="https://netfoundry-${APIMOP}.auth0.com/oauth/token"
	else
		APIAuthURL="${ThisAuthURL}"
	fi

	# Console Bearer Token does not exist and it was not passed in.
	if [[ ${NFN_BEARER[0]:-UNSET} == "UNSET" ]]; then

		# Required global variables are not available, thus we cannot continue.
		[[ -z ${ThisClientID} ]] || [[ -z ${ThisClientSecret} ]] \
			&& GoToExit "3" "Console Bearer Token cannot be received unless \"ThisClientID\" and \"ThisClientSecret\" global variables are set."

		# Obtained required global variables to retrieve the Console Bearer Token.
		if [[ ${APIAuthURL} =~ auth0 ]]; then
			NFN_BEARER[0]=$( \
				curl -sSLm ${CURLMaxTime} -X POST -H "content-type: application/json" -H "Cache-Control: no-cache" -d "{
						\"client_id\":\"${ThisClientID}\",
						\"client_secret\": \"${ThisClientSecret}\",
						\"audience\":\"${APIGatewayDomain}/\",
						\"grant_type\":\"client_credentials\"
					}" "${APIAuthURL}" \
					| jq -r '.access_token' 2>/dev/null
			)
		elif [[ ${APIAuthURL} =~ amazoncognito ]]; then
			NFN_BEARER[0]=$( \
				curl -sSLm ${CURLMaxTime} -u "${ThisClientID}:${ThisClientSecret}" -X POST -H "content-type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" --data "grant_type=client_credentials" "${APIAuthURL}" \
				| jq -r '.access_token' 2>/dev/null
			)
		fi

		# Check validity.
		[[ ${#NFN_BEARER[0]} -lt 500 ]] \
			&& GoToExit "3" "Console Bearer Token received from \"${APIAuthURL}\" did not appear to be correct." \
			&& NFN_BEARER[0]="UNSET" \
			|| AttentionMessage "GENERALINFO" "Console Bearer Token received from \"${APIAuthURL}\" appears to be correct."

	# Console Bearer Token does exist from pass in.
	elif [[ ${NFN_BEARER[0]:-UNSET} != "UNSET" ]]; then

		# Check parameters.
		[[ ${#NFN_BEARER[0]} -lt 500 ]] \
			&& GoToExit "3" "Console Bearer Token from pass in was not correctly formatted." \
			&& NFN_BEARER[0]="UNSET" \
			|| AttentionMessage "GENERALINFO" "Console Bearer Token was passed in for \"${APIMOP}\"."

	fi

	# Set syntax for future usage.
	GETSyntax_MOP="curl -sSLim ${CURLMaxTime} -X GET -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: Bearer ${NFN_BEARER[0]}\""
	PUTSyntax_MOP="curl -sSLim ${CURLMaxTime} -X PUT -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: Bearer ${NFN_BEARER[0]}\""
	POSTSyntax_MOP="curl -sSLim ${CURLMaxTime} -X POST -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: Bearer ${NFN_BEARER[0]}\""
	DELETESyntax_MOP="curl -sSLim ${CURLMaxTime} -X DELETE -H \"content-type: application/json\" -H \"Cache-Control: no-cache\" -H \"Authorization: Bearer ${NFN_BEARER[0]}\""

	# If Console Bearer Token previously or now exists, perform a test on it.
	# Store global variables.
	AttentionMessage "GENERALINFO" "Fetching available Organizations."
	GetObjects_MOP "ORGANIZATIONS" 2>/dev/null
	if [[ ${#AllOrganizations} -gt 0 ]]; then

		AttentionMessage "GENERALINFO" "Fetching available Networks."
		GetObjects_MOP "NETWORKS_V6" 2>/dev/null
		GetObjects_MOP "NETWORKS_V7" 2>/dev/null
		GetObjects_MOP "IDTENANTS" 2>/dev/null

		if [[ ${#AllIDTenants} -ge 1 ]]; then

			for ((i=0;i<${#AllIDTenants[*]};i++)); do
				AttentionMessage "GENERALINFO" "Identity Tenant #$((i+1)): ${AllIDTenants[${i}]}."
			done

		else
			AttentionMessage "ERROR" "No Identity Tenants found."
		fi

	else

		GoToExit "3" "No Organizations available. Please check the Console Bearer Token and/or the Organization health and try again."

	fi

	# Release in-memory variables as required.
	[[ -n ${ThisClientID} ]] \
		&& AttentionMessage "GENERALINFO" "Scrambling and releasing the ClientID." \
		&& ThisClientID="${RANDOM}${RANDOM}" \
		&& unset ThisClientID
	[[ -n ${ThisClientSecret} ]] \
		&& AttentionMessage "GENERALINFO" "Scrambling and releasing the ClientSecret." \
		&& ThisClientSecret="${RANDOM}${RANDOM}" \
		&& unset ThisClientSecret
}

#################################################################################
# Usage and help menu for Bulk Creation of Endpoints.
function BulkCreateHelp() {
	FancyPrint "$(printf "%s\n" 'Bulk creation of Endpoints using the API requires an external file be correctly formatted as a read-in.')" "1" "0"
	FancyPrint "$(printf "%s\n" 'Results from each creation will be stored in a relatively created local file named "./OutputFile="BulkEndpoints-OUTPUT_[EPOCH].csv".')" "1" "0"
	FancyPrint "$(printf "%s\n" 'Updates to the input file will be performed for subsequent re-runs against it.')" "1" "0"
	FancyPrint "$(printf "%s\n" 'One or more lines of the Comma Separated Values (CSV) list shall include each of the following in the order shown without quotes.')" "1" "0"
	FancyPrint "$(printf "%s\n\n" '[ENDPOINT NAME],[ENDPOINT TYPE],[NETWORK UUID],[ENDPOINT GEOREGION UUID],[OPTIONAL: ENDPOINTGROUP UUIDS (semi-colon delimited)],[OPTIONAL: APPWAN UUIDS (semi-colon delimited)],[OPTIONAL: ALERT EMAIL(semi-colon delimited)],[OPTIONAL: ALERT EMAIL MESSAGE],')" "0" "0"
	echo
	FancyPrint "$(printf "%s\n" 'Example: The following line will create a new Endpoint named as shown, of type CLIENT, in network of UUID, in the Region of UUID, added to EndPointGroup of UUID, and TWO Emails with details using "Welcome!" as the message.')" "1" "1"
	FancyPrint "$(printf "%s\n\n" 'NetFoundry Fragale-Nic MacBookPro,CL,2dca15fa-6845-47a5-801c-99e94de6d9a7,20d5c5b8-0006-43b9-99aa-503fd3931fea,2dca15fa-6845-4715-1011-49e94dedd9aa,kapil.barman@netfoundry.io;nic.fragale@netfoundry.io,Welcome!')" "0" "0"
	echo
	FancyPrint "$(printf "%s\n" 'Example: The following line will create a new Endpoint named as shown, of type VCPEGW, in network of UUID, in the Region of UUID, added to AppWAN of UUIDs, with no Email alert being sent.')" "1" "1"
	FancyPrint "$(printf "%s\n\n" 'ACME DC-A Trenton-NJ,VCPEGW,2dca15fa-6845-47a5-801c-99e94de6d9a7,9bbca6aa-767c-4c48-b4ab-dac0ead018fc,2dca15fa-6845-4715-1111-99e94de6d9a7;2dca15fa-6845-4715-1111-99e94de6daaa')" "0" "0"
	echo
	FancyPrint "$(printf "%s\n" 'WARNING: Always use the GEOREGION UUID and TYPE as defined by the CURRENT API Syntax.')" "1" "41"
	FancyPrint "$(printf "%s\n" 'WARNING: This program does not check naming syntax, so ensure naming obides by current API requirements.')" "1" "41"
}

#################################################################################
# Calculate the LAT/LON of two points, return distance.
function GetLatLonDistance() {
	function CalcDeg2Rad() {
		bc -l <<< "${1} * 0.0174532925"
	}
	function CalcRad2Deg() {
		bc -l <<< "${1} * 57.2957795"
	}
	function CalcACOS() {
		PIVal="3.141592653589793"
		bc -l <<<"${PIVal} / 2 - a(${1} / sqrt(1 - ${1} * ${1}))"
	}

	# 1/Latitude1 2/Longitude1 3/Latitude2 4/Longitude2
	LAT1Val="${1}"
	LON1Val="${2}"
	LAT2Val="${3}"
	LON2Val="${4}"

	# Step 1, get deltas.
	DeltaLATVal=$(bc <<<"${LAT2Val} - ${LAT1Val}")
	DeltaLONVal=$(bc <<<"${LON2Val} - ${LON1Val}")
	DeltaLATVal="$(CalcDeg2Rad ${DeltaLATVal})"
	DeltaLONVal="$(CalcDeg2Rad ${DeltaLONVal})"

	# Step 2, get radius measurements.
	LAT1Val="$(CalcDeg2Rad ${LAT1Val})"
	LON1Val="$(CalcDeg2Rad ${LON1Val})"
	LAT2Val="$(CalcDeg2Rad ${LAT2Val})"
	LON2Val="$(CalcDeg2Rad ${LON2Val})"

	# Step 3, get final distances.
	DistanceVal=$(bc -l <<< "s(${LAT1Val}) * s(${LAT2Val}) + c(${LAT1Val}) * c(${LAT2Val}) * c($DeltaLONVal)")
	DistanceVal=$(CalcACOS ${DistanceVal})
	DistanceVal=$(CalcRad2Deg ${DistanceVal})
	DistanceVal=$(bc -l <<< "${DistanceVal} * 60 * 1.15078")
	DistanceVal=$(bc <<<"scale=4; ${DistanceVal} / 1")

	# Step 4, output the distance in MILES.
	printf "%.0f" "${DistanceVal}"
}

#################################################################################
# Help the user set/get/lookup their API ID/Secret SAFE.
function ObtainSAFE() {
	function CheckStats() {
		# 1/OPTION 2/DIR_FILE
		# Use Linux STAT to check the ownership of a directory or file.
		stat --format "%${1}" "${2}" 2>/dev/null \
			|| echo "???"
	}

	function CreateSAFE() {
		# 1/SAFEFILE
		local SAFEFile="${1}"
		# Write into the file.
		AttentionMessage "GREENINFO" "Saving information to the SAFE."
		sleep 3
		mkdir -p "${SAFEDir}" &>/dev/null \
			&& export GPG_TTY="$(tty)" \
			&& echo -e "ThisClientID=${ThisClientID}\nThisClientSecret=${ThisClientSecret}\nThisAuthURL=${ThisAuthURL}" | gpg -q --yes -c -o "${SAFEFile}" 2>/dev/null \
			&& chmod -R 700 "${SAFEDir}" &>/dev/null \
			&& (AttentionMessage "GREENINFO" "Successfully created the API SAFE \"${SAFEFile}\"." \
				&& return 0) \
			|| (AttentionMessage "REDINFO" "Failed to create the API SAFE \"${SAFEFile}\". Ensure the directory is accessible and permissioned correctly." \
				&& return 1)
	}

	function OpenSAFE() {
		# 1/SAFEFILE
		local SAFEFile="${1}"
		# It is critical that the SAFE exists before moving forward.
		if [[ -f ${SAFEFile} ]] && [[ $(CheckStats "a" "${SAFEFile}") == "700" ]] && [[ $(CheckStats "U" "${SAFEFile}") == "${USER}" ]]; then
			# The SAFE is valid and permissioned correctly, so read it in.
			AttentionMessage "GENERALINFO" "The API SAFE \"${SAFEFile}\" was found and correctly permissioned."
			while read -r EachLine; do
				export ${EachLine}
			done < <(bash -c "export GPG_TTY=$(tty) && gpg -dqo- ${SAFEFile} 2>/dev/null")
			# Semi-Validate the variables are actually populated correctly.
			if [[ -n ${ThisClientID} ]] && [[ -n ${ThisClientSecret} ]]; then
				if [[ -n ${ThisAuthURL} ]]; then
					AttentionMessage "GENERALINFO" "Successfully able to ascertain the API ID, Secret, and Authentication URL from the API SAFE named \"${SAFEFile##*\/}\"."
					APIAuthURL="${ThisAuthURL}"
					return 0
				else
					AttentionMessage "GENERALINFO" "Successfully able to ascertain the API ID and Secret without Authentication URL from the API SAFE named \"${SAFEFile##*\/}\"."
					APIAuthURL=""
					return 0
				fi
			else
				GoToExit "3" "Failed to ascertain the API ID and Secret from the API SAFE named \"${SAFEFile}\"."
			fi
		else
			if [[ -d ${SAFEDir} ]] && [[ $(CheckStats "a" "${SAFEDir}") != "700" ]] || [[ $(CheckStats "U" "${SAFEDir}") != "${USER}" ]]; then
				GoToExit "3" "API SAFE directory \"${SAFEDir}\" - [Currently: $(CheckStats "a" "${SAFEDir}")/$(CheckStats "U" "${SAFEDir}")] [Requires: 700/${USER}]"
			elif [[ -f ${SAFEFile} ]] && [[ $(CheckStats "a" "${SAFEFile}") != "700" ]] || [[ $(CheckStats "U" "${SAFEFile}") != "${USER}" ]]; then
				GoToExit "3" "API SAFE file \"${SAFEFile}\" - [Currently: $(CheckStats "a" "${SAFEFile}")/$(CheckStats "U" "${SAFEFile}")] [Requires: 700/${USER}]"
			fi
		fi
	}

	function DeleteSAFE() {
		# 1/SAFEFILE (FULL /DIR/FILE)
		local SAFEFile="${1}"
		# Assuming the SAFE file was gathered by prechecking, so it is not required here.
		AttentionMessage "WARNING" "You are about to delete SAFE named \"${SAFEFile##*\/}\"."
		! GetYorN "Proceed?" "No" \
			&& return 0
		rm -f "${SAFEFile}" &>/dev/null \
			&& (AttentionMessage "VALIDATED" "Successfully deleted SAFE named \"${SAFEFile##*\/}\"." \
				&& return 0) \
			|| (AttentionMessage "ERROR" "Failed to delete SAFE named \"${SAFEFile##*\/}\"." \
				&& return 1)
	}

	# 1/SAFENAME
	local SAFEName="${1##*\/}"
	local SAFEPostExt="SAFE"
	local SAFEEncryption="gpg"
	local SAFEFile="${SAFEDir}/${SAFEName}.${SAFEPostExt}.${SAFEEncryption}"

	# If the user did not specify a SAFE they are defaulted to SELECT.
	if [[ ${SAFEName} == "MENU" ]]; then

		AllSAFEOptions=( \
			"List SAFEs"
			"Create SAFE"
			"Open SAFE"
			"Delete SAFE"
		)

		# Path selection.
		while true; do
			CurrentPath="/APISAFE/MAINSelection"
			unset SAFEFile SAFEName ThisClientID ThisClientSecret ThisAuthURL

			if [[ ! -e ${SAFEDir} ]]; then
				AttentionMessage "ERROR" "The API SAFE directory \"${SAFEDir}\" does not exist."
			elif [[ $(CheckStats "a" "${SAFEDir}") != "700" ]] || [[ $(CheckStats "U" "${SAFEDir}") != "${USER}" ]]; then
				AttentionMessage "ERROR" "The API SAFE directory \"${SAFEDir}\" exists, however it is not permissioned correctly. [Currently: $(CheckStats "a" "${SAFEDir}")/$(CheckStats "U" "${SAFEDir}")] [Requires: 700/${USER}]"
			fi

			AllSAFEs=( $(find ${SAFEDir}/*.${SAFEPostExt}.${SAFEEncryption} -maxdepth 1 -type f -exec basename {} \; 2>/dev/null) )
			GetSelection "What would you like to do?" "${AllSAFEOptions[*]}" "NONE"

			case "${UserResponse}" in

				"List SAFEs")
					AttentionMessage "GREENINFO" "The following SAFEs are encrypted and stored at \"${SAFEDir}\"."
					while true; do
						CurrentPath="/APISAFE/ListSAFEs"
						! GetSelection "Review metadata on which SAFE?" "${AllSAFEs[*]}" "NONE" \
							&& break
						AttentionMessage "GREENINFO" "The following metadata is applicable to \"${UserResponse}\"."
						stat "${SAFEDir}/${UserResponse}" 2>/dev/null \
							|| AttentionMessage "ERROR" "Could not stat the file. Permissions to analyze it may not be correct for your user."
						GetYorN "SPECIAL-PAUSE"
						ClearLines "ALL"
					done
				;;

				"Create SAFE")
					# Loop around.
					while true; do
						CurrentPath="/APISAFE/CreateSAFE"
						# Ask questions about this SAFE.
						! GetResponse "Enter a name for this SAFE." "CLEARINPUT:0" \
							&& ClearLines "ALL" \
							&& break
						SAFEName="${UserResponse}"
						SAFEFile="${SAFEDir}/${SAFEName}.${SAFEPostExt}.${SAFEEncryption}"
						find "${SAFEFile}" &>/dev/null \
							&& AttentionMessage "WARNING" "A SAFE with the name \"${SAFEFile##*\/}\" already exists, proceeding will overwrite it." \
							&& ! GetYorN "Proceed?" "No" \
								&& continue
						ClearLines "ALL"
						# Get the ID and Secret from the user.
						until [[ ${#ThisClientID} -gt 10 ]]; do
							[[ ${ThisClientID:-UNSET} != "UNSET" ]] \
								&& AttentionMessage "ERROR" "Your response was too short to apply, try again." \
								&& sleep 2 \
								&& ClearLines "1"
							! GetResponse "Paste-in the API Client ID for SAFE named \"${SAFEFile##*\/}\"?" "CLEARINPUT:2" \
								&& ClearLines "ALL" \
								&& break 2
							ThisClientID="${UserResponse}"
						done
						until [[ ${#ThisClientSecret} -gt 10 ]]; do
							[[ ${ThisClientSecret:-UNSET} != "UNSET" ]] \
								&& AttentionMessage "ERROR" "Your response was too short to apply, try again." \
								&& sleep 2 \
								&& ClearLines "1"
							! GetResponse "Paste-in the API Client Secret for SAFE named \"${SAFEFile##*\/}\"?"  "CLEARINPUT:2" \
								&& ClearLines "ALL" \
								&& break 2
							ThisClientSecret="${UserResponse}"
						done
						until [[ ${#ThisAuthURL} -gt 10 ]]; do
							[[ ${ThisAuthURL:-UNSET} != "UNSET" ]] \
								&& AttentionMessage "ERROR" "Your response was too short to apply, try again." \
								&& sleep 2 \
								&& ClearLines "1"
							! GetResponse "Paste-in the Authentication URL for SAFE named \"${SAFEFile##*\/}\"?" "CLEARINPUT:2" \
								&& ClearLines "ALL" \
								&& break 2
							ThisAuthURL="${UserResponse}"
						done
						AttentionMessage "WARNING" "You will be asked to enter a PASSWORD of your choice. Save this password OUTSIDE of this device for security reasons."
						! GetYorN "Ready to create new SAFE named \"${SAFEFile##*\/}\"?" "Yes" \
							&& unset ThisClientID ThisClientSecret ThisAuthURL \
							&& ClearLines "ALL" \
							&& break
						CreateSAFE "${SAFEFile}" \
							&& unset ThisClientID ThisClientSecret ThisAuthURL \
							&& break \
							|| continue
					done
				;;

				"Open SAFE")
					while true; do
						CurrentPath="/APISAFE/OpenSAFE"
						! GetSelection "Select a SAFE to open." "${AllSAFEs[*]}" "NONE" \
							&& break
						SAFEFile="${SAFEDir}/${UserResponse}"
						OpenSAFE "${SAFEFile}" \
							&& return 0 \
							|| continue
					done
				;;

				"Delete SAFE")
					while true; do
						CurrentPath="/APISAFE/DeleteSAFE"
						! GetSelection "Select a SAFE to delete." "${AllSAFEs[*]}" "NONE" \
							&& break
						SAFEFile="${SAFEDir}/${UserResponse}"
						DeleteSAFE "${SAFEFile}" \
							&& break \
							|| continue
					done
				;;

			esac

		done

	else

		OpenSAFE "${SAFEFile}" \
			&& return 0 \
			|| GoToExit "3" "An internal error occurred. Please report this."

	fi
}

#################################################################################
# Auto installation of required packages.
function AutoInstallPackages() {
	function ExecuteInstall() {
		# 1/PKGMGRPROG
		local MyPkgMgr="${1}"
		AttentionMessage "GREENINFO" "Reviewing, installing, and updating programs on your system with \"${MyPkgMgr}\" Package Manager."
		AttentionMessage "GREENINFO" "This process could take a few minutes, so be patient."
		case "${MyPkgMgr}" in
			"brew")
				${MyPkgMgr} update
				${MyPkgMgr} install coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep gnupg curl jq bc openssl
				${MyPkgMgr} upgrade
				return $?
			;;
			*)
				[[ ${MyPkgMgr} == "yum" ]] \
					&& sudo -s bash -c "${MyPkgMgr} install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y"
				sudo -s bash -c "${MyPkgMgr} install gnupg curl jq bc -y"
				return $?
			;;
		esac
	}

	function GetPkgMgr() {
		local OSInfo
		OSInfo=( \
			"/etc/redhat-release:::yum"
			"/etc/arch-release:::pacman"
			"/etc/gentoo-release:::emerge"
			"/etc/SuSE-release:::zypp"
			"/etc/debian_version:::apt-get"
		)

		# Check for existence.
		for EachPkgMgr in ${OSInfo[*]}; do
			if CheckObject "FILE" "${EachPkgMgr%:::*}" "NOPRINT"; then
				if CheckObject "PROG" "${EachPkgMgr#*:::}" "NOPRINT"; then
					echo "INSTALLED:::${EachPkgMgr#*:::}"
					return 0
				else
					echo "NOTINSTALLED:::${EachPkgMgr#*:::}"
					return 0
				fi
			fi
		done

		# MacOS is a special case.
		if CheckObject "ENV-s" "Darwin" "NOPRINT"; then
			if CheckObject "PROG" "brew" "NOPRINT"; then
				echo "INSTALLED:::brew"
				return 0
			else
				echo "NOTINSTALLED:::brew"
				return 0
			fi
		fi

		# Could not determine.
		echo "UNKNOWN"
		return 1
	}

	MyPkgMgr="$(GetPkgMgr)"
	case "${MyPkgMgr}" in

		"NOTINSTALLED:::brew")
			AttentionMessage "REDINFO" "Ascertained the local Package Manager should be \"${MyPkgMgr#*:::}\", though it is not installed." \
			GetYorN "Do you want to install \"${MyPkgMgr#*:::}\"?" "Yes" \
				&& CheckObject "PROG" "ruby" \
				&& CheckObject "PROG" "curl" \
				&& ruby -e "$(curl -fsSLm ${CURLMaxTime} -X GET -H "Cache-Control: no-cache" https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				&& CheckObject "PROG" "${MyPkgMgr#*:::}" \
				&& ExecuteInstall "${MyPkgMgr#*:::}"
				AttentionMessage "GENERALINFO" "Auto installation of required packages reported code \"$?\"."
			AttentionMessage "GENERALINFO" "Run \"${MyName[0]}\" again without options to check validity of installed programs."
			GoToExit "7"
		;;

		"NOTINSTALLED:::"*)
			GoToExit "3" "Ascertained the local Package Manager should be \"${MyPkgMgr#*:::}\", though it is not installed. You must install required programs manually."
		;;

		"INSTALLED:::"*)
			AttentionMessage "GENERALINFO" "Ascertained the local Package Manager is \"${MyPkgMgr#*:::}\"."
			ExecuteInstall "${MyPkgMgr#*:::}"
			AttentionMessage "GENERALINFO" "Auto installation of required packages reported code \"$?\"."
			GoToExit "7"
		;;

		*)
			GoToExit "3" "Could not ascertain the local Package Manager. You must install required programs manually."
		;;

	esac
}

#################################################################################
# A series of checks prior to program launch.
function CheckingChain() {
	! CheckObject "PROG" "bash" \
		&& GoToExit "3" "BASH is a REQUIRED yet NOT INSTALLED Shell Processor."
	! CheckObject "PROG" "ls" \
		&& GoToExit "3" "LS is a REQUIRED yet NOT INSTALLED utility to list files and directories."
	! CheckObject "PROG" "cat" \
		&& GoToExit "3" "CAT is a REQUIRED yet NOT INSTALLED utilities to read and print text in files."
	! CheckObject "PROG" "grep" \
		&& GoToExit "3" "AWK is a REQUIRED yet NOT INSTALLED utility to parse text strings with pattern matching."
	! CheckObject "PROG" "awk" \
		&& GoToExit "3" "GREP is a REQUIRED yet NOT INSTALLED utility to parse text strings with pattern matching."
	! CheckObject "PROG" "date" \
		&& GoToExit "3" "DATE is a REQUIRED yet NOT INSTALLED utility to get/set the current time and date."
	! CheckObject "PROG" "touch" \
		&& GoToExit "3" "TOUCH is a REQUIRED yet NOT INSTALLED utility to create an empty file in the relative runtime directory."
	! CheckObject "PROG" "wc" \
		&& GoToExit "3" "WC is a REQUIRED yet NOT INSTALLED utility to count lines in a text file."
	! CheckObject "PROG" "find" \
		&& GoToExit "3" "FIND is a REQUIRED yet NOT INSTALLED utility to find files and folders in a directory structure."
	! CheckObject "PROG" "stat" \
		&& GoToExit "3" "STAT is a REQUIRED yet NOT INSTALLED utility to check statistics of files and directories."

	# Checking Chain - Secondary Critical - Not commonly part of the launching BASH program and Distro.
	! CheckObject "PROG" "jq" \
		&& GoToExit "3" "JQ is a REQUIRED yet NOT INSTALLED JSON Processor which is required to interact with the API System."
	! CheckObject "PROG" "curl" \
		&& GoToExit "3" "CURL is a REQUIRED yet NOT INSTALLED utility to transfer data from or to the API System."
	! CheckObject "PROG" "gpg" \
		&& GoToExit "3" "GPG is a REQUIRED yet NOT INSTALLED utility to securely encrypt/decrypt files with a password."
	! CheckObject "PROG" "bc" \
		&& GoToExit "3" "BC is a REQUIRED yet NOT INSTALLED utility to enhance calculations of floating point numbers."
	! CheckObject "PROG" "openssl" \
		&& GoToExit "3" "OPENSSL is a REQUIRED yet NOT INSTALLED utility to interact with cryptology in TLS and other standards."

	# Checking Chain - Secondary Critical - Specific to MacOS and BREW.
	if CheckObject "ENV-s" "Darwin" "NOPRINT"; then
		! CheckObject "FILE" "/usr/local/bin/gdate" \
			&& GoToExit "3" "GDATE is a REQUIRED yet NOT INSTALLED MACOS utility to get/set the current time and date." \
			|| alias date=/usr/local/bin/gdate # GDATE is required vs BSD DATE on MACOS.
		! CheckObject "FILE" "/usr/local/bin/gfind" \
			&& GoToExit "3" "GFIND is a REQUIRED yet NOT INSTALLED utility to find files and folders in a directory structure." \
			|| alias find=/usr/local/bin/gfind # GFIND is required vs BSD GREP on MACOS.
		! CheckObject "FILE" "/usr/local/bin/ggrep" \
			&& GoToExit "3" "GGREP is a REQUIRED yet NOT INSTALLED MACOS utility to parse text strings with pattern matching." \
			|| alias grep=/usr/local/bin/ggrep # GGREP is required vs BSD GREP on MACOS.
		! CheckObject "FILE" "/usr/local/bin/gawk" \
			&& GoToExit "3" "GAWK is a REQUIRED yet NOT INSTALLED MACOS utility to parse text strings with pattern matching." \
			|| alias grep=/usr/local/bin/gawk # GGREP is required vs BSD GREP on MACOS.
	fi

	# Checking Chain - Determine SHA1 executable.
	SHA1Exec=$(which shasum 2>/dev/null || which sha1sum 2>/dev/null)
	[[ ${SHA1Exec:-ERROR} == "ERROR" ]] \
		&& GoToExit "3" "SHASUM/SHA1SUM is a REQUIRED yet NOT INSTALLED utility to determine the hash of a file."

	# Checking Chain - Get the SHASUM hash of the main file from GITHUB and compare to the local hash.
	if [[ ${CheckGITVersion:-TRUE} == "TRUE" ]]; then
		SHA1HASH_GIT=$( (curl -fsSLm ${CURLMaxTime} -X GET -H "Cache-Control: no-cache" "${MyGitHubRAWURL}" 2>/dev/null || echo ERROR) | ${SHA1Exec} 2>/dev/null)
		SHA1HASH_LOCAL=$(${SHA1Exec} ${MyName[1]} 2>/dev/null)
		AttentionMessage "DEBUG" "UpdateCheck: GIT=\"${SHA1HASH_GIT%% *}\", LOCAL=\"${SHA1HASH_LOCAL%% *}\""
		if [[ "${SHA1HASH_GIT%% *}" == '709c7506b17090bce0d1e2464f39f4a434cf25f1' ]]; then
			AttentionMessage "REDINFO" "An error occurred when trying to obtain the HASH of the GIT repository - please report!"
			GetYorN "SPECIAL-PAUSE"
		elif [[ "${SHA1HASH_GIT%% *}" != "${SHA1HASH_LOCAL%% *}" ]]; then
			AttentionMessage "YELLOWINFO" "A new version of \"${MyName[0]}\" is available to clone, please update!"
			GetYorN "SPECIAL-PAUSE"
		fi
	else
		AttentionMessage "YELLOWINFO" "Bypassing repo check for version delta."
	fi

}

#################################################################################
# A primary loop to determine ORGANIZATION and NETWORK.
function InteractiveLoop() {
	while true; do
		SelectOrganization
		while true; do
			SelectNetwork \
				&& break 2 \
				|| break
		done
	done
}

#################################################################################
# Usage and help menu.
function GeneralHelp() {
	echo "${MyName[0]} -h/-H     ::: This Usage and Help Menu."
	echo "${MyName[0]} -N        ::: Do not check the repo for a version delta."
	echo "${MyName[0]} -X        ::: Use Local Package Manager - Install All Required Programs."
	echo "${MyName[0]}           ::: All Defaults (Interactive SAFE Select, Enable Text Decoration, Interactive Mode)"
	echo "${MyName[0]} -S        ::: Begin with Interactive Secure Authenticated File Enclave (SAFE) Select. [DEFAULT]"
	echo "${MyName[0]} -s [FILE] ::: Begin with PreSelected Secure Authenticated File Enclave (SAFE)."
	echo "${MyName[0]} -P        ::: Enable Text Decoration. [DEFAULT]"
	echo "${MyName[0]} -p        ::: Limit Text Decoration."
	echo "${MyName[0]} -t [TOKEN]::: Instead of a SAFE, user provides the Console Bearer Token for the session."
	echo "${MyName[0]} -T        ::: Include Teaching Information."
	echo "${MyName[0]} -I        ::: Interactive Mode. [DEFAULT]"
	echo "${MyName[0]} -B [FILE] ::: Bulk Endpoint Creation Mode. Applies [-L]."
	echo "${MyName[0]} -b        ::: Bulk Endpoint Creation Sub-Usage and Help Menu."
	echo "${MyName[0]} -D        ::: Enable Debug Messages."
	echo "${MyName[0]} -q        ::: Quiet(er) Printing Mode."
	echo "${MyName[0]} -M [????] ::: Point API Access towards [production/staging]. [default=production]"
	echo
}

#######################################################################################
# MAIN FUNCTION
#######################################################################################
function LaunchMAIN() {
	IFS=$'\n' # Field Separation locked only to newline for the entire program.
	#export LC_ALL="en_US.UTF-8" # Ensure characters can actually be printed by setting the appropriate locale.
	SetLimitFancy "FALSE"

	# Begin checking.
	! CheckObject "PROG" "whoami" \
		&& GoToExit "3" "WHOAMI is a REQUIRED yet NOT INSTALLED effective user reporting utility."
	! CheckObject "USER" "root" \
		&& GoToExit "3" "Your current user is ROOT. Please run this program as a non-elevated user."
	! CheckObject "PROG" "tput" \
		&& GoToExit "3" "TPUT is a REQUIRED yet NOT INSTALLED terminal window manipulation utility."
	! CheckObject "SCWD" "$((150-$(tput cols)))" \
		&& AttentionMessage "WARNING" "Your screen width is \"$(tput cols)\" columns, which is less than \"150\" columns and may cause some screen printing artifacts." \
		&& sleep 5
	! CheckObject "PROG" "uname" \
		&& GoToExit "3" "UNAME is a REQUIRED yet NOT INSTALLED OS name and detail printer."
	! CheckObject "PROG" "sudo" \
		&& GoToExit "3" "SUDO is a REQUIRED yet NOT INSTALLED super user elevation program."
	CheckObject "ENV-v" "Microsoft" "NOPRINT" \
		&& AttentionMessage "GREENINFO" "Detected Microsoft Windows Subsystem for Linux (WSL), limiting text decoration." \
		&& SetLimitFancy "WSL"

	# Get options from command line.
	while getopts "HhNXSs:Ppt:TIB:bDqM:" ThisOpt 2>/dev/null; do
		case ${ThisOpt} in
			"H"|"h")
				SetLimitFancy "TRUE"
				FancyPrint "PLAINLOGO"
				AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Usage and Help."
				GeneralHelp
				GoToExit "5"
			;;
			"N")
				CheckGITVersion="FALSE"
			;;
			"X")
				SetLimitFancy "TRUE"
				AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Package Installation Mode (PID:\"${ParentPID:-ERROR}\")."
				AutoInstallPackages
				GoToExit "3" "An unspecified error occurred." # Should exit before this.
			;;
			"S")
				SAFEFile="MENU"
			;;
			"s")
				SAFEFile="${OPTARG}"
			;;
			"P")
				SetLimitFancy "FALSE"
			;;
			"p")
				SetLimitFancy "TRUE"
			;;
			"t")
				NFN_BEARER=( "${OPTARG}" "RETAIN" )
			;;
			"T")
				TeachMode="TRUE"
			;;
			"I")
				ThisMode="INTERACTIVE"
			;;
			"B")
				SetLimitFancy "TRUE"
				QuietPrint="TRUE"
				AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Bulk Endpoint Creation Mode (PID:\"${ParentPID:-ERROR}\")."
				BulkImportFile="${OPTARG}"
				if [[ -e ${BulkImportFile:-NOTSET} ]]; then
					ThisMode="BULKCREATEENDPOINTS"
				else
					GoToExit "1" "Bulk import reported invalid/missing file \"${BulkImportFile}\"."
				fi
			;;
			"b")
				FancyPrint "PLAINLOGO"
				AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Bulk Endpoint Creation Usage and Help."
				BulkCreateHelp
				GoToExit "7"
			;;
			"D")
				DebugInfo="TRUE"
			;;
			"q")
				QuietPrint="TRUE"
			;;
			"M")
				APIMOP="${OPTARG}"
			;;
			*)
				AttentionMessage "ERROR" "Invalid Options."
				AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Usage and Help."
				GeneralHelp
				GoToExit "5" "Invalid input options."
			;;
		esac
	done

	# General usage of the program.
	if [[ ${ThisMode} == "INTERACTIVE" ]]; then
		TrackLastTouch "INITIATE" & # Kick off the idle tracker.
		FancyPrint "ENTERLOGO"
		AttentionMessage "GREENINFO" "\"${MyName[0]}\" - NetFoundry Custom API Interface Utility - Interactive Mode (PID:\"${ParentPID:-ERROR}\")."
	fi

	# Current warranty and licensing statements.
	AttentionMessage "GENERALINFO" "${MyWarranty}"
	AttentionMessage "GENERALINFO" "${MyLicense}"
	AttentionMessage "GENERALINFO" "Please See: ${MyGitHubURL}"

	# Checking Chain - Primary Critical - Expected to be part of the launching BASH program and Distro.
	CheckingChain

	# Perform startup functions for ensuring variables are ready.
	if [[ ${NFN_BEARER-:UNSET} != "UNSET" ]]; then
		AttentionMessage "GENERALINFO" "Console Bearer Token passed in. API SAFE not required."
	elif [[ ${SAFEFile} == "UNSET" ]]; then
		ObtainSAFE "MENU"
	elif [[ ${SAFEFile} == "MENU" ]]; then
		ObtainSAFE "MENU"
	else
		ObtainSAFE "${SAFEFile}"
	fi

	# Check the access token.
	CheckBearerToken

	# Determine path.
	if [[ ${ThisMode} == "INTERACTIVE" ]]; then
		InteractiveLoop
	elif [[ ${ThisMode} == "BULKCREATEENDPOINTS" ]]; then
		CurrentPath="/BulkCreateEndpoints"
		BulkCreateEndpoints "${BulkImportFile}" \
			&& GoToExit "7" \
			|| GoToExit "7" "Bulk Endpoint creation was not fully successful. Check the output log for more information."
	fi

	V7_AllMainOptions=( \
		"Listings"
		"Moving Adding Changing Deleting Objects"
	)
	V6_AllMainOptions=( \
		"Listings"
		"Macros"
		"Reports"
		"Moving Adding Changing Deleting Objects"
	)
	V6_AllListOptions=( \
		"List Endpoints"
		"List EndpointGroups"
		"List Services"
		"List AppWANs"
		"List GeoRegions"
		"List Countries"
	)
	V7_AllListOptions=( \
		"List Endpoints (D2C)"
		#"List Endpoints"
		"List EdgeRouters (D2C)"
		#"List EdgeRouters"
		#"List Services (D2C)"
		#"List Services"
		"List Enrollments (D2C)"
		#"List Enrollments"
		"List Versions (D2C)"
		#"List Versions"
	)
	V6_AllMACDOptions=( \
		"Modify AppWAN Associations"
		"Modify EndpointGroup Associations"
		"Create New Endpoint"
		"Create New AppWAN"
		"Create New EndpointGroup"
		"Change Endpoint Name"
		"Change EndpointGroup Name"
		"Change Service Name"
		"Change AppWAN Name"
		"Delete Existing Endpoint"
		"Delete Existing EndpointGroup"
	)
	V7_AllMACDOptions=( \
		"Create New Endpoint"
	)	
	V6_AllMacroOptions=( \
		"Add Internet Services to Gateway Endpoint"
		"Bulk Create Endpoints"
	)
	V6_AllReportOptions=( \
		"Report Endpoint Events"
		"Report Endpoint Usage"
		"Report Endpoints Last Activity"
		"Report Network Usage"
	)
	V6_FollowEndpoint=( \
		"EndpointGroups"
		"AppWANs"
		"Services (Provided-By)"
		"Services (Accessible-By)"
		"All"
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V7_FollowEndpoint=( \
		"Services (Provided-By)"
		"Services (Accessible-By)"
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V7_FollowEdgeRouter=( \
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V7_FollowEnrollments=( \
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V6_FollowEndpointGroup=( \
		"Endpoints"
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V6_FollowService=( \
		"Endpoints"
		"AppWANs"
		"All"
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V7_FollowService=( \
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V6_FollowAppWAN=( \
		"Endpoints and EndpointGroups"
		"Services"
		"All"
		"No Associations - Simple List"
		"No Associations - Derive Detail"
	)
	V6_FollowGeoRegions=( \
		"No Associations - Simple List"
	)
	V6_FollowCountries=( \
		"GeoRegion"
		"No Associations - Simple List"
	)

	# Interactive main loop.
	while true; do
		CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MainSelection"

		if [[ ${Target_NETWORK[1]} =~ ^"(V7)" ]]; then

			# If the V7 Controller metadata has been stored, show those options.
			if [[ -n ${NetworkMetadata_V7C[0]} ]]; then
				! GetSelection "Select an operation to perform in Network \"${Target_NETWORK[1]}\"." "${V7_AllMainOptions[*]}${NewLine}${V7_AllMainOptionsD2C[*]}" "NONE" \
					&& InteractiveLoop
			else
				! GetSelection "Select an operation to perform in Network \"${Target_NETWORK[1]}\"." "${V7_AllMainOptions[*]}" "NONE" \
					&& InteractiveLoop
			fi

			case "${UserResponse}" in

				"Listings")
					while true; do

						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing"
						! GetSelection "Select the type of List to review in Network \"${Target_NETWORK[1]}\"." "${V7_AllListOptions[*]}" "NONE" \
							&& break

						case "${UserResponse}" in

							"List Endpoints (D2C)")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/Endpoints/AndFollow"
									! GetSelection "Select Endpoint associations to follow." "${V7_FollowEndpoint[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"Services (Provided-By)")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated Services (Provided-By) in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "ENDPOINTS" "FOLLOW-PSERVICES"
										;;
										"Services (Accessible-By)")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated Services (Accessible-By) in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "ENDPOINTS" "FOLLOW-ASERVICES"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "ENDPOINTS"
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/Endpoints/DeriveDetail"
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "DERIVE-ENDPOINT" 2>/dev/null
										;;
									esac
								done
							;;

							"List Endpoints")
								AttentionMessage "YELLOWINFO" "Function not yet implemented." && continue
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Endpoints/AndFollow"
									! GetSelection "Select Endpoint associations to follow." "${V7_FollowEndpoint[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"Services (Accessible-By)")
											:
										;;
										"No Asociations - Simple List")
											:
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Endpoints/DeriveDetail"
											:
										;;
									esac
								done
							;;

							"List EdgeRouters (D2C)")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/EdgeRouters/AndFollow"
									! GetSelection "Select EdgeRouter associations to follow." "${V7_FollowEdgeRouter[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EdgeRouters in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "EDGEROUTERS"
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/EdgeRouters/DeriveDetail"
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EdgeRouters in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "DERIVE-EDGEROUTERS" 2>/dev/null
										;;
									esac
								done
							;;

							"List EdgeRouters")
								AttentionMessage "YELLOWINFO" "Function not yet implemented." && continue
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/EdgeRouters/AndFollow"
									! GetSelection "Select EdgeRouter associations to follow." "${V7_FollowEdgeRouter[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Asociations - Simple List")
											:
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/EdgeRouters/DeriveDetail"
											:
										;;
									esac
								done
							;;

							"List Services (D2C)")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Services/AndFollow"
									! GetSelection "Select Service associations to follow." "${V7_FollowService[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "SERVICES"
										;;
										"No Associations - Derive Detail")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "DERIVE-SERVICE" 2>/dev/null
										;;
									esac
								done
							;;

							"List Services")
								AttentionMessage "YELLOWINFO" "Function not yet implemented." && continue
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Services/AndFollow"
									! GetSelection "Select Service associations to follow." "${V7_FollowService[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Associations - Simple List")
											:
										;;
										"No Associations - Derive Detail")
											:
										;;
									esac
								done
							;;

							"List Enrollments (D2C)")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/Enrollments/AndFollow"
									! GetSelection "Select Enrollment associations to follow." "${V7_FollowEnrollments[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Enrollments in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "ENROLLMENTS"
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/Enrollments/DeriveDetail"
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Enrollments in Network \"${Target_NETWORK[1]}\"."
											GetObjects_V7C "DERIVE-ENROLLMENTS" 2>/dev/null
										;;
									esac
								done
							;;

							"List Enrollments")
								AttentionMessage "YELLOWINFO" "Function not yet implemented." && continue
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Enrollments/AndFollow"
									! GetSelection "Select Enrollment associations to follow." "${V7_FollowEnrollments[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Asociations - Simple List")
											:
										;;
										"No Associations - Derive Detail")
											CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Enrollments/DeriveDetail"
											:
										;;
									esac
								done
							;;

							"List Versions (D2C)")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/ListingD2C/Versions"
									! GetFilterString \
										&& continue
									AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Versions in Network \"${Target_NETWORK[1]}\"."
									GetObjects_V7C "VERSIONS"
									break
								done
							;;

							"List Versions")
								AttentionMessage "YELLOWINFO" "Function not yet implemented." && continue
							;;

						esac

					done
				;;

				"Moving Adding Changing Deleting Objects")
					while true; do

						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD"
						! GetSelection "Perform what type of MACD operation?" "${V7_AllMACDOptions[*]}" "NONE" \
							&& break
						case "${UserResponse}" in

							"Create New Endpoint")
								CreateEndpoints_V7
							;;

						esac
					done
				;;


			esac

		elif [[ ${Target_NETWORK[1]} =~ ^"(V6)" ]]; then

			! GetSelection "Select an operation to perform in Network \"${Target_NETWORK[1]}\"." "${V6_AllMainOptions[*]}" "NONE" \
				&& InteractiveLoop
			case "${UserResponse}" in

				"Listings")
					while true; do

						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing"
						! GetSelection "Select the type of List to review in Network \"${Target_NETWORK[1]}\"." "${V6_AllListOptions[*]}" "NONE" \
							&& break
						case "${UserResponse}" in

							"List Endpoints")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Endpoints/AndFollow"
									! GetSelection "Select Endpoint associations to follow." "${V6_FollowEndpoint[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"EndpointGroups")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated EndpointGroups in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS" "FOLLOW-ENDPOINTGROUPS"
										;;
										"AppWANs")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS" "FOLLOW-APPWANS"
										;;
										"Services (Provided-By)")
											AttentionMessage "GENERALINFO" "Be aware, only Gateway Endpoints provide Services."
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Gateway Endpoints and associated Services (Provided-By) in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS" "FOLLOW-PSERVICES"
										;;
										"Services (Accessible-By)")
											AttentionMessage "GENERALINFO" "Be aware, this function iterates through deep links such as EPT>EPG>APW>SRV or EPT>APW>SRV."
											AttentionMessage "GENERALINFO" "It is advised that you limit your critiera with a good filter."
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated Services (Accessible-By) in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS" "FOLLOW-ASERVICES"
										;;
										"All")
											AttentionMessage "GENERALINFO" "Be aware, \"All\" only reports direct associations such as EPT>APW or EPT>EPG or EPT>SRV."
											AttentionMessage "GENERALINFO" "If you are looking for linked associations such as EPT>EPG>APW>SRV or EPT>APW>SRV, use the \"Accessible-By\" function."
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints and associated EndpointGroups, Services, and AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS" "FOLLOW-ALL"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTS"
										;;
										"No Associations - Derive Detail")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "DERIVE-ENDPOINT" 2>/dev/null
										;;
									esac
								done
							;;

							"List EndpointGroups")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/EndpointGroups/AndFollow"
									! GetSelection "Select EndpointGroup associations to follow." "${V6_FollowEndpointGroup[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"Endpoints")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups and associated Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTGROUPS" "FOLLOW-ENDPOINTS"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "ENDPOINTGROUPS"
										;;
										"No Associations - Derive Detail")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "DERIVE-ENDPOINTGROUP" 2>/dev/null
										;;
									esac
								done
							;;

							"List Services")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Services/AndFollow"
									! GetSelection "Select Service associations to follow." "${V6_FollowService[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"Endpoints")
											AttentionMessage "GENERALINFO" "Be aware, this function shows the provider Gateway Endpoint for each Service."
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services and associated Endpoints in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "SERVICES" "FOLLOW-ENDPOINTS"
										;;
										"AppWANs")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services and associated AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "SERVICES" "FOLLOW-APPWANS"
										;;
										"All")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services and associated Endpoints and AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "SERVICES" "FOLLOW-ALL"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "SERVICES"
										;;
										"No Associations - Derive Detail")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "DERIVE-SERVICE" 2>/dev/null
										;;
									esac
								done
							;;

							"List AppWANs")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/AppWANs/AndFollow"
									! GetSelection "Select AppWAN associations to follow." "${V6_FollowAppWAN[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"Services")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs and associated Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "APPWANS" "FOLLOW-SERVICES"
										;;
										"Endpoints and EndpointGroups")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs and associated Endpoints and EndpointGroups in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "APPWANS" "FOLLOW-ENDPOINTGROUPS_ENDPOINTS"
										;;
										"All")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs and associated Endpoints, EndpointGroups, and Services in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "APPWANS" "FOLLOW-ALL"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "APPWANS"
										;;
										"No Associations - Derive Detail")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs in Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "DERIVE-APPWAN" 2>/dev/null
										;;
									esac
								done
							;;

							"List GeoRegions")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/GeoRegions"
									! GetSelection "Select GeoRegion associations to follow." "${V6_FollowGeoRegions[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of GeoRegions allowed for Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "GEOREGIONS"
										;;
									esac
								done
							;;

							"List Countries")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Listing/Countries"
									! GetSelection "Select Country associations to follow." "${V6_FollowCountries[*]}" "NONE" \
										&& break
									case "${UserResponse}" in
										"GeoRegion")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Countries and associated GeoRegions allowed for Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "COUNTRIES" "FOLLOW-GEOREGION"
										;;
										"No Associations - Simple List")
											! GetFilterString \
												&& continue
											AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Countries allowed for Network \"${Target_NETWORK[1]}\"."
											GetObjects_MOP "COUNTRIES"
										;;
									esac
								done
							;;
						esac
					done
				;;

				"Macros")
					while true; do
						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Macros"
						! GetSelection "Select the type of Macro to perform." "${V6_AllMacroOptions[*]}" "NONE" \
							&& break
						case "${UserResponse}" in
							"Add Internet Services to Gateway Endpoint")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Macros/AddInternetServices"
								RunMacro "CREATEINTERNETSERVICES"
							;;
							"Bulk Create Endpoints")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Macros/BulkCreateEndpoints"
								RunMacro "BULKCREATEENDPOINTS"
							;;
						esac
					done
				;;

				"Reports")
					while true; do

						AttentionMessage "GENERALINFO" "PLEASE NOTE: All report queries are limited to 10,000 results."

						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Reports"
						! GetSelection "Select the type of Report to perform." "${V6_AllReportOptions[*]}" "NONE" \
							&& break
						case "${UserResponse}" in

							"Report Endpoint Events")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Reports/EndpointEvents"
									! GetFilterString "Your filter input applies to only elements in the \"${Target_NETWORK[1]}\" Network which the Console Bearer Token permits access to." \
										&& break
									AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of criteria matching Endpoints in Network \"${Target_NETWORK[1]}\"."
									GetObjects_MOP "ENDPOINTS" &>/dev/null
									AllEndpoints=( ${AllEndpoints[*]/???:::/} )
									! GetSelection "Select the target Endpoint for the report." "${AllEndpoints[*]}" "NONE" \
										&& break
									! RunEventReport "${UserResponse}" \
										&& break
								done
							;;

							"Report Endpoint Usage")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Reports/EndpointUsage"
									! GetFilterString "Your filter input applies to only elements in the \"${Target_NETWORK[1]}\" Network which the Console Bearer Token permits access to." \
										&& break
									AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of criteria matching Endpoints in Network \"${Target_NETWORK[1]}\"."
									GetObjects_MOP "ENDPOINTS" &>/dev/null
									AllEndpoints=( ${AllEndpoints[*]/???:::/} )
									! GetSelection "Select the target Endpoint for the report." "${AllEndpoints[*]}" "NONE" \
										&& continue
									! RunUsageReport "${UserResponse}" \
										&& break
								done
							;;

							"Report Endpoints Last Activity")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Reports/EndpointsLastActivity"
									! RunLastActivityReport "${UserResponse}" \
										&& break
								done
							;;

							"Report Network Usage")
								while true; do
									CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/Reports/NetworkUsage"
									AllEndpoints=( ${AllEndpoints[*]/???:::/} )
									! RunUsageReport "WHOLENETWORK" \
										&& break
								done
							;;

						esac

					done
				;;

				"Moving Adding Changing Deleting Objects")
					while true; do

						CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD"
						! GetSelection "Perform what type of MACD operation?" "${V6_AllMACDOptions[*]}" "NONE" \
							&& break
						case "${UserResponse}" in

							"Modify AppWAN Associations")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ModifyAppWANAssociations"
								! GetFilterString "Narrow the AppWANs for modification selection." \
									&& continue
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "APPWANS" &>/dev/null
								while true; do
									! GetSelection "Select AppWAN to target for modification selection." "${AllAppWANs[*]}" "NONE" \
										&& break
									ModifyEndpointAssociations "APPWAN" "${UserResponse}"
								done
							;;

							"Modify EndpointGroup Associations")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ModifyEndpointGroupAssociations"
								! GetFilterString "Narrow the EndpointGroups for modification selection." \
									&& continue
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "ENDPOINTGROUPS" &>/dev/null
								while true; do
									! GetSelection "Select EndpointGroup to target for modification selection." "${AllEndpointGroups[*]}" "NONE" \
										&& break
									ModifyEndpointAssociations "ENDPOINTGROUP" "${UserResponse}"
								done
							;;

							"Create New Endpoint")
								CreateEndpoints_V6
							;;

							"Create New AppWAN")
								CreateAppWAN
							;;

							"Create New EndpointGroup")
								CreateEndpointGroup
							;;

							"Change Endpoint Name")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ChangeEndpointName"
								! GetFilterString \
									&& break
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Endpoints in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "ENDPOINTS" &>/dev/null
								AllEndpoints=( ${AllEndpoints[*]/???:::/} )
								while true; do
									! GetSelection "Select an Endpoint to target for name change." "${AllEndpoints[*]}" "NONE" \
										&& break
									ChangeObjectName "ENDPOINT" "${UserResponse##*:::}"
								done
							;;

							"Change EndpointGroup Name")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ChangeEndpointGroupName"
								! GetFilterString \
									&& break
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of EndpointGroups in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "ENDPOINTGROUPS" &>/dev/null
								while true; do
									! GetSelection "Select an EndpointGroup to target for name change." "${AllEndpointGroups[*]}" "NONE" \
										&& break
									ChangeObjectName "ENDPOINTGROUP" "${UserResponse}"
								done
							;;

							"Change Service Name")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ChangeServiceName"
								! GetFilterString \
									&& break
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of Services in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "SERVICES" &>/dev/null
								while true; do
									! GetSelection "Select a Service to target for name change." "${AllServices[*]}" "NONE" \
										&& break
									ChangeObjectName "SERVICE" "${UserResponse// (TYPE:*)/}"
								done
							;;

							"Change AppWAN Name")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/ChangeAppWANName"
								! GetFilterString \
									&& break
								AttentionMessage "GENERALINFO" "The following is a list (FILTER [${PrimaryFilterString:-.}]) of AppWANs in Network \"${Target_NETWORK[1]}\"."
								GetObjects_MOP "APPWANS" &>/dev/null
								while true; do
									! GetSelection "Select an AppWAN to target for name change." "${AllAppWANs[*]}" "NONE" \
										&& break
									ChangeObjectName "APPWAN" "${UserResponse}"
								done
							;;

							"Delete Existing Endpoint")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/DeleteEndpoints"
								DeleteEndpoints
							;;

							"Delete Existing EndpointGroup")
								CurrentPath="/${Target_ORGANIZATION[1]}/${Target_NETWORK[1]}/MACD/DeleteEndpointGroups"
								DeleteEndpointGroups
							;;
						esac
					done
				;;
			esac

		fi
	done
}

#######################################################################################
# MAIN
#######################################################################################
LaunchMAIN "${@}"

###################################################################################################################
# EOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOF #
###################################################################################################################