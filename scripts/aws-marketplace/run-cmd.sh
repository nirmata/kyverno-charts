PRODUCT_ID="53cc511c-fcd6-48c2-b2ed-937aad0923f9"
DETAILS_JSON_STRING=$(cat delivery-options-details.json | jq 'tostring')
echo "$DETAILS_JSON_STRING"

aws marketplace-catalog start-change-set \
--catalog "AWSMarketplace" \
--change-set '[
  {
    "ChangeType": "AddDeliveryOptions",
    "Entity": {
      "Identifier": "'"${PRODUCT_ID}"'",
      "Type": "ContainerProduct@1.0"
    },
    "Details": '"${DETAILS_JSON_STRING}"'
  }
]' \
--region us-east-1
