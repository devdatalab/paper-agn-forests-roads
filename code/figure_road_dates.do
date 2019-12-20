use $tmp/road_count, clear
graph bar num_roads, over(comp_year, label(labsize(small))) ytitle("Number of Roads Completed") intensity(20) legend( label(1 "July") label(2 "January") )
graphout pmgsy_dates, pdf
