#!/usr/bin/env bash
readonly GNUPLOT="/usr/bin/gnuplot"
readonly DB_SCRIPT="/usr/local/bin/tickets_per.sh"
readonly GNUPLOT_SCRIPT="/usr/local/etc/plot_script"
readonly GNUPLOT_SCRIPT_DEST="/tmp/plot_script"
readonly FIRST_DATE=$(date --date="now -60 day" --rfc-3339=date)
readonly LAST_DATE=$(date --rfc-3339=date)

$DB_SCRIPT day "$FIRST_DATE" "$LAST_DATE" > /tmp/perday
$DB_SCRIPT week "$FIRST_DATE" "$LAST_DATE" > /tmp/perweek

$GNUPLOT $GNUPLOT_SCRIPT_DEST