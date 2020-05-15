#!/usr/bin/env bash

increment_date() {
    date --date="$1 +$2 day" --rfc-3339=date
}

advance_to_day() {
    local counter=$1
    until [[ $(date --date="$counter" +%a) == "$2" ]]; do
        counter=$(increment_date "$counter")
    done
    echo -n "$counter"
}


readonly GNUPLOT="/usr/bin/gnuplot"
readonly DB_SCRIPT="/usr/local/bin/tickets_per.sh"
readonly GNUPLOT_SCRIPT="/usr/local/etc/plot_script"
readonly GNUPLOT_SCRIPT_DEST="/tmp/plot_script"
readonly FIRST_DATE=$(date --date="now -90 day" --rfc-3339=date)
readonly LAST_DATE=$(date --rfc-3339=date)

$DB_SCRIPT day "$FIRST_DATE" "$LAST_DATE" > /tmp/perday
$DB_SCRIPT week "$FIRST_DATE" "$LAST_DATE" > /tmp/perweek

sed "s/XFROMXTOX/\"$(advance_to_day $FIRST_DATE 'Mon')\":\"$(advance_to_day $LAST_DATE 'Mon')\"/" < $GNUPLOT_SCRIPT > $GNUPLOT_SCRIPT_DEST

$GNUPLOT $GNUPLOT_SCRIPT_DEST

cp /tmp/ticketsplot.png /var/www/ticketsper/