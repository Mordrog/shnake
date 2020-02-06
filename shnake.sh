declare -A board

BOARD_WIDTH=30
BOARD_HEIGHT=20

border_color="\e[30;43m"
snake_color="\e[32;42m"
food_color="\e[34;41m"
no_color="\e[0m"

# signals
SIG_UP=USR1
SIG_RIGHT=USR2
SIG_DOWN=URG
SIG_LEFT=IO
SIG_QUIT=WINCH
SIG_DEAD=HUP

running=true

score=0

snake_direction_x=0
snake_direction_y=1
snake_length=1
snake_x=(15)
snake_y=(5)

help=(
"q: quit a: left, d: right, w: up, s: down"
)


init_board() {
	for ((y=1;y<=BOARD_HEIGHT;y++)) do
		for ((x=0;x<=BOARD_WIDTH;x++)) do
			if [ $x = 1 ] || [ $y = 1 ] || [ $x = $BOARD_WIDTH ] || [ $y = $BOARD_HEIGHT ]; then
				board[$x,$y]="w"
			else
				board[$x,$y]=" "
			fi
		done
	done
}

draw() {
	x1=$((${1} * 2))
	x2=$((${1} * 2 + 1))
	y1=$((${2}))
	y2=$((${2}))
	echo -ne "\e[${y1};${x1}H$3"
	echo -ne "\e[${y2};${x2}H$3"
}

render() {
	for ((y=1;y<=BOARD_HEIGHT;y++)) do
		for ((x=1;x<=BOARD_WIDTH;x++)) do
			if [ "${board[$x,$y]}" = "s" ]; then
				draw ${x} ${y} "${snake_color} $no_color"
			elif [ "${board[$x,$y]}" = "w" ]; then
				draw ${x} ${y} "${border_color} $no_color"
			elif [ "${board[$x,$y]}" = "f" ]; then
				draw ${x} ${y} "${food_color} $no_color"
			else
				draw ${x} ${y} "${no_color} $no_color"
			fi
		done
	done
	echo
	draw 32 2 "${no_color} Score: ${score}$no_color"
	draw 34 6 "${no_color} ^$no_color"
	draw 34 7 "${no_color} w$no_color"
	draw 34 9 "${no_color} s$no_color"
	draw 34 10 "${no_color} v$no_color"
	draw 32 8 "${no_color} < a$no_color"
	draw 35 8 "${no_color} d >$no_color"
	draw 33 12 "${no_color} q quit$no_color"
	echo
}

check_hit_wall(){
	if [ $1 = 1 ] || [ $1 = $BOARD_WIDTH ] || [ $2 = 1 ] || [ $2 = $BOARD_HEIGHT ]; then
		return 0
	else
		return 1
	fi
}

check_hit_snake(){
	if [ "${board[$1,$2]}" = "s" ]; then
		return 0
	else
		return 1
	fi
}

check_hit_food(){
	if [ "${board[$1,$2]}" = "f" ]; then
		return 0
	else
		return 1
	fi
}

generate_food(){
	random_position_x=$(( ( RANDOM % (BOARD_WIDTH - 2) )  + 2 ))
	random_position_y=$(( ( RANDOM % (BOARD_HEIGHT - 2) )  + 2 ))
	
	while check_hit_snake $random_position_x $random_position_y
	do
		random_position_x=$(( ( RANDOM % (BOARD_WIDTH - 2) )  + 2 ))
		random_position_y=$(( ( RANDOM % (BOARD_HEIGHT - 2) )  + 2 ))
		echo retry
	done
	
	board[$random_position_x,$random_position_y]="f"
}


move(){
	next_head_position_x=$((snake_x[0] + snake_direction_x))
	next_head_position_y=$((snake_y[0] + snake_direction_y))
	tail_position_x=$((snake_x[snake_length-1]))
	tail_position_y=$((snake_y[snake_length-1]))
	
	if check_hit_wall $next_head_position_x $next_head_position_y; then
		running=false
		return
	fi
	
	if check_hit_snake $next_head_position_x $next_head_position_y; then
		running=false
		return
	fi
	
	if [ $snake_length != 0 ]; then
		for ((i=snake_length-1;i>0;i--)) do
			next_i=$((i-1))
			snake_x[$i]=${snake_x[next_i]}
			snake_y[$i]=${snake_y[next_i]}
		done
	fi
	
	if check_hit_food $next_head_position_x $next_head_position_y; then
		score=$((score + 10))
		snake_x[$snake_length]=$tail_position_x
		snake_y[$snake_length]=$tail_position_y
		board[$tail_position_x,$tail_position_y]="s"
		snake_length=$((snake_length + 1))
		generate_food
	else
		board[$tail_position_x,$tail_position_y]=" "
	fi

	snake_x[0]=$next_head_position_x
	snake_y[0]=$next_head_position_y
	board[$next_head_position_x,$next_head_position_y]="s"
}



inputloop() {
	trap "" SIGINT SIGQUIT
	trap "return;" $SIG_DEAD
	while true; do
		read -s -n 1 key
		case "$key" in
			[qQ]) kill -$SIG_QUIT $game_pid
				return
				;;
			[wW]) kill -$SIG_UP $game_pid
				;;
			[dD]) kill -$SIG_RIGHT $game_pid
				;;
			[sS]) kill -$SIG_DOWN $game_pid
				;;
			[aA]) kill -$SIG_LEFT $game_pid
				;;
		esac
	done
}


gameloop(){
    trap "direction=1;" $SIG_RIGHT
    trap "direction=2;" $SIG_LEFT
    trap "direction=3;" $SIG_UP
    trap "direction=4;" $SIG_DOWN
    trap "exit 1;" $SIG_QUIT

	while $running
	do
		if [ "$direction" = 1 ] && [ $snake_direction_x != -1 ]; then
            snake_direction_x=1
			snake_direction_y=0
		elif [ "$direction" = 2 ] && [ $snake_direction_x != 1 ]; then
            snake_direction_x=-1
			snake_direction_y=0
		elif [ "$direction" = 3 ] && [ $snake_direction_y != 1 ]; then
			snake_direction_x=0
			snake_direction_y=-1
		elif [ "$direction" = 4 ] && [ $snake_direction_y != -1 ]; then
			snake_direction_x=0
			snake_direction_y=1
		fi

		move
		render
		sleep 0.03
	done
	kill -$SIG_DEAD $$
}

tput civis #Makes cursor disappear
init_board
generate_food

gameloop &
game_pid=$!
inputloop

draw 13 10 "${border_color}-GameOver--$border_color"
read -s -n 1


exit 0
