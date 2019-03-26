#!/bin/bash

#SESSION=$USER
SESSION="test"

cd "../"
declare -a nodes=( one two three four )
ENTER="C-m"

port=15657

tmux -2 new-session -d -s $SESSION

tmux split-window -h

# Left panes
tmux select-pane -t 0
tmux split-pane -v
tmux split-pane -v
tmux select-pane -t 0
tmux split-pane -v

# Right panes
tmux select-pane -t 4
tmux split-pane -v
tmux split-pane -v
tmux select-pane -t 4
tmux split-pane -v


for i in {0..3};
do
        tmux select-pane -t $i
        tmux send-keys "eval apps/SimElevatorServer --port $(($port+$i))" $ENTER
done

tmux select-pane -t 4
for i in {0..3};
do
        tmux select-pane -t $(($i+4))
        tmux send-keys "eval rebar3 shell --config config/${nodes[$i]}.config --sname ${nodes[$i]} --setcookie bananpose --apps elevator" $ENTER
done

tmux -2 attach-session -t $SESSION
