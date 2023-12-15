import argparse

import boto3

# Boto3 ECS client
ecs_client = boto3.client("ecs")

# Boto3 waiters for service stability
ecs_waiter = ecs_client.get_waiter("services_stable")


def get_cli_args():
    """

    :return:
    """
    parser = argparse.ArgumentParser(
        description="Restart service updates to trigger ECS events."
    )
    parser.add_argument(
        "--cluster-name", help="ECS cluster name. Default: %(default)s", default="jenkins-cluster"
    )
    parser.add_argument(
        "--service-name", help="ECS service name. Default: %(default)s", default="jenkins-controller"
    )
    parser.add_argument(
        "-i",
        "--iterations", type=int, help="Number of updates. Default: %(default)s", default=16
    )

    return parser.parse_args()


# AWS CLI command to force update ECS service
def update_service(cluster_name, service_name):
    ecs_client.update_service(
        cluster=cluster_name, service=service_name, forceNewDeployment=True
    )


# AWS CLI command to check service stability
def check_service_stability(cluster_name, service_name):
    print("Checking service stability...")
    ecs_waiter.wait(cluster=cluster_name, services=[service_name])
    print("Service is stable.")


def main():
    args = get_cli_args()

    # Perform updates
    for i in range(args.iterations):
        print(f"Starting update {i + 1}/{args.iterations}...")
        update_service(args.cluster_name, args.service_name)
        check_service_stability(args.cluster_name, args.service_name)

    print("All updates completed.")


if __name__ == "__main__":
    main()
