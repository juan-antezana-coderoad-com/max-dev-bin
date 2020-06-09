#!/bin/bash

BATCH_SIZE=300
AUTH_NUMBER_OF_USERS=301

echo "BATCH_SIZE: $BATCH_SIZE"
echo "Number Of Users in Auth: ${AUTH_NUMBER_OF_USERS}"
# Calculating the number of batches (number of users / batch size) + (number of users % batch size > 0)
NUMBERS_OF_BATCHES=$(( (AUTH_NUMBER_OF_USERS / BATCH_SIZE) + (AUTH_NUMBER_OF_USERS % BATCH_SIZE > 0) ))
echo "Number Of Batches: ${NUMBERS_OF_BATCHES}"

for BATCH in $(seq 1 $NUMBERS_OF_BATCHES);
do
  echo $BATCH
done