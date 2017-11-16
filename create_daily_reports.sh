#!/bin/sh

########################################################
#
#	CRIBS Daily Traffic Summary		
#	Updated by: Evangelista, Em
#	MARCH 1, 2017
#
#	New In>Bill Daily Traffic Summary
#	Author: Tan, Lionel Chase
#	Edited: Noble, Renz Darnell 
#	March 13, 2009
#
#	
#
#
########################################################

#RRNoble: Parameterized the INI file

INI_FILE=$1



if [ $# -eq 0 ]
then

	echo "ERROR: INI FILE file doesn't exist."
	echo "Regular Run: main_script ini_file "
	echo "Special Run: main_script ini_file YYYYMMDD YYYYMMDD MON "
	exit -1
else

	echo "Daily Report Summary  "
	echo "Ini File: $INI_FILE "

fi




# --- Variables ---
   # dates to report on (default: today)

     # Setting an array from 0 to 11
    set -A months DEC JAN FEB MAR APR MAY JUN JUL AUG SEP OCT DEC	
    
    NOW_YEARMONTH=$(perl -e '@T = localtime(time); printf("%4d%02d\n", ($T[5] + 1900), $T[4] + 1)')
    NOW_DAY=$(perl -e '@T = localtime(time); printf("%02d\n", ($T[3]))')
    NOW_MONTH=$(perl -e '@T = localtime(time); printf("%02d\n", ($T[4] + 1))')
    NOW_PARTITION=$(perl -e '@T = localtime(time); printf("%d\n", ($T[4] + 1))')
    NOW_YEAR=$(perl -e '@T = localtime(time); printf("%04d\n", ($T[5] + 1900))')
    EMAIL_MONTH=`(export TZ=XYZ+24; date "+%b")` 	
    PARTITION_MONTH=`(export TZ=XYZ+24; date "+%b")`
    PARTITION_MONTH=$(echo $PARTITION_MONTH | tr '[:lower:]' '[:upper:]')

    	
 
   # Directory parameters
   # RRNoble: Made the directories defined in the INI file
   	MAIL_DIR=`grep MAIL_DIR $INI_FILE | cut -d'=' -f2`
   	MAIL_INI_DIR=`grep MAIL_INI_DIR $INI_FILE | cut -d'=' -f2`
   	MAIL_INI_FILE=`grep MAIL_INI_FILE $INI_FILE | cut -d'=' -f2`
   	REPORT_DIR=`grep REPORT_DIR $INI_FILE | cut -d'=' -f2`
   	ARCHIVE_DIR=`grep ARCHIVE_DIR $INI_FILE | cut -d'=' -f2`
   	LOG_DIR=`grep LOG_DIR $INI_FILE | cut -d'=' -f2`
	BASE_DIR=`grep BASE_DIR $INI_FILE | cut -d'=' -f2`

	#RRNoble: Check for the validity of the directories
	if [ -d $LOG_DIR ]
	then
		echo "LOG_DIR: $LOG_DIR"
	else
		echo "$LOG_DIR: Invalid log directory."
		exit -1
	fi
	
	if [ -d $BASE_DIR ]
	then
		echo "BASE_DIR: $BASE_DIR"
	else
		echo "$BASE_DIR: Invalid base directory."
		exit -1
	fi
	
	if [ -d $ARCHIVE_DIR ]
	then
		echo "ARCHIVE_DIR: $ARCHIVE_DIR"
	else
		echo "$ARCHIVE_DIR: Invalid archive directory."
		exit -1
	fi
	
	if [ -d $REPORT_DIR ]
	then
		echo "REPORT_DIR: $REPORT_DIR"
	else
		echo "$REPORT_DIR: Invalid reports directory."
		exit -1
	fi
	
	if [ -d $MAIL_DIR ]
	then
		echo "MAIL_DIR: $MAIL_DIR"
	else
		echo "$MAIL_DIR: Invalid mailer directory."
		exit -1
	fi
	
	if [ -d $MAIL_INI_DIR ]
	then
		echo "MAIL_INI_DIR: $MAIL_INI_DIR"
	else
		echo "$MAIL_INI_DIR: Invalid mailer INI directory."
		exit -1
	fi
	
	if [ -a $MAIL_INI_DIR/$MAIL_INI_FILE ]
	then
		echo ""
	else
		echo "ERROR: $MAIL_INI_DIR/$MAIL_INI_FILE doesn't exist."
		exit -1
	fi

	 
	
	LOGS_FILE=$LOG_DIR/$NOW_YEARMONTH$NOW_DAY\_run.log
	
	echo "LOG_FILE: $LOGS_FILE"

	if [ -a $BASE_DIR/emailer.flag ]
	then
		echo "`date` ERROR: CRIBS  Daily Emailer script already running."
		echo "`date` ERROR: CRIBS  Daily Emailer script already running." >> $LOGS_FILE
		exit -1
	fi

	touch $BASE_DIR/emailer.flag


# --- Main ---
  # . $HOME/.profile

	#RRNoble: edited on how to get the DB username and password
   SQLPLUS_USERNAME=`grep DB_USER $INI_FILE | cut -d'=' -f2`
   SQLPLUS_PASSWORD=`grep DB_PASS $INI_FILE | cut -d'=' -f2`
   DB_HOST=`grep DB_HOST $INI_FILE | cut -d'=' -f2`
   DB_PORT=`grep DB_POST $INI_FILE | cut -d'=' -f2`
   DB_SID=`grep DB_SID $INI_FILE | cut -d'=' -f2`
	
    echo "RunDate: `date`"
    echo "RunDate: `date`" >> $LOGS_FILE
    
   # check if 1st 5 days then previous month + current
	
	PREV_START_DATE="0"

	echo "NOW DAY: " $NOW_DAY
	if [ "$NOW_DAY" -le "05" ]
   	then
   		#PREV_MONTH=$(printf "%02d" $(($NOW_MONTH-1)))
   		#if [ "$PREV_MONTH" -eq "00" ]
   		#then
   		#	PREV_MONTH=12
   		#	PREV_YEAR=$(($NOW_YEAR-1))
   		#fi


		month_year=$(date +'%m %Y' | awk '!--$1{$1=12;$2--}1')
		m=${month_year% *}
		y=${month_year##* }
		d=$(cal $m $y | paste -s - | awk '{print $NF}')
		PREV_START_DATE=$(printf '%s%02s01' $y $m )
		PREV_END_DATE=$(printf '%s%02s%s' $y $m $d )
		PREV_PARTITION=${months[$m]}


   	fi
   	
	START_DATE=$NOW_YEAR$NOW_MONTH'01'
	END_DATE=$NOW_YEAR$NOW_MONTH$NOW_DAY
   	

#  For Special Run: Main_Script Ini_File Start_Date End_Date Partition_Month

if [ $# -eq 4 ]
then
	INI_FILE=$1
	START_DATE=$2
	END_DATE=$3
	PARTITION_MONTH=$4
	PREV_START_DATE="0" # Special Run will not execute Previous Month

fi


    
   # create daily invoice summary report
    echo "CURRENT MONTH From $START_DATE to $END_DATE\n"
    echo "CURRENT MONTH From $START_DATE to $END_DATE\n" >> $LOGS_FILE
    echo "`date`: Creating Daily Invoice Summary Report.......\n"
    echo "`date`: Creating Daily Invoice Summary Report.......\n" >> $LOGS_FILE
    
   # ADD  if 1st 5 days + Previous Month + Current day || Regular Process

	if [ "$PREV_START_DATE" != "0" ]
   	then
		echo "Processing PREVIOUS MONTH From $PREV_START_DATE to $PREV_END_DATE Partition $PREV_PARTITION \n"
		
		$BASE_DIR/create_daily_invc_report.sh $SQLPLUS_USERNAME $SQLPLUS_PASSWORD $PREV_START_DATE $PREV_END_DATE $PREV_PARTITION $REPORT_DIR >> $LOGS_FILE
   		
	fi	
		echo "Processing CURRENT MONTH From $START_DATE to $END_DATE Partition $PARTITION_MONTH  \n"
		
		$BASE_DIR/create_daily_invc_report.sh $SQLPLUS_USERNAME $SQLPLUS_PASSWORD $START_DATE $END_DATE $PARTITION_MONTH $REPORT_DIR >> $LOGS_FILE
		


    if [ $? -eq 0 ]
    	then
  		echo "DONE.\n"
		echo "`date`: SUCCESSFULLY created daily invoice report \n"
  		echo "`date`: SUCCESSFULLY created daily invoice report \n" >> $LOGS_FILE
  		gzip -q -f $REPORT_DIR/daily_invc_report_*.csv
  	else
  		echo "`date`: ERROR in invoice report generation. \n" >> $LOGS_FILE
  		echo "FAILED. Halting Execution."
  		rm $BASE_DIR/emailer.flag
  		exit -1
  	fi
       
    
   # create daily verification summary report
    echo "`date`: Creating Daily Verification Summary Report.......\n"
    echo "`date`: Creating Daily Verification Summary Report.......\n" >> $LOGS_FILE



	if [ "$PREV_START_DATE" != "0" ]
   	then
		echo "Processing PREVIOUS MONTH From $PREV_START_DATE to $PREV_END_DATE Partition $PREV_PARTITION \n"
		
		$BASE_DIR/create_daily_vrfy_report.sh $SQLPLUS_USERNAME $SQLPLUS_PASSWORD $PREV_START_DATE $PREV_END_DATE $PREV_PARTITION $REPORT_DIR >> $LOGS_FILE
   		
	fi

		echo "Processing CURRENT MONTH From $START_DATE to $END_DATE Partition $PARTITION_MONTH  \n"
		$BASE_DIR/create_daily_vrfy_report.sh $SQLPLUS_USERNAME $SQLPLUS_PASSWORD $START_DATE $END_DATE $PARTITION_MONTH $REPORT_DIR >> $LOGS_FILE	
	
    
   if [ $? -eq 0 ]
    	then
  		echo "DONE."
		echo "`date`: SUCCESSFULLY created daily verification report"
  		echo "`date`: SUCCESSFULLY created daily verification report" >> $LOGS_FILE
  		gzip -q -f $REPORT_DIR/daily_vrfy_report_*.csv
  	else
  		echo "ERROR in verification report generation." >> $LOGS_FILE
  		echo "`date`: FAILED. Halting Execution."
  		rm $BASE_DIR/emailer.flag
  		exit -1
  	fi
    


    #email reports
    #RRNoble: changed INI directory of mailer
    echo "`date`: Mailing reports.......................\n"
    
	
    perl $MAIL_DIR/ReportsMailer.pl $MAIL_INI_DIR/$MAIL_INI_FILE $LOG_DIR/ $END_DATE $EMAIL_MONTH $NOW_DAY $NOW_YEAR>> $LOGS_FILE
   
       if [ $? -eq 0 ]
    	then
  		echo "DONE. \n"
  		echo "`date`: SUCCESSFULLY completed all reports \n" >> $LOGS_FILE
  	else
  		echo "ERROR in report sending. \n" 
  		echo "`date`: FAILED. Halting Execution. \n" >> $LOGS_FILE
  		rm $BASE_DIR/emailer.flag
  		exit -1
  	fi
  	
       mv -f $REPORT_DIR/*.csv.gz $ARCHIVE_DIR
       rm $BASE_DIR/emailer.flag
  	
    exit 0

# --- End ---