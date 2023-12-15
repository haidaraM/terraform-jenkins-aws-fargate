import argparse
import time

from api4jenkins import Jenkins
from api4jenkins.build import Build
from api4jenkins.queue import QueueItem


def get_cli_args():
    """

    :return:
    """
    parser = argparse.ArgumentParser(
        description="""
        Trigger a Jenkins job and wait for it to complete.
        
        Example: python3 trigger-job.py -s http://localhost:8080 -u admin -p admin -i 10 job-full-name
        """
    )
    parser.add_argument(
        "job_name",
        type=str,
        help="The name of the job to trigger. The name of the job created by default by the module is 'example'.",
    )

    parser.add_argument(
        "-i",
        "--iterations",
        type=int,
        default=1,
        help="The number of times to trigger the job. Default: %(default)s",
    )

    parser.add_argument(
        "-u",
        "--user",
        type=str,
        required=True,
        help="The username to use to authenticate to Jenkins.",
    )
    parser.add_argument(
        "-p",
        "--password",
        type=str,
        required=True,
        help="The password to use to authenticate to Jenkins.",
    )
    parser.add_argument(
        "-s",
        "--server",
        type=str,
        required=True,
        help="The URL of the Jenkins server.",
    )
    return parser.parse_args()


def build_job(client: Jenkins, full_name: str) -> Build:
    """
    Build a Jenkins job and wait for it to complete.
    """
    queue_item: QueueItem = client.build_job(full_name)

    while not queue_item.get_build():
        print("Waiting for job to be scheduled...")
        time.sleep(5)

    build: Build = queue_item.get_build()

    while build.building:
        print("Waiting for job to complete...")
        time.sleep(5)

    return build


def main():
    args = get_cli_args()
    client = Jenkins(
        args.server,
        auth=(args.user, args.password),
    )

    # Checking access to the Jenkins server
    print(f"Jenkins version: {client.version}")

    print(f"Triggering the job {args.job_name}...")

    for i in range(args.iterations):
        print(f"Iteration: {i + 1}/{args.iterations}")
        build_job(client, args.job_name)
        print("=========================================\n")


main()
