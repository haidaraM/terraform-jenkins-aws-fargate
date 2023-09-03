import json
import logging
import os
import sys
from datetime import datetime

import boto3
import pandas as pd
from botocore.exceptions import ClientError

root = logging.getLogger()
if root.handlers:
    for handler in root.handlers:
        root.removeHandler(handler)
logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)


def main():
    # Ensure the User has set the LOG GROUP NAME for the container.
    if "LOG_GROUP_NAME" not in os.environ:
        logging.info(
            "LOG_GROUP_NAME has not been set in environment variables")
        sys.exit(1)

    log_group_name = os.environ.get("LOG_GROUP_NAME")
    logging.info('Using Log Group %s', log_group_name)

    # Ensure the User has set the AWS REGION for the container.
    if "AWS_REGION" not in os.environ:
        logging.info(
            "AWS_REGION has not been set in environment variables")
        sys.exit(1)

    aws_region = os.environ.get("AWS_REGION")
    logging.info('Using AWS Region %s', aws_region)

    # Get all the Log Streams from the Cloudwatch logs API
    client = boto3.client("logs", region_name=aws_region)
    logging.info('Getting Log Streams for Log Group %s', log_group_name)
    try:
        response = client.describe_log_streams(
            logGroupName=log_group_name,
            limit=50
        )
    except ClientError as error:
        logging.error(error)
        sys.exit(1)

    # For Each Log Group Stream find all the log events. For Each event
    # format the timestamps, retrieve the Task Id and the Family and add
    # them to an array of all the Tasks.
    all_tasks = []
    for logstream in response['logStreams']:
        logging.info("Getting Log Events for Log Stream %s", logstream['logStreamName'])
        try:
            response = client.get_log_events(
                logGroupName=log_group_name,
                logStreamName=logstream['logStreamName']
            )
        except ClientError as error:
            logging.error(error)
            sys.exit(1)

        events = response['events']

        for event in events:
            event_raw = json.loads(event['message'])

            date_format = "%Y-%m-%dT%H:%M:%S.%fZ"
            try:
                created_at = datetime.strptime(event_raw['detail']['pullStoppedAt'], date_format)
                started_at = datetime.strptime(event_raw['detail']['startedAt'], date_format)
            except KeyError:
                # incomplete event, we just skip it
                continue

            delta = started_at - created_at

            # We have only one container per task, so we can just take the first one
            task_image = event_raw['detail']['containers'][0]['image']

            task = {
                "task_id": event_raw['detail']['taskArn'].split("/")[2],
                "task_image": task_image,
                "created_at": created_at.strftime("%H:%M:%S:%f"),
                "started_at": started_at.strftime("%H:%M:%S:%f"),
                "start_timedelta_seconds": delta.total_seconds()
            }

            all_tasks.append(task)

    all_tasks = sorted(all_tasks, key=lambda k: k['created_at'])

    # To make the data easier to visualize, I am going to convert the array into a DataFrame.
    df = pd.DataFrame(all_tasks)

    # This shows all the raw data in my table.
    print("Printing Raw Table")
    print(df.to_markdown())

    # If I wanted to look at the average pull time, I can group the DataFrame by task_image.
    print("Printing Average Pull Time Grouped By Task Family")
    df2 = df[['task_image', 'start_timedelta_seconds']].groupby(['task_image']).mean()
    print(df2.to_markdown())


if __name__ == "__main__":
    main()