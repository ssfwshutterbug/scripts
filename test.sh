#!/bin/bash

# this script used to automatically change wallpaper using swww,
# so at first we need to make sure swww-daemon exist & is running.
! which swww-daemon >/dev/null && echo "need install swww first" && exit
pgrep swww-daemon >/dev/null || swww-daemon &

# get and set some variables
SCRIPT_NAME=$(basename $0)
WALLPAPER_DIR=$HOME/daisy/picture/background
INTERVAL=900
LEN_PARA=$#
UNSPLASH="https://api.unsplash.com/photos/random?client_id=hXQTv7k4nzXZTDxn-_Gg-akObGlC1D7phd6n20YgtDU&count=1&orientation=landscape"
TMP_DIR="/tmp"
CURRENT_PID=$$

# show help message
help() {
	cat <<EOF
usage: wl_change_wallpaper [OPTION] [PICTURE_DIR]

    without specify wallpaper directory, we will use the default one: $WALLPAPER_DIR
    without specify time, we will use the default one: $INTERVAL (seconds)

    example: wl_wall -t 60 -d ~/background


[OPTION]:
    -h  show help message
    -d  set wallpaper directory
    -t  time interval to change wallpaper
    -n  get wallpaper from online(unsplash)
    -l  get wallpaper from local folder
    -s  save current online wallpaper to $WALLPAPER_DIR, used with -n
EOF
}

# check path exist or not
check_path() {
	[ ! -d $1 ] && echo "directory not exist!" && exit || WALLPAPER_DIR=$1
}

# end current process if exist
kill_process() {
	for i in $(pgrep $SCRIPT_NAME); do
		# needed to return 1, otherwise it will return 1 if nothing need to kill
		[ $i != $CURRENT_PID ] && kill $i || return 0
	done
}

# try to get wallpaper online, error fallback to use local picture
set_wall_online() {
	# if already exist tmp file, remove it
	file=$(fd --type f "tmp.*" /tmp)
	[ ! -z $file ] && echo $file | xargs rm

	# create tmp file to store image url
	TMP_FILE=$(mktemp)

	while true; do
		# clean /tmp folder existed phote
		fd -t f photo /tmp | xargs rm

		# wirte urls to temp file under /tmp
		urls=$(curl -s "$UNSPLASH" | jq -r '.[].urls')
		echo $urls >>$TMP_FILE

		url=$(echo $urls | jq -r '.regular')
		img_name=$(echo $url | cut -d'/' -f 4)
		timeout 6 wget -q --show-progress $url --directory-prefix=$TMP_DIR

		# generate color palate for waybar
		wal -n -s -l --saturate 0.5 -i $TMP_DIR/$img_name
		swww img $TMP_DIR/${img_name} || set_wall
		sleep ${INTERVAL:-900}
	done
}

# set local wallpaper
set_wall() {
	check_path $WALLPAPER_DIR
	while true; do
		img_name=$(ls $WALLPAPER_DIR | shuf -n 1)
		img_path=${WALLPAPER_DIR}/${img_name}

		# generate color palate for waybar
		wal -n -s -l --saturate 0.5 -i $img_path

		swww img $img_path
		sleep ${INTERVAL:-900}
	done
}

# get parameters if there is
# i find this method is much more simple, but seems cannot use double -, for example: "--help"
while getopts lhnt:d: f; do
	case $f in
	h) help && exit ;;
	t) INTERVAL=${OPTARG} ;;
	d) WALLPAPER_DIR=${OPTARG} ;;
	n) kill_process && set_wall_online ;;
	l) kill_process && set_wall ;;
	esac
done
shift $((OPTIND - 1))
