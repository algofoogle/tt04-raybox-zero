#!/usr/bin/bash

# For more info, see:
# - https://github.com/algofoogle/journal/blob/master/0131-2023-08-24.md
# - https://github.com/algofoogle/journal/blob/master/0132-2023-08-25.md

function log {
    echo "[$(date)] $*"
}

function logmark {
    echo ">>>"
    echo ">>>>>"
    echo ">>>>>>>"
    echo ">>>>>>>>> [$(date)] ---  $*"
    echo ">>>>>>>"
    echo ">>>>>"
    echo ">>>"
}

# Function to set Gnome terminal title. For more info, see:
# https://unix.stackexchange.com/a/186167
function set-title() {
  if [[ -z "$ORIG" ]]; then
    ORIG=$PS1
  fi
  TITLE="\[\e]2;$*\a\]"
  PS1=${ORIG}${TITLE}
}

if ! egrep '^  tiles:\s*"[48]x2"' info.yaml > /dev/null; then
    echo 'Cannot find an expected "tiles" parameter in info.yaml'
    exit 1
fi

if [ ! -f src/config.tcl ]; then
    echo 'Cannot find config.tcl'
    exit 1
fi

for file in info.yaml src/config.tcl; do
    echo "Backing up $file to $file.backup"
    cp $file $file.backup
done

# Activate python environment (venv):
source ~/tt/venv/bin/activate

for tiles in 4x2 8x2; do
    # Replace existing 'tiles' parameter:
    sed -i -re 's/^(  tiles:\s*)"[48]x2"/\1"'$tiles'"/' info.yaml
    for combo in 1 2 3 4; do
        tag=$tiles-combo-$combo
        stats=$tag.txt
        date > $stats
        logmark "Hardening combo $combo, $tiles"
        set-title $tag
        # Combos:
        # 1. 25MHz/new-OpenLane/SYNTH_STRATEGY=4
        # 2. 50MHz/new-OpenLane/SYNTH_STRATEGY=4
        # 3. 50MHz/OLD-OpenLane/default
        # 4. 50MHz/new-OpenLane/default

        # Replace CLOCK_PERIOD:
        if [ $combo -eq 1 ]; then
            # 25MHz clock target (40ns period)
            clk=40
        else
            # 50MHz clock target (20ns period)
            clk=20
        fi

        # Set the desired clock period:
        sed -i -re 's/^(\s*set\s+::env\(CLOCK_PERIOD\)\s+)"[0-9]+"/\1"'$clk'"/' src/config.tcl

        if [ $combo -lt 3 ]; then
            # SYNTH_STRATEGY 4
            # Look for: set ::env(SYNTH_STRATEGY) {DELAY 4}
            if egrep '^\s*#\s*set\s+::env\(SYNTH_STRATEGY\)\s+\{DELAY\s+4\}' src/config.tcl > /dev/null; then
                # The line exists but is commented, so uncomment it:
                sed -i -re 's/^\s*#\s*(set\s+::env\(SYNTH_STRATEGY\)\s+\{DELAY\s+4\})/\1/' src/config.tcl
            elif ! egrep '^\s*set\s+::env\(SYNTH_STRATEGY\)\s+\{DELAY\s+4\}' src/config.tcl > /dev/null; then
                # The line doesn't exist, so add it:
                echo 'set ::env(SYNTH_STRATEGY) {DELAY 4}' >> src/config.tcl
            # else the line already exists and is not commented out, so do nothing.
            fi
        else
            # Default SYNTH_STRATEGY
            if egrep '^\s*set\s+::env\(SYNTH_STRATEGY\)\s+\{DELAY\s+4\}' src/config.tcl > /dev/null; then
                # The line exists, so comment it out:
                sed -i -re 's/^(\s*set\s+::env\(SYNTH_STRATEGY\)\s+\{DELAY\s+4\})/# \1/' src/config.tcl
            fi
        fi

        if [ $combo -eq 3 ]; then
            # OLD OpenLane
            export OPENLANE_ROOT=/home/zerotoasic/asic_tools/openlane
            export PDK_ROOT=/home/zerotoasic/asic_tools/pdk
            export PDK=sky130A
            export OPENLANE_TAG=2022.11.19
            export OPENLANE_IMAGE_NAME=efabless/openlane:cb59d1f84deb5cedbb5b0a3e3f3b4129a967c988-amd64
        else
            # New OpenLane
            export OPENLANE_ROOT=~/tt/openlane
            export PDK_ROOT=~/tt/pdk
            export PDK=sky130A
            export OPENLANE_TAG=2023.06.26
            export OPENLANE_IMAGE_NAME=efabless/openlane:3bc9d02d0b34ad032921553e512fbe4bebf1d833
        fi

        log "=== COMBO $combo CONFIG: ==="
        egrep 'CLOCK_PERIOD|SYNTH_STRATEGY' src/config.tcl | egrep -v '^\s*#'
        egrep '^  tiles:' info.yaml
        echo "OpenLane $OPENLANE_TAG"

        # Run the harden...
        if ./tt/tt_tool.py --create-user-config && time ./tt/tt_tool.py --debug --harden; then
            logmark "OK: $tag"
        else
            logmark "FAILED: $tag"
        fi

        # Generate stats:
        summary.py --design . --run 0 --caravel --full-summary | egrep 'pre_abc|clock_freq|TotalCells' >> $stats
        ./tt/tt_tool.py --print-cell-category | fgrep 'total cells' >> $stats
        ./tt/tt_tool.py --print-stats >> $stats
        date >> $stats

    done
