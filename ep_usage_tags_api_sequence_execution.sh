#!/usr/bin/bash

C=$1
for (( i=0; $i < $C; ((i++)) ))
do
ST=$(date +%s)
echo "Start Time: $ST"

echo "Response:"
curl -s --write-out "\nAPI Status Code:%{http_code}" "https://api-dallas.cmc-staging.com/cmctestsvt2-powercloud/v1/ep/usage/tags/SVT_CB_fw39c?StartTS=2021-08-19T07:00:00Z&EndTS=2021-08-19T09:00:00Z&Frequency=Hourly" -H "X-CMC-Client-Id:8173ef2c-0f65-4522-8dfe-0134e1061974" -H "X-CMC-Client-Secret:a379add8-44dd-45bc-a77a-4bcd34a5b5ca"
echo ""
ET=$(date +%s)
echo "End Time: $ET"
echo -e "Average Time: $((ET-ST)) second(s)\n"
echo "----------------------------------------------------------------------------------------------------------------"
done

echo "Finished."
