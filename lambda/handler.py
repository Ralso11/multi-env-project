import json
import os

ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": "Hello from the multi-environment demo!",
            "environment": ENVIRONMENT
        })
    }
