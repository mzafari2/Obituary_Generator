# add your get-obituaries function here
import json
import boto3
dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table("obituary-30118953")


def lambda_handler(event, context):
    try:
        response = table.scan()
        item = response["Items"]
        # you want to return an HTTP response
        # which includes a statusCode and body
        return {
            "statusCode": 200,
            "body": json.dumps(item)
        }
    except Exception as exp:
        # this will go to CloudWatch which you can explore later
        print(exp)
        return {
            "statusCode": 200,
            "body": str(exp)
        }