done

for file in info.yaml src/config.tcl; do
    echo "Restoring $file.backup to $file"
    cp $file.backup $file
done

# Convert stats to Markdown:

m=stats.md

git log -1 --no-merges --pretty="### [\`%h\`](https://github.com/algofoogle/tt04-raybox-zero/commit/%h?diff=split): %<(113,trunc)%s" > $m

for p in \
    _header \
    cells_pre_abc \
    TotalCells \
    suggested_clock_frequency \
    logic_cells \
    'utilisation_%' \
    wire_length_um \
; do
    case $p in
        _header)
            echo -n '| ' >> $m
            ;;
        suggested_clock_frequency)
            echo -n '| suggested_mhz ' >> $m
            ;;
        *)
            echo -n "| $p " >> $m
            ;;
    esac
    for c in 1 2 3 4; do
        for t in 4x2 8x2; do
            f=$t-combo-$c.txt
            echo -n '| ' >> $m
            case $p in
                _header)
                    printf "$t:$c" >> $m
                    ;;
                cells_pre_abc | TotalCells)
                    printf "%'d" $(fgrep $p $f | egrep -o '[-0-9]+') >> $m
                    ;;
                suggested_clock_frequency)
                    printf "%'.2f" $(fgrep $p $f | egrep -o '[0-9]+\.[0-9]{1,3}') >> $m
                    ;;
                logic_cells)
                    printf "%'d" $(fgrep 'total cells' $f | egrep -o '[0-9]+') >> $m
                    ;;
                'utilisation_%')
                    printf "%'.2f" $(egrep '\| [.0-9]+ \| [0-9]+ \|' $f | egrep -o '[0-9]+\.[0-9]+') >> $m
                    ;;
                wire_length_um)
                    printf "%'d" $(egrep '\| [.0-9]+ \| [0-9]+ \|' $f | egrep -o '\s[0-9]{3,}\s') >> $m
                    ;;
            esac
            echo -n ' ' >> $m
        done
    done
    echo '|' >> $m
    if [ $p == _header ]; then
        echo '|-|-:|-:|-:|-:|-:|-:|-:|-:|' >> $m
    fi
done

echo "Wrote results table to: $m"
