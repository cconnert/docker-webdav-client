declare -rA signal_cleanup_map=(["INT"]="cleanup_interruption"
				["TERM"]="cleanup_interruption",
				["EXIT"]="cleanup_exit"
			       )

exit_script() {
    signal="$1"
    exit_code="$2"
    echo "Caught $signal! Unmounting ${DEST}..."
    sync -f "${DEST}"
    umount -l "${DEST}"
    dav2fs=$(ps -o pid= -o comm= | grep mount.davfs | sed -E 's/\s*(\d+)\s+.*/\1/g')
    if [ -n "$dav2fs" ]; then
        while $(kill -0 $dav2fs 2> /dev/null); do
            echo "Waiting for davfs (pid: $dav2fs) to terminate..."
            sleep 1
        done
    fi
    # clear all traps
    trap - "${!signal_cleanup_map[@]}"
    exit "$exit_code"
}


cleanup_exit() {
    exit_code="$?"
    exit_script "$1" "$exit_code"
}

cleanup_interruption() {
    exit_script "$1" "0"
}

for sig in "${!signal_cleanup_map[@]}"; do
  trap "${signal_cleanup_map[$sig]} $sig" "$sig"
done
