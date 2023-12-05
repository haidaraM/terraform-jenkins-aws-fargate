import json
import os
import sys
from datetime import datetime

import boto3
import pandas as pd
from botocore.exceptions import ClientError


def get_all_log_streams(client, log_group_name, max_items=500):
    """

    Get all the log streams for a given log group name until there are no more log streams to retrieve or the max_items
    limit is reached or exceeded.
    """
    log_streams = []
    next_token = None

    while True:
        kwargs = {
            "logGroupName": log_group_name,
            "limit": 50,
        }

        if next_token:
            kwargs["nextToken"] = next_token

        response = client.describe_log_streams(**kwargs)

        log_streams.extend(response["logStreams"])

        if len(log_streams) >= max_items:
            break

        if "nextToken" in response:
            next_token = response["nextToken"]
        else:
            break

    return log_streams


def main():
    # Ensure the User has set the LOG GROUP NAME for the container.
    if "LOG_GROUP_NAME" not in os.environ:
        print("LOG_GROUP_NAME has not been set in environment variables")
        sys.exit(1)

    log_group_name = os.environ.get("LOG_GROUP_NAME")
    print("Using Log Group %s", log_group_name)

    # Ensure the User has set the AWS REGION for the container.
    if "AWS_REGION" not in os.environ:
        print("AWS_REGION has not been set in environment variables")
        sys.exit(1)

    # Get all the Log Streams from the Cloudwatch logs API
    client = boto3.client("logs", region_name=os.environ.get("AWS_REGION"))
    print("Getting Log Streams for Log Group %s", log_group_name)

    streams = get_all_log_streams(client, log_group_name)

    # For Each Log Group Stream find all the log events. For Each event
    # format the timestamps, retrieve the Task Id and the Family and add
    # them to an array of all the Tasks.
    all_tasks = []
    for logstream in streams:
        print("Getting Log Events for Log Stream %s", logstream["logStreamName"])
        try:
            response = client.get_log_events(
                logGroupName=log_group_name,
                logStreamName=logstream["logStreamName"],
                startFromHead=True,
            )
        except ClientError as error:
            print(error)
            sys.exit(1)

        events = response["events"]

        for event in events:
            event_raw = json.loads(event["message"])

            date_format = "%Y-%m-%dT%H:%M:%S.%fZ"

            created_at = datetime.strptime(
                event_raw["detail"]["pullStoppedAt"], date_format
            )
            started_at = datetime.strptime(
                event_raw["detail"]["startedAt"], date_format
            )

            if started_at < created_at:
                # Don't know yet how this is possible but let's ignore it for now
                continue

            delta = started_at - created_at

            # We have only one container per task, so we can just take the first one
            task_image = event_raw["detail"]["containers"][0]["image"]

            task = {
                "task_id": event_raw["detail"]["taskArn"].split("/")[2],
                "task_image": task_image,
                "created_at": created_at.isoformat(),
                "started_at": started_at.isoformat(),
                "start_timedelta_seconds": delta.total_seconds(),
            }

            all_tasks.append(task)

    all_tasks = sorted(all_tasks, key=lambda k: k["created_at"])

    # To make the data easier to visualize, I am going to convert the array into a DataFrame.
    df = pd.DataFrame(all_tasks)

    # This shows all the raw data in my table.
    # print("Printing Raw Table")
    # print(df.to_markdown(), flush=True)

    # If I wanted to look at the average pull time, I can group the DataFrame by task_image.
    print("Printing Average Pull Time Grouped By Task Family")
    df2 = (
        df[["task_image", "start_timedelta_seconds"]]
        .groupby(["task_image"])
        .agg(
            nb_runs=("task_image", "count"),
            min_start_time=("start_timedelta_seconds", "min"),
            max_start_time=("start_timedelta_seconds", "max"),
            mean_start_time=("start_timedelta_seconds", "mean"),
            median_start_time=("start_timedelta_seconds", "median"),
        )
    )
    print(df2.to_markdown())


if __name__ == "__main__":
    main()
