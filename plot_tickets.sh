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

join() {
    local IFS="|"
    echo "$*"
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

mysql --defaults-extra-file=/etc/mysql/debian.cnf -N -B -e "SELECT subject FROM Tickets;" rthelp | iconv -f UTF-8 -t ASCII//TRANSLIT | perl -pe 's/[^\s\w]/ /g' > /tmp/wordcloud

stopwords=()
for word in $(cat /usr/local/etc/stopwords);do
    stopwords+=( $word )
done
stopregex=$(join "${stopwords[@]}" | perl -pe 's/\|/\\s|\\s/g')
perl -pi -e "s/($stopregex)/ /gi" /tmp/wordcloud
perl -pi -e "s/($stopregex)/ /gi" /tmp/wordcloud
wordcloud_cli --min_word_length 3 --mode RGBA --background 'rgba(255,255,255,0)' --width 1920 --height 1080 --colormap solarized --stopwords /usr/local/etc/stopwords --text /tmp/wordcloud --imagefile /var/www/ticketsper/wordcloud.png