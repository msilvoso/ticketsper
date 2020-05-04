#!/usr/bin/env bash
readonly DATABASE="rthelp"
# period to lowercase
period=${1,,}
readonly PERIOD=${period:-"day"}
readonly FIRST_DATE=$2
readonly LAST_DATE=$3
readonly REMOVE_WEEKENDS=${4:-"false"}

sql_query() {
    mysql --defaults-extra-file=/etc/mysql/debian.cnf -sN -e "$1" $DATABASE
}

sql_query_day() {
    local count=$(sql_query "SELECT COUNT(*) FROM Tickets WHERE DATE(Started)='$1' GROUP BY DATE(Started);")
    echo -n "$count"
}

sql_query_week() {
    local sunday_of_the_week=$(date --date="$1 +6 day" --rfc-3339=date)
    local count=$(sql_query "SELECT COUNT(*) FROM Tickets WHERE Started BETWEEN '$1' AND '$sunday_of_the_week';")
    echo -n "$count"
}

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

init() {
    if [[ -z $FIRST_DATE ]]; then
        first_date=$(sql_query 'SELECT DATE(Started) FROM Tickets LIMIT 1,1;')
    else
        first_date=$FIRST_DATE
    fi
    if [[ -z $LAST_DATE ]]; then
        last_date=$(date --date="now +1 day" --rfc-3339=date)
    else
        last_date=$LAST_DATE
    fi
    if [[ $PERIOD == "week" ]]; then
        last_date=$(advance_to_day "$(date --date="$last_date +1 day" --rfc-3339=date)" "Mon")
        date_counter=$(advance_to_day "$first_date" "Mon")
        increment=7
    else
        date_counter="$first_date"
        increment=1
    fi
}

output() {
    echo -n "$1 "
    if [[ -z $2 ]]; then
        echo 0
    else
        echo "$2"
    fi
}

main() {
    init
    until [[ $date_counter == $last_date ]]; do
        if [[ $REMOVE_WEEKENDS != "false" ]]; then
            day_of_the_week=$(date --date="$date_counter" +%a)
            if [[ $day_of_the_week == "Sat" || $day_of_the_week == "Sun" ]]; then
                date_counter=$(increment_date "$date_counter")
                continue
            fi
        fi
        if [[ $PERIOD == "week" ]]; then
            count=$(sql_query_week "$date_counter")
        else
            count=$(sql_query_day "$date_counter")
        fi
        date_counter=$(increment_date "$date_counter" "$increment")
        output "${date_counter#*-}" "$count"
    done
}

main