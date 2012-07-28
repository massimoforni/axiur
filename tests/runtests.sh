PROJECT_NAME=axiur
echo "Running unit tests:"

for i in tests/*_tests
do
    if test -f $i
    then
        if ./$i 2>&1 > /tmp/$PROJECT_NAME-test.log
        then
            echo $i PASS
        else
            echo "ERROR in test $i:"
            cat /tmp/$PROJECT_NAME-test.log
            exit 1
        fi
    fi
done

rm -f /tmp/$PROJECT_NAME-test.log
echo ""
