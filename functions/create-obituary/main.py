# add your create-obituary function here
import hashlib
import os
import time
import requests
from requests_toolbelt.multipart import decoder
import boto3
import base64
import json
import uuid

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table("obituary-30118953")
client = boto3.client('ssm')


response = client.get_parameters_by_path(
    Path='/the-last-show/',
    Recursive=True,
    WithDecryption=True,
)
params = {item['Name']: item['Value'] for item in response['Parameters']}


def lambda_handler(event, context):

    body = event["body"]
    if event["isBase64Encoded"]:
        body = base64.b64decode(body)

    content_type = event["headers"]["content-type"]
    data = decoder.MultipartDecoder(body, content_type)

    binary_data = [part.content for part in data.parts]
    name = binary_data[1].decode()
    born = binary_data[2].decode()
    death = binary_data[3].decode()

    key = "obituary.png"
    file_name = os.path.join("/tmp", key)
    with open(file_name, "wb") as f:
        f.write(binary_data[0])

    res = upload_to_cloudinary(file_name, extra_fields={
                               "eager": "e_art:zorro"})
    image_url = res["eager"][0]["secure_url"]

    prompt = f"write an obituary about a fictional character named {name} who was born on {born} and died on {death}."
    chat_answer = ask_gpt(prompt)

    audio_file = read_this(chat_answer)
    res_1 = upload_to_cloudinary(audio_file, resource_type="raw")
    audio_url = res_1["secure_url"]

    obituary_uuid = uuid.uuid4().hex

    item = {
        "ID": obituary_uuid,
        "name": name,
        "born": born,
        "death": death,
        "image_url": image_url,
        "obituary": chat_answer,
        "audio_url": audio_url
    }

    # add to dynamodb
    res = table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": json.dumps(item)
    }


def get_param_by_name(param_name):
    return params.get(param_name, None)


def upload_to_cloudinary(file_name, resource_type="image", extra_fields={}):
    # upload file at file_name path to Cloudinary
    # extra_fields could be "eager" for example
    # the eager you want is e_art:zorro

    api_key = get_param_by_name("/the-last-show/cloudinary-api-key")
    cloud_name = get_param_by_name("/the-last-show/cloud-name")
    api_secret = get_param_by_name("/the-last-show/cloudinary-secret-key")

    body = {
        "api_key": api_key
    }

    body.update(extra_fields)

    files = {
        "file": open(file_name, "rb")
    }

    body["signature"] = create_signature(body, api_secret)
    url = f"http://api.cloudinary.com/v1_1/{cloud_name}/{resource_type}/upload"
    res = requests.post(url, files=files, data=body)

    return res.json()


def create_signature(body, api_secret):
    """
    To authenticate with Cloudinary using HTTP API, you need a signature
    Creates signature to authenticate with Cloudinary
    """
    exclude = ["api_key", "recourse_type", "cloud_name"]
    # adds timestamp
    timestamp = int(time.time())
    body["timestamp"] = timestamp
    # sort parameters
    sorted_body = sort_dictionary(body, exclude)
    # separate parameters using & and =
    query_string = create_query_string(sorted_body)
    # append API secret at the end
    query_string_appended = f"{query_string}{api_secret}"
    # create hex message digest
    hashed = hashlib.sha1(query_string_appended.encode())
    signature = hashed.hexdigest()
    return signature


def sort_dictionary(dictionary, exclude):
    return {k: v for k, v in sorted(dictionary.items(), key=lambda item: item[0]) if k not in exclude}


def create_query_string(body):
    query_string = ""
    for idx, (k, v) in enumerate(body.items()):
        query_string = f"{k}={v}" if idx == 0 else f"{query_string}&{k}={v}"

    return query_string


def ask_gpt(prompt):
    api_key = get_param_by_name('/the-last-show/API-KEY')
    print(api_key)
    url = "https://api.openai.com/v1/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }

    body = {
        "model": "text-davinci-003",
        "prompt": prompt,
        "max_tokens": 400,
        "temperature": 0.2
    }

    res = requests.post(url, headers=headers, json=body)
    print(res.json())
    return res.json()["choices"][0]["text"]


def read_this(text):
    client = boto3.client('polly')
    response = client.synthesize_speech(
        Engine='standard',
        LanguageCode='en-US',
        OutputFormat='mp3',
        Text=text,
        TextType='text',
        VoiceId='Joanna'
    )

    audio_key = "polly.mp3"
    # fileName = "polly.mp3"
    fileName = os.path.join("/tmp", audio_key)
    with open(fileName, "wb") as f:
        f.write(response["AudioStream"].read())

    # no return means None in Python
    # None translates to null in JSON

    return fileName
