import json
import uuid
import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def response(status_code, body):
    return {
        "statusCode": status_code,
        "body": json.dumps(body)
    }


def lambda_handler(event, context):
    logger.info("Incoming request event: %s", json.dumps(event))

    payload = None

    try:
        method = event.get("requestContext", {}).get("http", {}).get("method")
    except Exception:
        return response(400, {"error": "can't process this request"})

    try:
        if method == "POST":
            body = json.loads(event.get("body") or "{}")
            payload = body.get("payload")

        elif method == "GET":
            query_params = event.get("queryStringParameters") or {}
            payload = query_params.get("payload")

        else:
            return response(405, {"error": "method not allowed"})

    except Exception:
        return response(400, {"error": "can't process this request"})

    if payload is None:
        return response(400, {"error": "payload key missing"})

    item = {
        "request_id": str(uuid.uuid4()),
        "payload": payload
    }

    table.put_item(Item=item)

    return response(200, {
        "status": "healthy",
        "message": "Request processed and saved."
    })
