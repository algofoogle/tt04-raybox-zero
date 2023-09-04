#!/usr/bin/bash

# For more info, see:
# - https://github.com/algofoogle/journal/blob/master/0131-2023-08-24.md
# - https://github.com/algofoogle/journal/blob/master/0132-2023-08-25.md

function stamp {
    date +"%Y-%m-%d %H:%M:%S"
}

function log {
    echo "[$(stamp)] $*"
}


function stop {
    log "STOP: $*"
    exit 1
}

function ssort {
    echo $(printf '%s\n' $(echo $*) | sort)
}

function print_options {
cat <<EOH
  STARTED: $STARTED
    SIZES: $SIZES  (sorted: $(ssort $SIZES))
   COMBOS: $COMBOS (sorted: $(ssort $COMBOS))
    STOPT: $STOPT
  OUTFILE: $OUTFILE
   SELECT: $SELECT
    FORCE: $FORCE
      TAG: $TAG
 FINISHED: $FINISHED
EOH
}


# Parse command-line args:
SIZES="4x2 8x2"
COMBOS="5 4 1 2 3"
STARTED="$(stamp)"
STOPT=0
OUTFILE=stats-$(date +%y%m%d-%H%M%S).md
SELECT=
FORCE=0
TAG=
while [ "$#" -gt 0 ]; do
    OPT=$1; shift
    if [ "$STOPT" -eq 0 ] && [ '-' == "${OPT:0:1}" ]; then
        # Option processing in effect:
        case $OPT in
            --)
                # Stop processing remaining args as options.
                STOPT=1
                ;;
            -o)
                # Specify output summary file instead of default.
                OUTFILE=$1
                if [[ -z ${OUTFILE// } ]]; then
                    stop "-o expects output file, but none given"
                fi
                shift
                ;;
            -f)
                # Force-overwrite any existing OUTFILE.
                FORCE=1
                ;;
            -s)
                # Size input overrides.
                SIZES=$1
                if [[ -z ${SIZES// } ]]; then
                    stop "-s expects sizes list (e.g. '4x2 8x2'), but none given"
                fi
                shift
                ;;
            -c)
                # Combo input overrides.
                COMBOS=$1
                if [[ -z ${COMBOS// } ]]; then
                    stop "-c expects combos list (e.g. '5 4 1 2 3'), but none given"
                fi
                shift
                ;;
            -t)
                # Extra heading tag
                TAG=$1
                if [[ -z ${TAG// } ]]; then
                    stop "-t expects extra heading tag string, but none given"
                fi
                shift
                ;;
            -h)
                cat <<EOH
Usage: $0 [OPTIONS] [SELECT]
OPTIONS can include:
    -h          Show this help.
    -t STRING   Include STRING as an extra heading in the summary file.
    -o OUTFILE  Specify output summary file instead of default timestamped stats-*.md
    -s SIZES    String that overrides the sizes (and order) to iterate. Default: '4x2 8x2'
    -c COMBOS   String that overrides the combos (and order) to iterate. Default: '5 4 1 2 3'
    -f          Force overwriting of OUTFILE if it already exists.
    --          Stop processing options; remaining arguments are literal.
SELECT, if provided, is an extended regular expression that will specify which combos to run.
It gets matched against the name of each combo:
    4x2:1 4x2:2 ... 4x2:5
    8x2:1 8x2:2 ... 8x2:5
EOH
                exit 0
                ;;
            *)
                stop "Unknown option: $OPT"
                ;;
        esac
    else
        # Option processing not applicable for this arg:
        SELECT="$OPT"
    fi
done

if [ -e "$OUTFILE" ] && [ $FORCE -eq 0 ]; then
    # OUTFILE already exists, and FORCE is not specified.
    stop "Output file already exists and -f not specified: $OUTFILE"
fi

# stop "BREAKPOINT"


function logmark {
    echo
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
  echo -e "\e]2;$*\a"
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

mkdir JUNK >/dev/null 2>&1

for tiles in $SIZES; do
    # Replace existing 'tiles' parameter:
    sed -i -re 's/^(  tiles:\s*)"[1-8]x[1-2]"/\1"'$tiles'"/' info.yaml
    for combo in $COMBOS; do
        rm -rf runs/wokwi
        tag=$tiles-combo-$combo
        stats=JUNK/$tag.txt
        if ! echo "$tiles:$combo" | egrep "$SELECT" >/dev/null 2>&1; then
            echo "Skipping $tag" | tee $stats
            continue
        fi
        stamp > $stats

        logmark "Hardening combo $combo, $tiles"
        set-title $tag
        # Combos:
        # 1. 25MHz/new-OpenLane/SYNTH_STRATEGY=4
        # 2. 50MHz/new-OpenLane/SYNTH_STRATEGY=4
        # 3. 50MHz/OLD-OpenLane/default
        # 4. 50MHz/new-OpenLane/default
        # 5. 25MHz/new-OpenLane/default/PL_TARGET_DENSITY=65

        # Replace CLOCK_PERIOD:
        if [ $combo -eq 1 ] || [ $combo -eq 5 ]; then
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

        if [ $combo -eq 5 ]; then
            # PL_TARGET_DENSITY 65%
            # Look for: set ::env(PL_TARGET_DENSITY) 0.65
            if egrep '^\s*#\s*set\s+::env\(PL_TARGET_DENSITY\)\s+0\.65' src/config.tcl > /dev/null; then
                # The line exists but is commented, so uncomment it:
                sed -i -re 's/^\s*#\s*(set\s+::env\(PL_TARGET_DENSITY\)\s+0\.65)/\1/' src/config.tcl
            elif ! egrep '^\s*set\s+::env\(PL_TARGET_DENSITY\)\s+0\.65' src/config.tcl > /dev/null; then
                # The line doesn't exist, so add it:
                echo 'set ::env(PL_TARGET_DENSITY) 0.65' >> src/config.tcl
            fi
        else
            # Comment out any PL_TARGET_DENSITY:
            sed -i -re 's/^(\s*set\s+::env\(PL_TARGET_DENSITY\)\s)/# \1/' src/config.tcl
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
        egrep 'CLOCK_PERIOD|SYNTH_STRATEGY|PL_TARGET_DENSITY' src/config.tcl | egrep -v '^\s*#'
        egrep '^  tiles:' info.yaml
        echo "OpenLane $OPENLANE_TAG"

        # Run the harden...
        if ./tt/tt_tool.py --create-user-config && time ./tt/tt_tool.py --debug --harden; then
            logmark "OK: $tag"
        else
            logmark "FAILED: $tag"
        fi

        # Generate stats:
        summary.py --design . --run 0 --caravel --full-summary | egrep 'synth_cell_count|pre_abc|clock_freq|TotalCells|_antenna_violations|spef_wns|spef_tns' >> $stats
        ./tt/tt_tool.py --print-cell-category | fgrep 'total cells' >> $stats
        ./tt/tt_tool.py --print-stats >> $stats
        date >> $stats

    done
done

for file in info.yaml src/config.tcl; do
    echo "Restoring $file.backup to $file"
    cp $file.backup $file
done

# Recreate user_config.tcl now that we've restored the original config:
./tt/tt_tool.py --create-user-config

# Convert stats to Markdown:

FINISHED="$(stamp)"


m="$OUTFILE"

echo > $m # Init the summary file.

cat >> $m <<EOH
### $TAG

<details><summary>Click for details...</summary>

Code:
*   tt04-raybox-zero: $(echo $(
        git log -1 --no-merges \
        --pretty="[\`%h\`](https://github.com/algofoogle/tt04-raybox-zero/commit/%h?diff=split): %<(113,trunc)%s"
    ))
    *   Equivalent to: [\`\`](): ?
EOH
pushd src/raybox-zero
cat >> ../../$m <<EOH
*   src/raybox-zero: $(echo $(
        git log -1 --no-merges \
        --pretty="[\`%h\`](https://github.com/algofoogle/raybox-zero/commit/%h?diff=split): %<(113,trunc)%s"
    ))
EOH
popd
cat >> $m <<EOH
    *   Modified? **($(echo $(git status src/raybox-zero/ -s | fgrep '' || echo No)))**
    *   Equivalent to: [\`\`](): ?

Summary:
*   ???

Options used:
\`\`\`
$(print_options)
\`\`\`

</details>

EOH


for p in \
    _header \
    suggested_clock_frequency \
    'utilisation_%' \
    wire_length_um \
    TotalCells \
    cells_pre_abc \
    synth_cell_count \
    logic_cells \
    pin_antenna_violations \
    net_antenna_violations \
    spef_wns \
    spef_tns \
; do
    case $p in
        _header)
            echo -n '| ' >> $m
            ;;
        suggested_clock_frequency)
            echo -n '| suggested_mhz ' >> $m
            ;;
        pin_antenna_violations)
            echo -n '| pin_antennas ' >> $m
            ;;
        net_antenna_violations)
            echo -n '| net_antennas ' >> $m
            ;;
        synth_cell_count)
            echo -n '| synth_cells ' >> $m
            ;;
        *)
            echo -n "| $p " >> $m
            ;;
    esac
    for c in $(ssort $COMBOS); do
        for t in $(ssort $SIZES); do
            f=JUNK/$t-combo-$c.txt
            echo -n '| ' >> $m
            case $p in
                _header)
                    printf "$t:$c" >> $m
                    ;;
                cells_pre_abc | TotalCells | synth_cell_count | pin_antenna_violations | net_antenna_violations)
                    printf "%'d" $(fgrep $p $f 2>/dev/null | egrep -o '[-0-9]+') >> $m
                    ;;
                suggested_clock_frequency | spef_wns | spef_tns)
                    printf "%'.2f" $(fgrep $p $f 2>/dev/null | egrep -o '[-0-9]+\.[0-9]{1,3}') >> $m
                    ;;
                logic_cells)
                    printf "%'d" $(fgrep 'total cells' $f 2>/dev/null | egrep -o '[0-9]+') >> $m
                    ;;
                'utilisation_%')
                    printf "%'.2f" $(egrep '\| [.0-9]+ \| [-]?[0-9]+ \|' $f 2>/dev/null | egrep -o '[0-9]+\.[0-9]+') >> $m
                    ;;
                wire_length_um)
                    printf "%'d"   $(egrep '\| [.0-9]+ \| [0-9]+ \|' $f 2>/dev/null | egrep -o '\s[0-9]{3,}\s') >> $m
                    ;;
            esac
            echo -n ' ' >> $m
        done
    done
    echo '|' >> $m
    if [ $p == _header ]; then
        echo -n '|-|' >> $m
        for dummy in $COMBOS; do
            for sizes in $SIZES; do
                echo -n '-:|' >> $m
            done
        done
        # echo '|-|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|' >> $m
        echo >> $m
    fi
done

cat >> $m <<EOH

Findings:
*   ??

EOH

echo "Wrote results table to: $m"

print_options

set-title "Done $FINISHED"
