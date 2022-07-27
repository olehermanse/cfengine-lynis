# Note: This scripts content is authored inside of README.org, it's tangled from
# it. If you want to make an update, please update the code block inside
# README.org

exec 2>&1
TestDB="$1"
TMPFILE=$(mktemp compliance_report.XXX.json)
> $TMPFILE
echo "{" >> $TMPFILE
echo "\"reports\": {" >> $TMPFILE
echo "\"cisofy-lynis\": {" >> $TMPFILE
echo "\"id\": \"cisofy-lynis\"," >> $TMPFILE
echo "\"type\": \"compliance\"," >> $TMPFILE
echo "\"title\": \"CISOfy Lynis\"," >> $TMPFILE
echo "\"conditions\": [" >> $TMPFILE

#MAX_CHECKS=30
MAX_CHECKS=1000
CONDITION_COUNTER=0
while read line; do
    if echo "$line" | grep -P "^\s*#.*" > /dev/null; then
        # Do nothing with comments
        # echo "$line matched comment"
        :
    else
        ID=$(echo "$line" | awk -F: '{print $1}')
        ID_lowercase="lynis:$(echo $ID | tr '[:upper:]' '[:lower:]' )"
        echo "\"${ID_lowercase}\"," >> $TMPFILE
    fi
    CONDITION_COUNTER=$((CONDITION_COUNTER+1))
    if [ "$CONDITION_COUNTER" = "$MAX_CHECKS" ]; then
        break
    fi
done < $TestDB
  truncate -s -2 $TMPFILE
  echo ']}},' >> $TMPFILE

  echo '"conditions": {' >> $TMPFILE

CONDITION_COUNTER=0
while read line; do

    if echo "$line" | grep -P "^\s*#.*" > /dev/null; then
        # Do nothing with comments
        # echo "$line matched comment"
        :
    else

        ID=$(echo "$line" | awk -F: '{print $1}')
        Type=$(echo "$line" | awk -F: '{print $2}')
        Category=$(echo "$line" | awk -F: '{print $3}')
        Group=$(echo "$line" | awk -F: '{print $4}')
        OperatingSystem=$(echo "$line" | awk -F: '{print $5}')
        Description=$(echo "$line" | awk -F: '{print $6}')
        class="";

        case $OperatingSystem in
            "")
                class="linux"
                ;;
            Linux)
                class="linux"
                ;;
            FreeBSD)
                class="freebsd"
                ;;
            OpenBSD)
                class="openbsd"
                ;;
            NetBSD)
                class="netbsd"
                ;;
            DragonFly)
                class="dragonfly"
                ;;
            Solaris)
                class="solaris"
                ;;
            MacOS)
                class="darwin"
                ;;
            HP-UX)
                class="hpux"
                ;;
            AIX)
                class="aix"
                ;;
            *)
                class="UNKNOWN"
                ;;
        esac

        #echo $ID $Type $Category $Group $OperatingSystem $class $Description
        ID_lowercase="lynis:$(echo $ID | tr '[:upper:]' '[:lower:]' )"
        echo "\"${ID_lowercase}\": {" >> $TMPFILE
        echo "\"id\": \"${ID_lowercase}\"," >> $TMPFILE
        echo "\"name\": \"Lynis:${ID}\"," >> $TMPFILE
        echo "\"description\": \"${Description}\"," >> $TMPFILE
        # Herman dislikes using the control ID for the name, I tried to use the description string directly for name, but nop
        #echo "\"name\": \"${Description}\"," >> $TMPFILE
        #echo "\"name\": \"${Description}\"," >> $TMPFILE
        #echo "\"description\": \"$(printf \"%q\" \"${ID}: ${Description}\")," >> $TMPFILE
        echo "\"type\": \"inventory\"," >> $TMPFILE
        echo "\"condition_for\": \"passing\"," >> $TMPFILE
        echo "\"rules\": [" >> $TMPFILE
        echo "{" >> $TMPFILE
        echo "\"attribute\": \"CISOfy Lynis Control ID findings\"," >> $TMPFILE
        echo "\"operator\": \"not_contain\"," >> $TMPFILE
        echo "\"value\": \"$ID\"" >> $TMPFILE
        echo "}" >> $TMPFILE
        echo "]," >> $TMPFILE
        echo "\"category\": \"$Category\"," >> $TMPFILE
        echo "\"severity\": \"medium\"," >> $TMPFILE
        echo "\"host_filter\": \"$class\"" >> $TMPFILE
        echo "}," >> $TMPFILE
    fi
    CONDITION_COUNTER=$((CONDITION_COUNTER+1))
    if [ "$CONDITION_COUNTER" = "$MAX_CHECKS" ]; then
        break
    fi
done < $TestDB
  truncate -s -2 $TMPFILE
  echo '}}' >> $TMPFILE
  cat $TMPFILE | jq > generated-compliance-report.json
  rm $TMPFILE
  echo "DONE generating CFEngine Enterprise Compliance report (generated-compliance-report.json) with $CONDITION_COUNTER checks."
:
